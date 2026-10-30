shader_type canvas_item;
render_mode unshaded;
uniform sampler2D mask_map:filter_linear;
uniform sampler2D materials:source_color,filter_linear;
uniform sampler2D rice_field:source_color,filter_linear;
void fragment(){
	vec4 base=texture(TEXTURE,UV);vec4 mask=texture(mask_map,UV);
	vec2 p=UV*vec2(4608.0,3072.0);vec2 uv=clamp(fract(p/320.0),vec2(.004),vec2(.996));
	vec3 earth=texture(materials,(uv+vec2(1.0,0.0))*.5).rgb;
	vec3 stone=texture(materials,uv*.5).rgb;
	vec3 ground=mix(earth,stone,mask.r);
	// A raked grain drying yard is painted terrain, never a solid obstacle.
	float rows=smoothstep(.45,.55,fract(p.y/13.0));
	float grain=fract(sin(dot(floor(p/2.0),vec2(127.1,311.7)))*43758.5453);
	vec3 rice=earth*vec3(1.06,1.0,.83)*(0.98+rows*.025)+vec3(.035,.025,.008)*grain;
	ground=mix(ground,rice,mask.g);
	ground=mix(ground,texture(rice_field,clamp(fract(p/540.0),vec2(.004),vec2(.996))).rgb,mask.b);
	COLOR=vec4(mix(base.rgb,ground,mask.a),base.a);
}
