**Nim OpenGL Window**

- **What**: Minimal example that opens a window and creates an OpenGL context using GLFW.
- **Files**: `opengl_window.nim`

**Requirements (Windows)**
- Install Nim (choosing the recommended installer from nim-lang.org).
- Install GLFW (DLLs or system package). On Windows you can download the prebuilt binaries from the GLFW website and put `glfw3.dll` somewhere on your PATH or next to the compiled exe.
- OpenGL driver: provided by your GPU drivers (no extra install normally needed).

**Nimble packages**
Run in PowerShell:

```powershell
nimble install glfw
nimble install opengl
```

If any package is already installed, nimble will skip it.

**Build & Run (PowerShell)**

```powershell
# compile and run
nim c -r --verbosity:0 opengl_window.nim

# if you prefer a separate build step, just compile first
nim c --out:opengl_window.exe opengl_window.nim
./opengl_window.exe
```

**Notes**
- If the program fails to run with a missing DLL, ensure `glfw3.dll` is available next to the executable or on the PATH.
- If you prefer GLFW development via MSYS2/Chocolatey, you can install GLFW there and link accordingly.

If you want, I can switch this sample to use SDL2 or a direct Win32+WGL setup instead — tell me which you prefer and I will update the sample.