shader_type canvas_item;
render_mode unshaded;
// Preserve the authored shore/road geometry, while sampling new material detail
// in WORLD units. A 1440p window no longer magnifies a tiny whole-city texture.
uniform sampler2D material_atlas : source_color, filter_linear;
uniform sampler2D district_mask : filter_linear;
uniform vec2 world_extent=vec2(6144.0,4096.0);
vec4 swatch(float id,vec2 point) {
	vec2 cell=vec2(mod(id,3.0),floor(id/3.0));
	vec2 uv=fract(point/280.0);
	uv=clamp(uv,vec2(0.002),vec2(0.998));
	return texture(material_atlas,(cell+uv)/vec2(3.0,2.0));
}
void fragment() {
	vec4 base=texture(TEXTURE,UV);
	vec4 mask=texture(district_mask,UV);
	vec2 px=vec2(2.0)/vec2(1536.0,1024.0);
	mask=(mask*4.0+texture(district_mask,UV+vec2(px.x,0.0))+texture(district_mask,UV-vec2(px.x,0.0))+texture(district_mask,UV+vec2(0.0,px.y))+texture(district_mask,UV-vec2(0.0,px.y)))/8.0;
	vec2 point=UV*world_extent;
	vec3 earth=swatch(0.0,point).rgb;
	vec3 stone=swatch(2.0,point).rgb;
	vec3 brick=swatch(1.0,point).rgb;
	vec3 quay=swatch(3.0,point).rgb;
	vec3 floor_ink=mix(earth,stone,mask.r);
	floor_ink=mix(floor_ink,brick,mask.g);
	floor_ink=mix(floor_ink,quay,mask.b);
	// Retain hand-authored joins, bank edging and local colour variation.
	vec3 tone=base.rgb/max(vec3(0.18),vec3(dot(base.rgb,vec3(.299,.587,.114))));
	floor_ink*=mix(vec3(1.0),clamp(tone,vec3(.75),vec3(1.25)),.16);
	vec3 final_ink=mix(base.rgb,floor_ink,mask.a);
	// Preserve vegetation/edging from the authored floor instead of painting over it.
	float greenery=smoothstep(.015,.10,base.g-base.r);
	greenery*=smoothstep(.0,.08,base.g-base.b);
	final_ink=mix(final_ink,base.rgb,greenery*.85);
	float water=smoothstep(.06,.22,base.b-base.r)*smoothstep(.01,.10,base.b-base.g);
	vec2 art=UV*vec2(1536.0,1024.0);
	float river_band=step(775.0,art.y)*(1.0-step(900.0,art.y));
	float harbor=(1.0-step(181.0,art.x))*(1.0-step(380.0,art.y));
	harbor=max(harbor,(1.0-step(75.0,art.x))*step(564.0,art.y)*(1.0-step(714.0,art.y)));
	water*=max(river_band,harbor);
	final_ink=mix(final_ink,swatch(5.0,point).rgb,water*.86);
	COLOR=vec4(final_ink,base.a);
}
