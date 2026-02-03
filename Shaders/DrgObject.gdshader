shader_type spatial;

uniform sampler2D wall_texture : source_color;
uniform float uv_scale = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
    // Get world position and normals for triplanar calculation
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = abs((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // Calculate weights based on normal direction
    vec3 weights = world_normal / (world_normal.x + world_normal.y + world_normal.z);

    // Sample texture from 3 axes (X, Y, Z)
    vec3 samp_x = texture(wall_texture, world_pos.zy * uv_scale).rgb;
    vec3 samp_y = texture(wall_texture, world_pos.xz * uv_scale).rgb;
    vec3 samp_z = texture(wall_texture, world_pos.xy * uv_scale).rgb;

    // Blend them together
    ALBEDO = samp_x * weights.x + samp_y * weights.y + samp_z * weights.z;
}

void light() {
    // Basic toon banding for environment
    float dot_p = dot(NORMAL, LIGHT);
    float ramp = step(0.1, dot_p) * 0.6 + 0.4; // Simple 2-band light
    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ramp * ATTENUATION;
}