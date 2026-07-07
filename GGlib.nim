import glfw
import opengl
import math
import stb_image/read as stbi
import glm

var defaultVertexShader: cstring =
    """
    #version 460 core
  layout (location = 0) in vec3 aPos;
  layout (location = 1) in vec2 aTexCoord;
  layout (location = 2) in vec3 aNormal; // New: Normal attribute

  uniform mat4 model;
  uniform mat4 view;
  uniform mat4 projection;
  
  out vec3 FragPos;
  out vec3 Normal;
  out vec2 TexCoord;

  void main()
  {
    vec4 worldPos = model * vec4(aPos, 1.0);
    FragPos = vec3(worldPos);
    // Properly transform normals avoiding non-uniform scaling distortions
    Normal = mat3(transpose(inverse(model))) * aNormal; 
    gl_Position = projection * view * worldPos;
    TexCoord = aTexCoord;
  }
  """

var defaultFragmentShader: cstring =
    """
  #version 460 core
  out vec4 FragColor;

  in vec3 FragPos;
  in vec3 Normal;
  in vec2 TexCoord;

  uniform vec3 lightPos;
  uniform vec3 viewPos;
  uniform vec3 lightColor;
  uniform sampler2D texture_diffuse1;
  uniform float shininess;

  void main()
  {
    vec3 objectColor = texture(texture_diffuse1, TexCoord).rgb;

    // ambient
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;

    // diffuse
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    // specular
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
    vec3 specular = spec * lightColor;

    vec3 result = (ambient + diffuse + specular) * objectColor;
    FragColor = vec4(result, 1.0);
  }
  """

proc speed*(f: float): float = 
  f * 0.03

# --- MODERN DSA UNIFORMS ---
proc setMat4*(program: GLuint, name: cstring, mat: Mat4f) =
  let loc = glGetUniformLocation(program, name)
  var m = mat
  glProgramUniformMatrix4fv(program, loc, 1, GL_FALSE, m.caddr)

proc setVec3*(program: GLuint, name: cstring, x, y, z: float32) =
  let loc = glGetUniformLocation(program, name)
  glProgramUniform3f(program, loc, x, y, z)

proc setVec3v*(program: GLuint, name: cstring, v: Vec3f) =
  let loc = glGetUniformLocation(program, name)
  glProgramUniform3f(program, loc, v.x, v.y, v.z)

proc setFloat*(program: GLuint, name: cstring, v: float32) =
  let loc = glGetUniformLocation(program, name)
  glProgramUniform1f(program, loc, v)

proc setInt*(program: GLuint, name: cstring, v: GLint) =
  let loc = glGetUniformLocation(program, name)
  glProgramUniform1i(program, loc, v)


# --- CAMERA SYSTEM ---
type
  Camera* = object
    pos*: Vec3f
    front*: Vec3f
    up*: Vec3f
    right*: Vec3f
    worldUp*: Vec3f
    yaw*: float32
    pitch*: float32

proc updateCameraVectors*(c: var Camera) =
  var front: Vec3f
  front.x = cos(degToRad(c.yaw)) * cos(degToRad(c.pitch))
  front.y = sin(degToRad(c.pitch))
  front.z = sin(degToRad(c.yaw)) * cos(degToRad(c.pitch))
  c.front = normalize(front)
  c.right = normalize(cross(c.front, c.worldUp))
  c.up    = normalize(cross(c.right, c.front))

proc newCamera*(pos: Vec3f = vec3(0.0f, 0.0f, 3.0f), yaw: float32 = -90.0f, pitch: float32 = 0.0f): Camera =
  result.pos = pos
  result.worldUp = vec3(0.0f, 1.0f, 0.0f)
  result.yaw = yaw
  result.pitch = pitch
  result.front = vec3(0.0f, 0.0f, -1.0f)
  result.updateCameraVectors()

proc getViewMatrix*(c: Camera): Mat4f =
  return lookAt(c.pos, c.pos + c.front, c.up)
# ---------------------


type Transform* = object
  pos*: Vec3f
  rot*: Vec3f # rotations in radians: pitch(x), yaw(y), roll(z)
  scale*: Vec3f

proc toMat4*(t: Transform): Mat4f =
  var m = mat4(1.0f)
  m = translate(m, t.pos)
  m = rotate(m, t.rot.z, vec3(0.0f, 0.0f, 1.0f))
  m = rotate(m, t.rot.y, vec3(0.0f, 1.0f, 0.0f))
  m = rotate(m, t.rot.x, vec3(1.0f, 0.0f, 0.0f))
  m = scale(m, t.scale)
  result = m

