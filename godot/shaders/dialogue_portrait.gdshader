shader_type canvas_item;
// Sample a calibrated portrait window; transparent padding keeps the source art intact.
uniform vec2 frame_origin = vec2(0.0);
uniform vec2 frame_size = vec2(1024.0, 1536.0);
uniform vec2 source_size = vec2(1024.0, 1536.0);
varying vec4 portrait_tint;
void vertex() {
	portrait_tint = COLOR;
}
void fragment() {
	vec2 sample_uv = (frame_origin + UV * frame_size) / source_size;
	vec4 ink = texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0)));
	float inside = step(0.0, sample_uv.x) * step(sample_uv.x, 1.0) * step(0.0, sample_uv.y) * step(sample_uv.y, 1.0);
	COLOR = portrait_tint * vec4(ink.rgb, ink.a * inside);
}
