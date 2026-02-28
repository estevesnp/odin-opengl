package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

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

    fb_width, fb_height := glfw.GetFramebufferSize(window)
    gl.Viewport(0, 0, fb_width, fb_height)
    glfw.SetFramebufferSizeCallback(window, framebuffer_callback)

    shader_program, err := shader_init("./shaders/vertex.glsl", "./shaders/fragment.glsl")
    if err != nil {
        log.errorf("error creating shader program: %v", err)
        return
    }


    // odinfmt: disable

    vertices := [?]f32{
        // positions       // colors        // texture coords
         0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
         0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
        -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom left
        -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0    // top left
    }
    indices := [?]u32{
        0, 1, 3,   // first triangle
        1, 2, 3    // second triangle
    }


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

    stride: i32 = size_of([8]f32)

    // positions
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, 0)
    gl.EnableVertexAttribArray(0)

    // colors
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, stride, size_of([3]f32))
    gl.EnableVertexAttribArray(1)

    // texture coords
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, stride, size_of([6]f32))
    gl.EnableVertexAttribArray(2)

    // wireframe polygons
    // gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

    stbi.set_flip_vertically_on_load(1)
    box_texture := load_texture("./textures/container.jpg", gl.RGB)
    smile_texture := load_texture("./textures/awesomeface.png", gl.RGBA)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, box_texture)

    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, smile_texture)

    shader_use(shader_program)
    shader_set_i32(shader_program, "texture1", 0)
    shader_set_i32(shader_program, "texture2", 1)

    for !glfw.WindowShouldClose(window) {
        process_input(window)

        gl.ClearColor(0.2, 0.3, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.BindVertexArray(vao)
        gl.DrawElements(gl.TRIANGLES, len(indices), gl.UNSIGNED_INT, nil)

        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}

load_texture :: proc(filename: cstring, format: u32) -> u32 {
    width, height, nr_channels: i32
    data := stbi.load(filename, &width, &height, &nr_channels, 0)
    defer stbi.image_free(data)

    texture: u32

    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, format, gl.UNSIGNED_BYTE, data)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    return texture
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
