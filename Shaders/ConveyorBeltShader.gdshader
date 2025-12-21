shader_type spatial;

uniform sampler2D belt_texture : repeat_enable;
uniform float scroll_speed_x = 1.0;
uniform float scroll_speed_y = 0.0;

void fragment() {
    // Offset the UV by time multiplied by speed
    vec2 moving_uv = UV;
    moving_uv.x += TIME * scroll_speed_x;
    moving_uv.y += TIME * scroll_speed_y;

    // Apply the offset UV to the texture
    vec4 tex = texture(belt_texture, moving_uv);
    ALBEDO = ALBEDO * tex.rgb;
}
