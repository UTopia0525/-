shader_type canvas_item;
render_mode unshaded;
uniform sampler2D mask_map:filter_linear;
uniform sampler2D materials:source_color,filter_linear;
void fragment(){
	vec4 base=texture(TEXTURE,UV);vec4 mask=texture(mask_map,UV);
	vec2 p=UV*vec2(5632.0,4096.0);
	vec2 uv=clamp(fract(p/360.0),vec2(.004),vec2(.996));
	vec3 soil=texture(materials,(uv+vec2(1.0,0.0))*.5).rgb;
	vec3 stone=texture(materials,uv*.5).rgb;
	vec3 pale=texture(materials,(uv+vec2(0.0,1.0))*.5).rgb;
	vec3 wood=texture(materials,(uv+vec2(1.0,1.0))*.5).rgb;
	vec3 floor_color=mix(mix(soil,stone,mask.r),pale,mask.g);
	float dock=1.0-smoothstep(.05,.18,abs(mask.b-.5));
	floor_color=mix(floor_color,wood,dock);
	floor_color=mix(floor_color,soil*vec3(.78,.80,.78),smoothstep(.7,.95,mask.b));
	COLOR=vec4(mix(base.rgb,floor_color,mask.a),base.a);
}
