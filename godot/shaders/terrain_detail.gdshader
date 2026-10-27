shader_type canvas_item;
render_mode unshaded;
uniform sampler2D terrain_detail : source_color, filter_linear, repeat_disable;
uniform vec2 world_size = vec2(6144.0, 4096.0);
uniform float detail_strength : hint_range(0.0, 1.0) = 0.38;
void fragment() {
 vec2 source_size = vec2(textureSize(TEXTURE, 0));
 float texels_per_screen = max(length(dFdx(UV * source_size)), length(dFdy(UV * source_size)));
 float magnification = 1.0 / max(texels_per_screen, .0001);
 float correction = smoothstep(3.0, 7.0, magnification);
 vec4 original = texture(TEXTURE, (floor(UV * source_size) + .5) / source_size);
 vec4 smooth_color = texture(TEXTURE, UV);
 vec4 base = mix(original, smooth_color, correction);
 // Small material detail is anchored in the world, not the moving screen.
 float green = smoothstep(.02, .10, base.g - base.r * .90) * step(base.b * .95, base.g);
 float chroma = max(max(base.r, base.g), base.b) - min(min(base.r, base.g), base.b);
 float stone = (1.0 - smoothstep(.04, .15, chroma)) * step(.38, dot(base.rgb, vec3(.299,.587,.114)));
 vec2 cell = green > .5 ? vec2(1.0, 0.0) : stone > .5 ? vec2(0.0, 1.0) : vec2(0.0);
 float water = smoothstep(.015, .10, base.b - base.r);
 vec2 atlas_size = vec2(textureSize(terrain_detail, 0));
 vec2 local_uv = fract(UV * world_size / 640.0);
 vec2 uv = (cell + clamp(local_uv, vec2(.025), vec2(.975))) * .5;
 vec2 delta = vec2(8.0) / atlas_size;
 vec3 fine = texture(terrain_detail, uv).rgb;
 vec3 broad = (texture(terrain_detail, uv + vec2(delta.x, 0.0)).rgb + texture(terrain_detail, uv - vec2(delta.x, 0.0)).rgb + texture(terrain_detail, uv + vec2(0.0, delta.y)).rgb + texture(terrain_detail, uv - vec2(0.0, delta.y)).rgb) * .25;
 float grain = dot(fine - broad, vec3(.299,.587,.114));
 float seam = smoothstep(0.0,.035,local_uv.x) * smoothstep(0.0,.035,local_uv.y) * smoothstep(0.0,.035,1.0-local_uv.x) * smoothstep(0.0,.035,1.0-local_uv.y);
 base.rgb = clamp(base.rgb + vec3(grain * detail_strength * correction * (1.0-water) * seam), vec3(0.0), vec3(1.0));
 COLOR = base;
}
