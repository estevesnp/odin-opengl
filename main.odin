package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

VERTEX_SHADER := #load("./shaders/vertex.glsl", cstring)
FRAGMENT_SHADER := #load("./shaders/fragment.glsl", cstring)

main :: proc() {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    glfw.Init()
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    when ODIN_OS == .Darwin {
        glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
    }

    window := glfw.CreateWindow(800, 600, "odinGL", nil, nil)
    if window == nil {
        fmt.eprintln("error creating window")
        return
    }
    glfw.MakeContextCurrent(window)

    gl.load_up_to(3, 3, glfw.gl_set_proc_address)

    gl.Viewport(0, 0, 800, 600)
    glfw.SetFramebufferSizeCallback(window, framebuffer_callback)

    shader_program, err := shader_init("./shaders/vertex.glsl", "./shaders/fragment.glsl")
    if err != nil {
        log.errorf("error creating shader program: %v", err)
        return
    }


    // odinfmt: disable

    // TRIANGLE

    vertices := [?]f32{
        // positions      // colors
         0.5, -0.5, 0.0,  1.0, 0.0, 0.0,   // bottom right
        -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,   // bottom left
         0.0,  0.5, 0.0,  0.0, 0.0, 1.0    // top
    }
    indices := [?]u32{
        0, 1, 2,
    }


    // RECTANGLE

    // vertices := [?]f32{
    //      0.5,  0.5, 0.0,  // top right
    //      0.5, -0.5, 0.0,  // bottom right
    //     -0.5, -0.5, 0.0,  // bottom left
    //     -0.5,  0.5, 0.0,  // top left
    // }
    // indices := [?]u32{
    //     0, 1, 3,
    //     1, 2, 3,
    // }

    // odinfmt: enable

    vao, vbo, ebo: u32
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

    // positions
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of([6]f32), 0)
    gl.EnableVertexAttribArray(0)

    // colors
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of([6]f32), size_of([3]f32))
    gl.EnableVertexAttribArray(1)

    // wireframe polygons
    // gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

    for !glfw.WindowShouldClose(window) {
        process_input(window)

        gl.ClearColor(0.2, 0.3, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        shader_use(shader_program)

        gl.BindVertexArray(vao)
        gl.DrawElements(gl.TRIANGLES, len(indices), gl.UNSIGNED_INT, nil)

        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}

process_input :: proc "c" (window: glfw.WindowHandle) {
    if glfw.GetKey(window, glfw.KEY_Q) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }
}

framebuffer_callback :: proc "c" (window: glfw.WindowHandle, width, height: c.int) {
    context = runtime.default_context()
    fmt.printf("got callback for width %d, height %d, window %v\n", width, height, window)

    gl.Viewport(0, 0, width, height)
}