type
  Shader* = object
    id*: GLuint

proc compileShader*(source: cstring; shaderType: GLenum): Shader =
    var shader = glCreateShader(shaderType)
    let srcStr = $source
    let srcArr = allocCStringArray([srcStr])

    glShaderSource(shader, 1, srcArr, nil)
    deallocCStringArray(srcArr)
    glCompileShader(shader)

    var success: GLint
    glGetShaderiv(shader, GL_COMPILE_STATUS, addr success)
    if success == 0:
        var infoLog: array[0..512, char]
        glGetShaderInfoLog(shader, 512, nil, cast[cstring](addr infoLog[0]))
        echo "Shader COMPILATION FAILED:"
        echo cast[cstring](addr infoLog[0])
        quit(1)

    result.id = shader

type
  ShaderProgram* = object
    id*: GLuint

proc linkProgram*(vert: Shader; frag: Shader): ShaderProgram =
  let program = glCreateProgram()
  glAttachShader(program, vert.id)
  glAttachShader(program, frag.id)
  glLinkProgram(program)

  var success: GLint
  glGetProgramiv(program, GL_LINK_STATUS, addr success)
  if success == 0:
    var infoLog: array[0..512, char]
    glGetProgramInfoLog(program, 512, nil, cast[cstring](addr infoLog[0]))
    echo "PROGRAM LINK FAILED:"
    echo cast[cstring](addr infoLog[0])
    quit(1)

  glDeleteShader(vert.id)
  glDeleteShader(frag.id)
  result.id = program

type 
  Texture* = object 
    TextureID*: GLuint

proc getTextureID*(t: Texture): Gluint = 
  return t.TextureID
  
