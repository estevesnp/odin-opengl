package main

import "base:runtime"
import "core:log"
import "core:mem"
import "core:os"
import gl "vendor:OpenGL"

ShaderType :: enum (u32) {
    vertex   = gl.VERTEX_SHADER,
    fragment = gl.FRAGMENT_SHADER,
}

Shader :: u32

Compile_Error :: enum {
    None,
    Compile_Shader,
    Link_Program,
}

Error :: union #shared_nil {
    os.Error,
    Compile_Error,
}

shader_use :: proc(shader: Shader) {
    gl.UseProgram(shader)
}

shader_set :: proc {
    shader_set_bool,
    shader_set_i32,
    shader_set_f32,
}

shader_set_bool :: proc(shader: Shader, name: cstring, val: bool) {
    gl.Uniform1i(gl.GetUniformLocation(shader, name), i32(val))
}

shader_set_i32 :: proc(shader: Shader, name: cstring, val: i32) {
    gl.Uniform1i(gl.GetUniformLocation(shader, name), val)
}

shader_set_f32 :: proc(shader: Shader, name: cstring, val: f32) {
    gl.Uniform1f(gl.GetUniformLocation(shader, name), val)
}

shader_init :: proc(vertex_path, fragment_path: string) -> (Shader, Error) {
    arena: mem.Dynamic_Arena
    mem.dynamic_arena_init(&arena)
    defer mem.dynamic_arena_destroy(&arena)

    alloc := mem.dynamic_arena_allocator(&arena)

    vertex, verr := create_shader(vertex_path, .vertex, alloc)
    if verr != nil {
        return {}, verr
    }
    defer gl.DeleteShader(vertex)

    fragment, ferr := create_shader(fragment_path, .fragment, alloc)
    if ferr != nil {
        return {}, ferr
    }
    defer gl.DeleteShader(fragment)

    program := gl.CreateProgram()

    gl.AttachShader(program, vertex)
    gl.AttachShader(program, fragment)
    gl.LinkProgram(program)

    success: i32
    gl.GetProgramiv(program, gl.LINK_STATUS, &success)
    if !bool(success) {
        buf: [512]byte
        raw := raw_data(buf[:])
        gl.GetProgramInfoLog(program, i32(len(buf)), nil, raw)
        log.errorf("error linking shader program: %s", raw)

        return 0, .Link_Program
    }

    return program, nil
}

create_shader :: proc(shader_path: string, type: ShaderType, allocator: mem.Allocator) -> (u32, Error) {
    shader_data, err := os.read_entire_file_from_path(shader_path, allocator)
    if err != nil {
        return 0, err
    }
    defer delete(shader_data, allocator)

    data_c_str := cstring(raw_data(shader_data))
    data_len := i32(len(shader_data))

    shader := gl.CreateShader(u32(type))
    gl.ShaderSource(shader, 1, &data_c_str, &data_len)
    gl.CompileShader(shader)

    success: i32
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
    if !bool(success) {
        buf: [512]byte
        raw := raw_data(buf[:])
        gl.GetShaderInfoLog(shader, i32(len(buf)), nil, raw)
        log.errorf("error compiling shader for path %s: %s", shader_path, raw)

        return 0, .Compile_Shader
    }

    return shader, nil
}
