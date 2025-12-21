shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// Semi-transparent blue
uniform vec4 albedo : source_color = vec4(0.0, 0.5, 1.0, 0.4);

void fragment() {
    ALBEDO = albedo.rgb;
    ALPHA = albedo.a;
}
