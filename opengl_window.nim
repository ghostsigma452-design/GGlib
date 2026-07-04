import GGLib
import glm


var w = NWindow(1000, 1000, "OpenGL Window")
var shit = loadTexture("shit.png")
var c = newCamera()
let cubeVertices: seq[float32] = @[
    # --- Front Face (Normal: 0, 0, 1) ---
    -0.5'f, -0.5'f,  0.5'f,   0.0'f,  0.0'f,  1.0'f,   0.0'f, 0.0'f, # 0
     0.5'f, -0.5'f,  0.5'f,   0.0'f,  0.0'f,  1.0'f,   1.0'f, 0.0'f, # 1
     0.5'f,  0.5'f,  0.5'f,   0.0'f,  0.0'f,  1.0'f,   1.0'f, 1.0'f, # 2
    -0.5'f,  0.5'f,  0.5'f,   0.0'f,  0.0'f,  1.0'f,   0.0'f, 1.0'f, # 3

    # --- Back Face (Normal: 0, 0, -1) ---
    -0.5'f, -0.5'f, -0.5'f,   0.0'f,  0.0'f, -1.0'f,   1.0'f, 0.0'f, # 4
     0.5'f, -0.5'f, -0.5'f,   0.0'f,  0.0'f, -1.0'f,   0.0'f, 0.0'f, # 5
     0.5'f,  0.5'f, -0.5'f,   0.0'f,  0.0'f, -1.0'f,   0.0'f, 1.0'f, # 6
    -0.5'f,  0.5'f, -0.5'f,   0.0'f,  0.0'f, -1.0'f,   1.0'f, 1.0'f, # 7

    # --- Left Face (Normal: -1, 0, 0) ---
    -0.5'f, -0.5'f, -0.5'f,  -1.0'f,  0.0'f,  0.0'f,   0.0'f, 0.0'f, # 8
    -0.5'f, -0.5'f,  0.5'f,  -1.0'f,  0.0'f,  0.0'f,   1.0'f, 0.0'f, # 9
    -0.5'f,  0.5'f,  0.5'f,  -1.0'f,  0.0'f,  0.0'f,   1.0'f, 1.0'f, # 10
    -0.5'f,  0.5'f, -0.5'f,  -1.0'f,  0.0'f,  0.0'f,   0.0'f, 1.0'f, # 11

    # --- Right Face (Normal: 1, 0, 0) ---
     0.5'f, -0.5'f,  0.5'f,   1.0'f,  0.0'f,  0.0'f,   0.0'f, 0.0'f, # 12
     0.5'f, -0.5'f, -0.5'f,   1.0'f,  0.0'f,  0.0'f,   1.0'f, 0.0'f, # 13
     0.5'f,  0.5'f, -0.5'f,   1.0'f,  0.0'f,  0.0'f,   1.0'f, 1.0'f, # 14
     0.5'f,  0.5'f,  0.5'f,   1.0'f,  0.0'f,  0.0'f,   0.0'f, 1.0'f, # 15

    # --- Top Face (Normal: 0, 1, 0) ---
    -0.5'f,  0.5'f,  0.5'f,   0.0'f,  1.0'f,  0.0'f,   0.0'f, 0.0'f, # 16
     0.5'f,  0.5'f,  0.5'f,   0.0'f,  1.0'f,  0.0'f,   1.0'f, 0.0'f, # 17
     0.5'f,  0.5'f, -0.5'f,   0.0'f,  1.0'f,  0.0'f,   1.0'f, 1.0'f, # 18
    -0.5'f,  0.5'f, -0.5'f,   0.0'f,  1.0'f,  0.0'f,   0.0'f, 1.0'f, # 19

    # --- Bottom Face (Normal: 0, -1, 0) ---
    -0.5'f, -0.5'f, -0.5'f,   0.0'f, -1.0'f,  0.0'f,   0.0'f, 0.0'f, # 20
     0.5'f, -0.5'f, -0.5'f,   0.0'f, -1.0'f,  0.0'f,   1.0'f, 0.0'f, # 21
     0.5'f, -0.5'f,  0.5'f,   0.0'f, -1.0'f,  0.0'f,   1.0'f, 1.0'f, # 22
    -0.5'f, -0.5'f,  0.5'f,   0.0'f, -1.0'f,  0.0'f,   0.0'f, 1.0'f  # 23
]

# Updated indices referencing the 24 individual vertices
let cubeIndices: seq[uint32] = @[
    0,  1,  2,  2,  3,  0,  # Front
    4,  5,  6,  6,  7,  4,  # Back
    8,  9,  10, 10, 11, 8,  # Left
    12, 13, 14, 14, 15, 12, # Right
    16, 17, 18, 18, 19, 16, # Top
    20, 21, 22, 22, 23, 20  # Bottom
]
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


