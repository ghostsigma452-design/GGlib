import glfw
import opengl


var defaultVertexShader: cstring =
    """
    #version 330 core
    layout (location = 0) in vec3 aPos;
    
    void main()
    {
        gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
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
















