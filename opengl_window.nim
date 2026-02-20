import window


var w = NWindow(1000, 1000, "OpenGL Window", vsync = true, 0.2, 0.3, 0.3, 1.0,)

let cubeVertices: seq[float32] = @[
  # front (Z+)
  -0.5, -0.5,  0.5,
   0.5, -0.5,  0.5,
   0.5,  0.5,  0.5,

   0.5,  0.5,  0.5,
  -0.5,  0.5,  0.5,
  -0.5, -0.5,  0.5,

  # back (Z-)
  -0.5, -0.5, -0.5,
  -0.5,  0.5, -0.5,
   0.5,  0.5, -0.5,

   0.5,  0.5, -0.5,
   0.5, -0.5, -0.5,
  -0.5, -0.5, -0.5,

  # left (X-)
  -0.5, -0.5, -0.5,
  -0.5, -0.5,  0.5,
  -0.5,  0.5,  0.5,

  -0.5,  0.5,  0.5,
  -0.5,  0.5, -0.5,
  -0.5, -0.5, -0.5,

  # right (X+)
   0.5, -0.5, -0.5,
   0.5,  0.5, -0.5,
   0.5,  0.5,  0.5,

   0.5,  0.5,  0.5,
   0.5, -0.5,  0.5,
   0.5, -0.5, -0.5,

  # top (Y+)
  -0.5,  0.5, -0.5,
  -0.5,  0.5,  0.5,
   0.5,  0.5,  0.5,

   0.5,  0.5,  0.5,
   0.5,  0.5, -0.5,
  -0.5,  0.5, -0.5,

  # bottom (Y-)
  -0.5, -0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5, -0.5,  0.5,

   0.5, -0.5,  0.5,
  -0.5, -0.5,  0.5,
  -0.5, -0.5, -0.5
]

var cube = createModel(w.program, cubeVertices)
var cube2 = createModel(w.program, cubeVertices)

# place cube in front of the camera
cube.transform.pos = [0'f32, 0'f32, -1'f32]
cube2.transform.pos = [1'f32, 0'f32, -1'f32]


while not w.Close():
    w.pollE()

    # animate rotation and render using the Model's transform

    cube.transform.rot = cube.transform.rot + vec3(0'f32, 0.01'f32, 0'f32)

    # set Phong shader uniforms
    setVec3(cube.program.id, "lightPos", 2'f32, 0'f32, 5'f32)
    setVec3(cube.program.id, "viewPos", 0'f32, 0'f32, 3'f32)
    setVec3(cube.program.id, "lightColor", 1'f32, 1'f32, 1'f32)
    setVec3(cube.program.id, "objectColor", 1'f32, 0.5'f32, 0.2'f32)
    setFloat(cube.program.id, "shininess", 16'f32)

    cube.render(w)
    cube2.render(w)

    w.swap()

w.destroy()


