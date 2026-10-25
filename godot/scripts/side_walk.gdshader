shader_type canvas_item;
render_mode unshaded;
uniform vec2 frame_origin;
uniform vec2 frame_extent;
uniform vec2 source_size;
uniform float gait_phase = 0.0;
uniform float walking = 0.0;

void vertex() {
	vec2 local_uv = (UV - frame_origin) / frame_extent;
	float boot_weight = smoothstep(0.85, 0.89, local_uv.y);
	float leg = COLOR.r * 2.0 - 1.0;
	COLOR = vec4(1.0);
	// Keep both feet below the hips at rest. Alternate forward/backward
	// placement while walking, leaving the head and torso vertices untouched.
	VERTEX.x += boot_weight * source_size.x * leg * (-0.16 + sin(gait_phase) * 0.18 * walking);
	VERTEX.y -= boot_weight * source_size.y * 0.035 * max(0.0, leg * cos(gait_phase)) * walking;
}
