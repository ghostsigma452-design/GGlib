import window


var w = NWindow(1000, 1000, "OpenGL Window", vsync = true, 0.2, 0.3, 0.3, 1.0,)
var shit = loadTexture("shit.png")
# 8 unique vertices (X, Y, Z, U, V)
let cubeVertices: seq[float32] = @[
    -0.5, -0.5,  0.5, 0.0, 0.0, # 0
     0.5, -0.5,  0.5, 1.0, 0.0, # 1
     0.5,  0.5,  0.5, 1.0, 1.0, # 2
    -0.5,  0.5,  0.5, 0.0, 1.0, # 3
    -0.5, -0.5, -0.5, 1.0, 0.0, # 4
     0.5, -0.5, -0.5, 0.0, 0.0, # 5
     0.5,  0.5, -0.5, 0.0, 1.0, # 6
    -0.5,  0.5, -0.5, 1.0, 1.0  # 7
]

# Indices for the 12 triangles
let cubeIndices: seq[uint32] = @[
    0, 1, 2, 2, 3, 0, # Front
    4, 5, 6, 6, 7, 4, # Back
    4, 0, 3, 3, 7, 4, # Left
    1, 5, 6, 6, 2, 1, # Right
    3, 2, 6, 6, 7, 3, # Top
    4, 5, 1, 1, 0, 4  # Bottom
]
var cube = createModel(w.program, cubeVertices, cubeIndices, shit)
var cube2 = createModel(w.program, cubeVertices, cubeIndices, shit)

# place cube in front of the camera
cube.transform.pos = [0'f32, 0'f32, -1'f32]
cube2.transform.pos = [1'f32, 0'f32, -1'f32]

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

    cube.render(w)
    cube2.render(w)

    w.swap()

w.destroy()


