package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import "core:math/linalg/glsl"
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

    shader, err := shader_init("./shaders/vertex.glsl", "./shaders/fragment.glsl")
    if err != nil {
        log.errorf("error creating shader program: %v", err)
        return
    }


    // odinfmt: disable

    vertices := [?]f32{
        // positions       // texture coords
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0
    }
    indices := [?]u32{
        0, 1, 3,   // first triangle
        1, 2, 3    // second triangle
    }
    cube_positions := [?]glsl.vec3 {
        {  0.0,  0.0,  0.0  },
        {  2.0,  5.0, -15.0 },
        { -1.5, -2.2, -2.5  },
        { -3.8, -2.0, -12.3 },
        {  2.4, -0.4, -3.5  },
        { -1.7,  3.0, -7.5  },
        {  1.3, -2.0, -2.5  },
        {  1.5,  2.0, -2.5  },
        {  1.5,  0.2, -1.5  },
        { -1.3,  1.0, -1.5  },
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

    stride: i32 = size_of([5]f32)

    // positions
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, 0)
    gl.EnableVertexAttribArray(0)

    // texture coords
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, stride, size_of([3]f32))
    gl.EnableVertexAttribArray(1)

    // wireframe polygons
    // gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

    stbi.set_flip_vertically_on_load(1)
    box_texture := load_texture("./textures/container.jpg", gl.RGB)
    smile_texture := load_texture("./textures/awesomeface.png", gl.RGBA)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, box_texture)

    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, smile_texture)

    shader_use(shader)
    shader_set_i32(shader, "texture1", 0)
    shader_set_i32(shader, "texture2", 1)

    gl.Enable(gl.DEPTH_TEST)

    cam: Camera = {
        pos   = {0, 0, 3},
        front = {0, 0, -1},
        up    = {0, 1, 0},
    }

    for !glfw.WindowShouldClose(window) {
        process_input(window, &cam)

        gl.ClearColor(0.2, 0.3, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        view := glsl.mat4LookAt(cam.pos, cam.pos + cam.front, cam.up)

        projection: glsl.mat4 = 1
        projection *= glsl.mat4Perspective(glsl.radians(f32(45)), 800.0 / 600.0, 0.1, 100)

        shader_use(shader)
        shader_set(shader, "view", view)
        shader_set(shader, "projection", projection)

        gl.BindVertexArray(vao)

        for pos, idx in cube_positions {
            model: glsl.mat4 = 1

            model *= glsl.mat4Translate(pos)

            angle := 20.0 * f32(idx)
            model *= glsl.mat4Rotate({1, 0.3, 0.5}, glsl.radians(angle))

            shader_set(shader, "model", model)
            gl.DrawArrays(gl.TRIANGLES, 0, 36)
        }

        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}

Camera :: struct {
    pos:   [3]f32,
    front: [3]f32,
    up:    [3]f32,
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

delta_time: f32 = 0
last_frame: f32 = 0
process_input :: proc(window: glfw.WindowHandle, cam: ^Camera) {
    if glfw.GetKey(window, glfw.KEY_Q) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }

    current_frame := f32(glfw.GetTime())
    delta_time = current_frame - last_frame
    last_frame = current_frame

    cam_speed := 2.5 * delta_time

    if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
        cam.pos += cam.front * cam_speed
    }
    if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
        cam.pos -= cam.front * cam_speed
    }

    if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
        cam.pos -= glsl.normalize(glsl.cross(cam.front, cam.up)) * cam_speed
    }
    if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
        cam.pos += glsl.normalize(glsl.cross(cam.front, cam.up)) * cam_speed
    }
}

framebuffer_callback :: proc "c" (window: glfw.WindowHandle, width, height: c.int) {
    context = runtime.default_context()
    fmt.printf("got callback for width %d, height %d, window %v\n", width, height, window)

    gl.Viewport(0, 0, width, height)
}
