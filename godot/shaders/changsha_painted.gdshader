shader_type canvas_item;
render_mode unshaded;
uniform sampler2D mask_map:filter_linear;
uniform sampler2D materials:source_color,filter_linear;
void fragment(){
	vec4 base=texture(TEXTURE,UV);
	vec4 mask=texture(mask_map,UV);
	vec2 p=UV*vec2(6144.0,4096.0);
	vec2 repeat_uv=clamp(fract(p/360.0),vec2(.004),vec2(.996));
	vec3 earth=texture(materials,(repeat_uv+vec2(1.0,0.0))*.5).rgb*vec3(.97,.98,1.0);
	vec3 stone=texture(materials,repeat_uv*.5).rgb;
	vec3 floor_color=mix(earth,stone,mask.r);
	floor_color=mix(floor_color,texture(materials,(repeat_uv+vec2(0.0,1.0))*.5).rgb*vec3(.95,.96,.98),mask.g);
	COLOR=vec4(mix(base.rgb,floor_color,mask.a),base.a);
}