proc loadTexture*(path: string): Texture =
  var width, height, channels: int
  let data = stbi.load(path, width, height, channels, stbi.Default)
  
  var textureID: GLuint
  # --- DSA: Create Texture & Allocate Immutable Storage ---
  glCreateTextures(GL_TEXTURE_2D, 1, addr textureID)

  glTextureParameteri(textureID, GL_TEXTURE_WRAP_S, GL_REPEAT)
  glTextureParameteri(textureID, GL_TEXTURE_WRAP_T, GL_REPEAT)
  glTextureParameteri(textureID, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
  glTextureParameteri(textureID, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

  let internalFormat = if channels == 4: GL_RGBA8 else: GL_RGB8
  let dataFormat = if channels == 4: GL_RGBA else: GL_RGB
  
  # Calculate mipmap levels
  let levels = GLsizei(floor(log2(float(max(width, height)))) + 1)

  # Allocate and upload data without binding
  glTextureStorage2D(textureID, levels, internalFormat.GLenum, width.GLsizei, height.GLsizei)
  glTextureSubImage2D(textureID, 0, 0, 0, width.GLsizei, height.GLsizei, dataFormat.GLenum, GL_UNSIGNED_BYTE, unsafeAddr data[0])
  glGenerateTextureMipmap(textureID)
  
  result.TextureID = textureID

type
  Model* = object
    vao*: GLuint
    vbo*: GLuint
    ebo*: GLuint
    vertexCount*: int
    program*: ShaderProgram
    transform*: Transform
    textureID*: GLuint 

proc createModel*(program: ShaderProgram, vertices: seq[float32], indices: seq[uint32], t: Texture): Model =
  var vao, vbo, ebo: GLuint
  
  # --- DSA: Create VAOs and Buffers ---
  glCreateVertexArrays(1, addr vao)
  glCreateBuffers(1, addr vbo)
  glCreateBuffers(1, addr ebo)

  # Immutable data allocation
  let vboSize = vertices.len * sizeof(float32)
  let eboSize = indices.len * sizeof(uint32)
  glNamedBufferStorage(vbo, vboSize, unsafeAddr vertices[0], GLbitfield(0))
  glNamedBufferStorage(ebo, eboSize, unsafeAddr indices[0], GLbitfield(0))

  # Tie buffers to the VAO directly
  glVertexArrayVertexBuffer(vao, 0, vbo, 0, GLsizei(8 * sizeof(float32)))
  glVertexArrayElementBuffer(vao, ebo)

  # --- POSITION ATTRIBUTE (Location 0) ---
  glEnableVertexArrayAttrib(vao, 0)
  glVertexArrayAttribFormat(vao, 0, 3, GLenum(0x1406), GL_FALSE, 0)
  glVertexArrayAttribBinding(vao, 0, 0)

  # --- TEXTURE ATTRIBUTE (Location 1) ---
  glEnableVertexArrayAttrib(vao, 1)
  glVertexArrayAttribFormat(vao, 1, 2, GLenum(0x1406), GL_FALSE, GLuint(6 * sizeof(float32)))
  glVertexArrayAttribBinding(vao, 1, 0)

  # --- NORMAL ATTRIBUTE (Location 2) ---
  glEnableVertexArrayAttrib(vao, 2)
  glVertexArrayAttribFormat(vao, 2, 3, GLenum(0x1406), GL_FALSE, GLuint(3 * sizeof(float32)))
  glVertexArrayAttribBinding(vao, 2, 0)

  result.transform.pos = vec3(0'f32, 0'f32, 0'f32)
  result.transform.rot = vec3(0'f32, 0'f32, 0'f32)
  result.transform.scale = vec3(1'f32, 1'f32, 1'f32)

  result.vao = vao
  result.vbo = vbo
  result.ebo = ebo
  result.vertexCount = indices.len
  result.program = program
  result.textureID = t.getTextureID()


type
    Window* = object
        w*: glfw.Window
        width*: int
        height*: int
        title*: string
        vsync*: bool
        red*: float
        green*: float
        blue*: float
        alpha*: float
        vertexShader*: Shader
        fragmentShader*: Shader
        program*: ShaderProgram
        
proc NWindow*(width: int = 1000; height: int = 1000; title: string = "GGLib"; vsync = true; red: float = 0.2; green:float = 0.3; blue:float = 0.3; alpha: float = 1.0, fragmentShader: cstring = defaultFragmentShader, vertexShader: cstring = defaultVertexShader): Window =
    glfw.initialize()
    var c = DefaultOpenglWindowConfig
    c.size = (width, height)
    c.title = title
    c.version = glv46
    c.forwardCompat = true

    let w = newWindow(c)
    if w == nil:
        terminate()
        quit("Failed to create GLFW window")

    makeContextCurrent(w)
    if vsync:
        swapInterval(1)
    else:
        swapInterval(0)

    loadExtensions()
    glClearColor(red, green, blue, alpha)
    glEnable(GL_DEPTH_TEST)

    var id: Shader = compileShader(vertexShader, GL_VERTEX_SHADER)
    var id2: Shader = compileShader(fragmentShader, GL_FRAGMENT_SHADER)

    result.w = w
    result.width = width
    result.height = height
    result.title = title
    result.vsync = vsync
    result.red = red
    result.green = green
    result.blue = blue
    result.alpha = alpha
    result.vertexShader = id
    result.fragmentShader = id2
    result.program = linkProgram(id, id2)

proc makeContextCurrent*(w: var Window) =
    if w.w != nil:
        w.makeContextCurrent()

proc pollE*(w: var Window) =
    if w.w != nil:
        glfw.pollEvents()
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc setSky*(w: var Window, r: float, b: float, g: float, a: float) = 
    w.red = r
    w.blue = b
    w.green = g
    w.alpha = a
    glClearColor(r,g,b,a)

proc swap*(w: var Window) =
    if w.w != nil:
        w.w.swapBuffers()

proc Close*(w: var Window): bool =
    if w.w != nil:
        result = glfw.shouldClose(cast[glfw.Window](w.w))

proc destroy*(w: var Window) =
    if w.w != nil:
        w.w.destroy()
        glfw.terminate()

proc render*(m: Model, w: Window, cam: Camera) =
  glUseProgram(m.program.id)

  # Lighting Uniforms (Set using the program ID directly)
  setVec3(m.program.id, "lightPos", 1.2'f32, 1.0'f32, 2.0'f32)
  setVec3v(m.program.id, "viewPos", cam.pos)
  setVec3(m.program.id, "lightColor", 1.0'f32, 1.0'f32, 1.0'f32)
  setFloat(m.program.id, "shininess", 32.0'f32)

  # --- DSA: Bind Texture Directly to Unit ---
  glBindTextureUnit(0, m.textureID)
  setInt(m.program.id, "texture_diffuse1", 0)

  let model = m.transform.toMat4()
  let view = cam.getViewMatrix()
  let proj = perspective(degToRad(60'f32), float32(w.width) / float32(w.height), 0.1'f32, 100'f32)

  setMat4(m.program.id, "model", model)
  setMat4(m.program.id, "view", view)
  setMat4(m.program.id, "projection", proj)

  glBindVertexArray(m.vao)
  glDrawElements(GL_TRIANGLES, GLsizei(m.vertexCount), GL_UNSIGNED_INT, nil)
  glBindVertexArray(0)