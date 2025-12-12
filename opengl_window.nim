import window


var w = NWindow(1000, 1000, "OpenGL Window", vsync = true, 0.2, 0.3, 0.3, 1.0,)
  
while not w.Close():
    w.pollE()

    w.swap()

w.destroy()


