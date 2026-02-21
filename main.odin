package main

import "base:runtime"
import "core:bytes"
import "core:c"
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"

VERTEX_SHADER := #load("./shaders/vertex.glsl", cstring)
FRAGMENT_SHADER := #load("./shaders/fragment.glsl", cstring)

main :: proc() {
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

    //gl.Viewport(0, 0, 800, 600)
    glfw.SetFramebufferSizeCallback(window, framebuffer_callback)

    shader_program, err_msg, ok := compile_shader_program()
    if !ok {
        defer delete(err_msg)
        fmt.eprintf("error compiling shader program: %s", err_msg)
        return
    }

    // odinfmt: disable
    vertices := [?]f32{
        -0.5, -0.5, 0.0,
        0.5, -0.5, 0.0,
        0.0, 0.5, 0.0
    }
    // odinfmt: enable

    vbo, vao: u32
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of([3]f32), 0)
    gl.EnableVertexAttribArray(0)

    for !glfw.WindowShouldClose(window) {
        process_input(window)

        gl.ClearColor(0.2, 0.3, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader_program)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}

compile_shader_program :: proc() -> (program: u32, err_msg: string, ok: bool) {
    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_shader, 1, &VERTEX_SHADER, nil)
    gl.CompileShader(vertex_shader)
    if err, ok := check_shader_compile_error(vertex_shader); !ok {
        defer delete(err)
        return 0, fmt.aprintf("error compiling vertex shader: %s", err), false
    }

    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fragment_shader, 1, &FRAGMENT_SHADER, nil)
    gl.CompileShader(fragment_shader)
    if err, ok := check_shader_compile_error(fragment_shader); !ok {
        defer delete(err)
        return 0, fmt.aprintf("error compiling fragment shader: %s", err), false
    }

    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)
    gl.LinkProgram(shader_program)
    if err, ok := check_shader_program_error(shader_program); !ok {
        defer delete(err)
        return 0, fmt.aprintf("error linking shader program: %s", err), false
    }

    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(fragment_shader)

    return shader_program, "", true
}

// on failure, error message must be freed
check_shader_compile_error :: proc(shader: u32) -> (string, bool) {
    success: i32
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
    if bool(success) {
        return "", true
    }

    buf: [512]u8
    gl.GetShaderInfoLog(shader, size_of(buf), nil, raw_data(buf[:]))

    terminator_idx := bytes.index_byte(buf[:], 0)
    if terminator_idx == -1 {
        terminator_idx = len(buf)
    }

    return strings.clone_from(buf[:terminator_idx]), false
}

// on failure, error message must be freed
check_shader_program_error :: proc(program: u32) -> (string, bool) {
    success: i32
    gl.GetProgramiv(program, gl.LINK_STATUS, &success)
    if bool(success) {
        return "", true
    }

    buf: [512]u8
    gl.GetProgramInfoLog(program, size_of(buf), nil, raw_data(buf[:]))

    terminator_idx := bytes.index_byte(buf[:], 0)
    if terminator_idx == -1 {
        terminator_idx = len(buf)
    }

    return strings.clone_from(buf[:terminator_idx]), false
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
