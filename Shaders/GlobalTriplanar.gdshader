shader_type spatial;

// Access the global texture defined in Project Settings
global uniform sampler2D global_surface_tex : repeat_enable;
uniform vec4 base_color : source_color;

uniform float texture_intensity = 1.0;

uniform float scroll_speed_x = 0.0;
uniform float scroll_speed_y = 0.0;

void fragment() {
	 // Offset the UV by time multiplied by speed
    vec2 moving_uv = UV;
    moving_uv.x += TIME * scroll_speed_x;
    moving_uv.y += TIME * scroll_speed_y;

    // Get the world position of the pixel
    //vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Simple triplanar mapping (X-axis projection)
    // For a full DRG effect, you would blend X, Y, and Z projections
    vec3 tex_color = texture(global_surface_tex, moving_uv).rbg * texture_intensity;
	tex_color *= dot(tex_color.rgb, vec3(0.2126, 0.7152, 0.0722));

    // Mix the global texture with the object's base color

    ALBEDO = ALBEDO * (base_color.rgb + tex_color);
}