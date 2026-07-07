import GGLib
import GGObj
import glm


var w = NWindow(1000, 1000, "OpenGL Window")
var shit = loadTexture("shit.png")
var c = newCamera()
var modelData = GGObj.parseOBJ("examples/cube.obj")
var cubeVertices = modelData[0]
var cubeIndices = modelData[1]
var cube = createModel(w.program, cubeVertices, cubeIndices, shit)
var cube2 = createModel(w.program, cubeVertices, cubeIndices, shit)

# place cube in front of the camera
cube.transform.pos = vec3f(0'f, 0'f, -1'f)
cube2.transform.pos = vec3f(1'f, 0'f, -1'f)

w.setSky(1,0,0,0)


while not w.Close():
    w.pollE()

    # animate rotation and render using the Model's transform
    c.pos = c.pos + vec3(0f,0f,speed(1f))
    cube.transform.rot = cube.transform.rot + vec3(0'f, speed(1f), 0'f)

    # set Phong shader uniforms
    setVec3(cube.program.id, "lightPos", 6'f, 0'f, 5'f)
    setVec3(cube.program.id, "viewPos", 0'f, 0'f, 3'f)
    setVec3(cube.program.id, "lightColor", 1'f, 1'f, 2'f)
    setVec3(cube.program.id, "objectColor", 10'f, 0.5'f, 0.2'f)
    setFloat(cube.program.id, "shininess", 56'f)

    cube.render(w, c)
    cube2.render(w, c)

    w.swap()

w.destroy()


