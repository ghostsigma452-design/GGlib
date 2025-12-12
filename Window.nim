import glfw
import opengl

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

## Create and initialize a new GLFW window. This uses the low-level
## GLFW API (`createWindow`, `makeContextCurrent`, `swapInterval`).
proc NWindow*(width: int; height: int; title: string; vsync = true; red: float; green:float; blue:float; alpha: float): Window =
    glfw.initialize()
    var c = DefaultOpenglWindowConfig

    c.size = (width, height)
    c.title = title
    let w = newWindow(c)
    if w == nil:
        terminate()
        quit("Failed to create GLFW window")

    makeContextCurrent(w)
    if vsync:
        swapInterval(1)
    else:
        swapInterval(0)
    glClearColor(red, green, blue, alpha)
    makeContextCurrent(w)
    loadExtensions()

    result.w = w
    result.width = width
    result.height = height
    result.title = title
    result.vsync = vsync
    result.red = red
    result.green = green
    result.blue = blue
    result.alpha = alpha

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

type
  Shader* = object
    id*: GLuint

proc compileShader*(source: cstring; shaderType: GLenum): Shader =
    var shader: GLuint = glCreateShader(shaderType)

    # Nim bindings require cstringArray, not array[…]
    var srcArr: cstringArray = cast[cstringArray](addr source)
    glShaderSource(shader, 1, srcArr, nil)

    var success: GLint
    glGetShaderiv(shader, GL_COMPILE_STATUS, addr success)

    if success == 0:   # GL_FALSE is 0
        var infoLog: array[0..512, char]
        glGetShaderInfoLog(shader, 512, nil, addr infoLog[0])
        quit("ERROR::SHADER::COMPILATION_FAILED\n" &
            $cast[cstring](addr infoLog[0]))

    result.id = shader

type
    App* = object
        window*: Window
        vertexShader*: Shader
        fragmentShader*: Shader


proc initApp*(width: int; height: int; title: string, vertexShader: string,fragmentShader: string): App =
    result.window = NWindow(width, height, title, vsync = true, 0.2, 0.3, 0.3, 1.0)
    result.vertexShader = compileShader(vertexShader.cstring, GL_VERTEX_SHADER)
    result.fragmentShader = compileShader(fragmentShader.cstring, GL_FRAGMENT_SHADER)











