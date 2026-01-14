import glfw
import opengl
import math
import stb_image/read as stbi



var defaultVertexShader: cstring =
    """
    #version 330 core
  layout (location = 0) in vec3 aPos;

  uniform mat4 model;
  uniform mat4 view;
  uniform mat4 projection;

  out vec3 FragPos;
  out vec3 Normal;

  void main()
  {
    vec4 worldPos = model * vec4(aPos, 1.0);
    FragPos = vec3(worldPos);
    // NOTE: we don't have a normal attribute in the simple mesh, so
    // approximate using the transformed position. Replace with a
    // proper normal attribute when available.
    Normal = mat3(transpose(inverse(model))) * aPos;
    gl_Position = projection * view * worldPos;
  }

  """

var defaultFragmentShader: cstring =
    """
  #version 330 core
  out vec4 FragColor;

  in vec3 FragPos;
  in vec3 Normal;

  uniform vec3 lightPos;
  uniform vec3 viewPos;
  uniform vec3 lightColor;
  uniform vec3 objectColor;
  uniform float shininess;

  void main()
  {
    // ambient
    float ambientStrength = 0.05;
    vec3 ambient = ambientStrength * lightColor;

    // diffuse
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0) * 1.5;
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


type Mat4 = array[16, float32]

proc identityMat4(): Mat4 =
  result = [
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1
  ]

proc perspective(fov, aspect, near, far: float32): Mat4 =
  let f = 1.0 / tan(fov / 2)
  result = [
        float32(f / aspect), 0'f32, 0'f32, 0'f32,
        0'f32, float32(f), 0'f32, 0'f32,
        0'f32, 0'f32, float32((far + near) / (near - far)), -1'f32,
        0'f32, 0'f32, float32(2 * far * near / (near - far)), 0'f32
    ]

proc translate(z: float32): Mat4 =
  result = identityMat4()
  result[14] = z


proc setMat4(program: GLuint, name: cstring, mat: Mat4) =
  glUseProgram(program)
  let loc = glGetUniformLocation(program, name)
  glUniformMatrix4fv(loc, 1, GL_FALSE, addr mat[0])


proc setVec3*(program: GLuint, name: cstring, x, y, z: float32) =
  glUseProgram(program)
  let loc = glGetUniformLocation(program, name)
  glUniform3f(loc, x, y, z)

proc setFloat*(program: GLuint, name: cstring, v: float32) =
  glUseProgram(program)
  let loc = glGetUniformLocation(program, name)
  glUniform1f(loc, v)

proc setInt*(program: GLuint, name: cstring, v: GLint) =
  glUseProgram(program)
  let loc = glGetUniformLocation(program, name)
  glUniform1i(loc, v)

proc rotateY(angle: float32): Mat4 =
  let c = cos(angle)
  let s = sin(angle)
  result = [
     c, 0,  s, 0,
     0, 1,  0, 0,
    -s, 0,  c, 0,
     0, 0,  0, 1
  ]


type Vec3 = array[3, float32]

proc `+`*(a, b: Vec3): Vec3 =
  result[0] = a[0] + b[0]
  result[1] = a[1] + b[1]
  result[2] = a[2] + b[2]

proc `-`*(a, b: Vec3): Vec3 =
  result[0] = a[0] - b[0]
  result[1] = a[1] - b[1]
  result[2] = a[2] - b[2]

proc vec3*(x, y, z: float32): Vec3 =
  result[0] = x
  result[1] = y
  result[2] = z

type Transform* = object
  pos*: Vec3
  rot*: Vec3 # rotations in radians: pitch(x), yaw(y), roll(z)
  scale*: Vec3

proc mulMat4(a, b: Mat4): Mat4 =
  for r in 0..3:
    for c in 0..3:
      var s: float32 = 0'f32
      for k in 0..3:
        s += a[k*4 + r] * b[c*4 + k]
      result[c*4 + r] = s

proc rotateX(angle: float32): Mat4 =
  let c = cos(angle)
  let s = sin(angle)
  result = [
    1, 0, 0, 0,
    0, c, -s, 0,
    0, s,  c, 0,
    0, 0, 0, 1
  ]

proc rotateZ(angle: float32): Mat4 =
  let c = cos(angle)
  let s = sin(angle)
  result = [
    c, -s, 0, 0,
    s,  c, 0, 0,
    0,  0, 1, 0,
    0,  0, 0, 1
  ]

proc scaleMat(sx, sy, sz: float32): Mat4 =
  result = [
    sx, 0, 0, 0,
    0, sy, 0, 0,
    0, 0, sz, 0,
    0, 0, 0, 1
  ]

proc translateVec(v: Vec3): Mat4 =
  result = identityMat4()
  result[12] = v[0]
  result[13] = v[1]
  result[14] = v[2]

proc toMat4*(t: Transform): Mat4 =
  let S = scaleMat(t.scale[0], t.scale[1], t.scale[2])
  let Rx = rotateX(t.rot[0])
  let Ry = rotateY(t.rot[1])
  let Rz = rotateZ(t.rot[2])
  # Combined rotation: R = Rz * Ry * Rx
  let R = mulMat4(Rz, mulMat4(Ry, Rx))
  let T = translateVec(t.pos)
  result = mulMat4(T, mulMat4(R, S))



type
  Shader* = object
    id*: GLuint

proc compileShader*(source: cstring; shaderType: GLenum): Shader =
    var shader = glCreateShader(shaderType)

    # convert cstring -> string so Nim stops crying
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
  Model* = object
    vao*: GLuint
    vbo*: GLuint
    vertexCount*: int
    program*: ShaderProgram
    transform*: Transform

proc createModel*(program: ShaderProgram, vertices: seq[float32]): Model =


  var vao, vbo: GLuint
  glGenVertexArrays(1, addr vao)
  glGenBuffers(1, addr vbo)

  glBindVertexArray(vao)
  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(
    GL_ARRAY_BUFFER,
    vertices.len * sizeof(float32),
    unsafeAddr vertices[0],
    GL_STATIC_DRAW
  )

  glVertexAttribPointer(
  GLuint(0),
  GLint(3),
  GLenum(0x1406),
  GL_FALSE,
  GLsizei(3 * sizeof(float32)),
  cast[pointer](nil)
  )


  glEnableVertexAttribArray(0)
  result.transform.pos = [0'f32, 0'f32, 0'f32]
  result.transform.rot = [0'f32, 0'f32, 0'f32]
  result.transform.scale = [1'f32, 1'f32, 1'f32]

  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindVertexArray(0)

  result.vao = vao
  result.vbo = vbo
  result.vertexCount = vertices.len div 3
  result.program = program







type
    ## `Window` is a small wrapper around a GLFW window handle and metadata.
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
        
        
        ## Create and initialize a new GLFW window. This uses the low-level
## GLFW API (`createWindow`, `makeContextCurrent`, `swapInterval`).
proc NWindow*(width: int; height: int; title: string; vsync = true; red: float; green:float; blue:float; alpha: float, fragmentShader: cstring = defaultFragmentShader, vertexShader: cstring = defaultVertexShader): Window =
    glfw.initialize()

    var c = DefaultOpenglWindowConfig

    c.size = (width, height)
    c.title = title
    c.version = glv33          # This is the part you MUST change
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


proc render*(m: Model, w: Window) =
  glUseProgram(m.program.id)

  let model = m.transform.toMat4()
  let view = translate(-3.0'f32)
  let proj = perspective(
    degToRad(60'f32),
    float32(w.width) / float32(w.height),
    0.1'f32,
    100'f32
  )

  setMat4(m.program.id, "model", model)
  setMat4(m.program.id, "view", view)
  setMat4(m.program.id, "projection", proj)

  glBindVertexArray(m.vao)
  glDrawArrays(GL_TRIANGLES, 0, GLsizei(m.vertexCount))
  glBindVertexArray(0)

















