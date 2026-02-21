#version 330 core
layout(location = 0) in vec3 aPos;

out vec4 vertexColor;

void main() {
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    vertexColor = vec4(
            abs(aPos.x + aPos.y),
            abs(aPos.y + aPos.z),
            abs(aPos.z + aPos.x),
            1.0);
}
