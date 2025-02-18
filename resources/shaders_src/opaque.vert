#version 450

layout(binding = 1) uniform Render_Pass_UBO {
    mat4 view;
    mat4 proj;
    mat4 viewproj;
} cam_ubo;

layout(location = 0) in vec3 vertPosition;
layout(location = 1) in vec3 vertNormal;
layout(location = 2) in vec4 vertTangent;
// layout(location = 3) in vec2 vertUV;

// layout(location = 0) out vec2 fragUV;
layout(location = 1) out vec3 fragNormal;
layout(location = 2) out vec4 fragTangent;

void main() {
    // fragUV = vertUV;
    
    gl_Position = cam_ubo.viewproj * vec4(vertPosition, 1.0);
    // mat4 modelViewMatrix = ubo.view * ubo.model;
    fragNormal = (cam_ubo.view * vec4(vertNormal, 1.0)).xyz;
    fragTangent = vec4(0.0, 0.0, 0.0, 1.0);
}
