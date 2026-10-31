shader_type canvas_item;
render_mode unshaded;
uniform sampler2D mask_map:filter_linear;
uniform sampler2D materials:source_color,filter_linear;
uniform sampler2D old_terrain:source_color,filter_linear;
uniform sampler2D outdoor_materials:source_color,filter_linear;
void fragment(){
	vec2 art=UV*vec2(1840.0,1760.0);
	vec2 old_uv=vec2(art.x/1760.0,fract((art.y-400.0+1280.0)/1280.0));
	vec4 base=texture(old_terrain,clamp(old_uv,vec2(.001),vec2(.999)));
	if(art.x>1490.0 && art.y<460.0)base=texture(old_terrain,vec2((art.x-1390.0)/1760.0,fract(art.y/1280.0)));
	vec4 mask=texture(mask_map,UV);vec2 p=art*3.2;
	vec2 uv=clamp(fract(p/360.0),vec2(.004),vec2(.996));
	vec3 soil=texture(materials,(uv+vec2(1.0,0.0))*.5).rgb;
	vec3 stone=texture(materials,uv*.5).rgb;
	vec3 pale=texture(materials,(uv+vec2(0.0,1.0))*.5).rgb;
	vec3 wood=texture(materials,(uv+vec2(1.0,1.0))*.5).rgb;
	vec3 grass=texture(outdoor_materials,(uv+vec2(0.0,1.0))*.5).rgb*vec3(.85,.91,.78);
	// Only the settlement behind the wall is paved. The northern rural approach stays earth.
	if(art.x>=433.0 && art.x<1808.0 && art.y>=400.0 && art.y<1680.0)soil=pale;
	vec3 floor_color=mix(mix(soil,stone,mask.r),pale,mask.g);
	float field=1.0-smoothstep(.03,.1,abs(mask.b-.25));
	float dock=1.0-smoothstep(.05,.18,abs(mask.b-.5));
	floor_color=mix(floor_color,grass,field);floor_color=mix(floor_color,wood,dock);
	floor_color=mix(floor_color,soil*vec3(.78,.80,.78),smoothstep(.7,.95,mask.b));
	COLOR=vec4(mix(base.rgb,floor_color,mask.a),1.0);
}
