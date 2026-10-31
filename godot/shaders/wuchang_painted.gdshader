shader_type canvas_item;
render_mode unshaded;
uniform sampler2D mask_map:filter_linear;
uniform sampler2D materials:source_color,filter_linear;
void fragment(){
	vec4 base=texture(TEXTURE,UV);vec4 mask=texture(mask_map,UV);
	vec2 p=UV*vec2(8192.0,7680.0);
	vec2 uv=clamp(fract(p/360.0),vec2(.004),vec2(.996));
	vec3 soil=texture(materials,(uv+vec2(1.0,0.0))*.5).rgb;
	vec3 stone=texture(materials,uv*.5).rgb;
	vec3 ground=mix(soil,stone,mask.r);
	ground=mix(ground,texture(materials,(uv+vec2(0.0,1.0))*.5).rgb*vec3(.96,.97,.98),mask.g);
	COLOR=vec4(mix(base.rgb,ground,mask.a),base.a);
}
