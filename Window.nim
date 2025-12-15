import glfw
import opengl
import math


var defaultVertexShader: cstring =
    """
    #version 330 core
    layout (location = 0) in vec3 aPos;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    void main()
    {
        gl_Position = projection * view * model * vec4(aPos, 1.0);
    }

    """

var defaultFragmentShader: cstring =
        """
    #version 330 core
    out vec4 FragColor;
    void main()
    {
        FragColor = vec4(1.0, 0.5, 0.2, 1.0);
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
  let loc = glGetUniformLocation(program, name)
  glUniformMatrix4fv(loc, 1, GL_FALSE, addr mat[0])

proc rotateY(angle: float32): Mat4 =
  let c = cos(angle)
  let s = sin(angle)
  result = [
     c, 0,  s, 0,
     0, 1,  0, 0,
    -s, 0,  c, 0,
     0, 0,  0, 1
  ]



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
        glGetShaderInfoLog(shader, 512, nil, addr infoLog[0])
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
    glGetProgramInfoLog(program, 512, nil, addr infoLog[0])
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


proc render*(m: Model, w: Window, angle: float32) =
  glUseProgram(m.program.id)

  let model = rotateY(angle)
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

















