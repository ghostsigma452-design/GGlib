import GGLib
import glm


var w = NWindow(1000, 1000, "OpenGL Window")
var shit = loadTexture("shit.png")
var c = newCamera()
let cubeVertices: seq[float32] = @[
    # --- Front Face (Normal: 0, 0, 1) ---
    -0.5'f32, -0.5'f32,  0.5'f32,   0.0'f32,  0.0'f32,  1.0'f32,   0.0'f32, 0.0'f32, # 0
     0.5'f32, -0.5'f32,  0.5'f32,   0.0'f32,  0.0'f32,  1.0'f32,   1.0'f32, 0.0'f32, # 1
     0.5'f32,  0.5'f32,  0.5'f32,   0.0'f32,  0.0'f32,  1.0'f32,   1.0'f32, 1.0'f32, # 2
    -0.5'f32,  0.5'f32,  0.5'f32,   0.0'f32,  0.0'f32,  1.0'f32,   0.0'f32, 1.0'f32, # 3

    # --- Back Face (Normal: 0, 0, -1) ---
    -0.5'f32, -0.5'f32, -0.5'f32,   0.0'f32,  0.0'f32, -1.0'f32,   1.0'f32, 0.0'f32, # 4
     0.5'f32, -0.5'f32, -0.5'f32,   0.0'f32,  0.0'f32, -1.0'f32,   0.0'f32, 0.0'f32, # 5
     0.5'f32,  0.5'f32, -0.5'f32,   0.0'f32,  0.0'f32, -1.0'f32,   0.0'f32, 1.0'f32, # 6
    -0.5'f32,  0.5'f32, -0.5'f32,   0.0'f32,  0.0'f32, -1.0'f32,   1.0'f32, 1.0'f32, # 7

    # --- Left Face (Normal: -1, 0, 0) ---
    -0.5'f32, -0.5'f32, -0.5'f32,  -1.0'f32,  0.0'f32,  0.0'f32,   0.0'f32, 0.0'f32, # 8
    -0.5'f32, -0.5'f32,  0.5'f32,  -1.0'f32,  0.0'f32,  0.0'f32,   1.0'f32, 0.0'f32, # 9
    -0.5'f32,  0.5'f32,  0.5'f32,  -1.0'f32,  0.0'f32,  0.0'f32,   1.0'f32, 1.0'f32, # 10
    -0.5'f32,  0.5'f32, -0.5'f32,  -1.0'f32,  0.0'f32,  0.0'f32,   0.0'f32, 1.0'f32, # 11

    # --- Right Face (Normal: 1, 0, 0) ---
     0.5'f32, -0.5'f32,  0.5'f32,   1.0'f32,  0.0'f32,  0.0'f32,   0.0'f32, 0.0'f32, # 12
     0.5'f32, -0.5'f32, -0.5'f32,   1.0'f32,  0.0'f32,  0.0'f32,   1.0'f32, 0.0'f32, # 13
     0.5'f32,  0.5'f32, -0.5'f32,   1.0'f32,  0.0'f32,  0.0'f32,   1.0'f32, 1.0'f32, # 14
     0.5'f32,  0.5'f32,  0.5'f32,   1.0'f32,  0.0'f32,  0.0'f32,   0.0'f32, 1.0'f32, # 15

    # --- Top Face (Normal: 0, 1, 0) ---
    -0.5'f32,  0.5'f32,  0.5'f32,   0.0'f32,  1.0'f32,  0.0'f32,   0.0'f32, 0.0'f32, # 16
     0.5'f32,  0.5'f32,  0.5'f32,   0.0'f32,  1.0'f32,  0.0'f32,   1.0'f32, 0.0'f32, # 17
     0.5'f32,  0.5'f32, -0.5'f32,   0.0'f32,  1.0'f32,  0.0'f32,   1.0'f32, 1.0'f32, # 18
    -0.5'f32,  0.5'f32, -0.5'f32,   0.0'f32,  1.0'f32,  0.0'f32,   0.0'f32, 1.0'f32, # 19

    # --- Bottom Face (Normal: 0, -1, 0) ---
    -0.5'f32, -0.5'f32, -0.5'f32,   0.0'f32, -1.0'f32,  0.0'f32,   0.0'f32, 0.0'f32, # 20
     0.5'f32, -0.5'f32, -0.5'f32,   0.0'f32, -1.0'f32,  0.0'f32,   1.0'f32, 0.0'f32, # 21
     0.5'f32, -0.5'f32,  0.5'f32,   0.0'f32, -1.0'f32,  0.0'f32,   1.0'f32, 1.0'f32, # 22
    -0.5'f32, -0.5'f32,  0.5'f32,   0.0'f32, -1.0'f32,  0.0'f32,   0.0'f32, 1.0'f32  # 23
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
cube.transform.pos = vec3f(0'f32, 0'f32, -1'f32)
cube2.transform.pos = vec3f(1'f32, 0'f32, -1'f32)

w.setSky(1,0,0,0)


while not w.Close():
    w.pollE()

    # animate rotation and render using the Model's transform

    cube.transform.rot = cube.transform.rot + vec3(0'f32, 0.01'f32, 0'f32)

    # set Phong shader uniforms
    setVec3(cube.program.id, "lightPos", 6'f32, 0'f32, 5'f32)
    setVec3(cube.program.id, "viewPos", 0'f32, 0'f32, 3'f32)
    setVec3(cube.program.id, "lightColor", 1'f32, 1'f32, 2'f32)
    setVec3(cube.program.id, "objectColor", 10'f32, 0.5'f32, 0.2'f32)
    setFloat(cube.program.id, "shininess", 56'f32)

    cube.render(w, c)
    cube2.render(w, c)

    w.swap()

w.destroy()


