package main

import "core:math"
import "core:math/linalg/glsl"


Camera :: struct {
    pos:   [3]f32,
    front: [3]f32,
    up:    [3]f32,
    yaw:   f32,
    pitch: f32,
    fov:   f32,
}

Cam_Direction :: enum {
    Front,
    Back,
    Right,
    Left,
    Up,
    Down,
}

sens: f32 : 0.03

camera_init :: proc() -> Camera {
    cam := Camera{
        pos   = {0, 0, 0},
        front = {0, 0, -1},
        up    = {0, 1, 0},
        yaw   = -90,
        pitch = 0,
        fov   = 45,
    }
    camera_update_vectors(&cam)

    return cam
}

camera_init_pos :: proc(pos: [3]f32) -> Camera {
    cam := Camera{
        pos   = pos,
        front = {0, 0, -1},
        up    = {0, 1, 0},
        yaw   = -90,
        pitch = 0,
        fov   = 45,
    }
    camera_update_vectors(&cam)

    return cam
}

camera_view_matrix :: proc(cam: Camera) -> matrix[4, 4]f32 {
    return glsl.mat4LookAt(cam.pos, cam.pos + cam.front, cam.up)
}

camera_update_keyboard :: proc(cam: ^Camera, direction: Cam_Direction, ammt: f32) {
    switch direction {
    case .Front:
        cam.pos += cam.front * ammt
    case .Back:
        cam.pos -= cam.front * ammt

    case .Right:
        cam.pos += glsl.normalize(glsl.cross(cam.front, cam.up)) * ammt
    case .Left:
        cam.pos -= glsl.normalize(glsl.cross(cam.front, cam.up)) * ammt

    case .Up:
        cam.pos.y += ammt
    case .Down:
        cam.pos.y -= ammt
    }
}

last_x: f32 = 400
last_y: f32 = 300
first_mouse := true
camera_update_mouse_movement :: proc(cam: ^Camera, pos_x, pos_y: f32) {
    if first_mouse {
        last_x = f32(pos_x)
        last_y = f32(pos_y)
        first_mouse = false
    }

    offset_x := f32(pos_x) - last_x
    offset_y := last_y - f32(pos_y)
    last_x = f32(pos_x)
    last_y = f32(pos_y)

    offset_x *= sens
    offset_y *= sens

    cam.yaw += offset_x
    cam.pitch = clamp(cam.pitch + offset_y, -89, 89)

    camera_update_vectors(cam)
}

camera_update_vectors :: proc(cam: ^Camera) {
    front: [3]f32

    yaw_rad := glsl.radians(cam.yaw)
    pitch_rad := glsl.radians(cam.pitch)

    yaw_cos := math.cos(yaw_rad)
    yaw_sin := math.sin(yaw_rad)

    pitch_cos := math.cos(pitch_rad)
    pitch_sin := math.sin(pitch_rad)

    front.x = yaw_cos * pitch_cos
    front.y = pitch_sin
    front.z = yaw_sin * pitch_cos

    cam.front = glsl.normalize(front)
}

camera_update_mouse_scroll :: proc(cam: ^Camera, offset_y: f32) {
    cam.fov = clamp(cam.fov - offset_y, 1, 45)
}

