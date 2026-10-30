shader_type canvas_item;
render_mode unshaded;
// Preserve the authored shore/road geometry, while sampling new material detail
// in WORLD units. A 1440p window no longer magnifies a tiny whole-city texture.
uniform sampler2D material_atlas : source_color, filter_linear;
uniform sampler2D district_mask : filter_linear;
uniform vec2 world_extent=vec2(6144.0,4096.0);
uniform bool market_enabled=false;
uniform bool capital_materials=false;
uniform vec4 market_bounds=vec4(738.0,286.0,292.0,240.0);
uniform sampler2D market_materials : source_color, filter_linear;
uniform vec4 market_shadows[4];
vec3 market_swatch(vec2 cell,vec2 point,float scale) {
	vec2 uv=clamp(fract(point/scale),vec2(.004),vec2(.996));
	return texture(market_materials,(cell+uv)*.5).rgb;
}
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
	if(capital_materials) {
		earth=market_swatch(vec2(1.0,0.0),point,380.0);
		stone=market_swatch(vec2(0.0,0.0),point,320.0);
		brick=market_swatch(vec2(0.0,1.0),point,380.0)*vec3(1.0,.97,.93);
		quay=market_swatch(vec2(0.0,1.0),point,320.0);
	}
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
	final_ink=mix(final_ink,base.rgb,greenery*(0.85*(1.0-float(capital_materials))));
	float water=smoothstep(.06,.22,base.b-base.r)*smoothstep(.01,.10,base.b-base.g);
	vec2 art=UV*vec2(1536.0,1024.0);
	float river_band=step(775.0,art.y)*(1.0-step(900.0,art.y));
	float harbor=(1.0-step(181.0,art.x))*(1.0-step(380.0,art.y));
	harbor=max(harbor,(1.0-step(75.0,art.x))*step(564.0,art.y)*(1.0-step(714.0,art.y)));
	water*=max(river_band,harbor);
	final_ink=mix(final_ink,swatch(5.0,point).rgb,water*.86);
	if (market_enabled) {
		vec2 lo=market_bounds.xy,hi=lo+market_bounds.zw;
		vec2 join=smoothstep(lo,lo+vec2(9.0),art)*(1.0-smoothstep(hi-vec2(9.0),hi,art));
		float region=join.x*join.y;
		// A quiet brick spine connects the four thresholds and the east-west alley.
		float vertical=1.0-smoothstep(12.0,19.0,abs(art.x-889.0));
		float crossing=1.0-smoothstep(9.0,17.0,abs(art.y-405.0));
		float entrance=smoothstep(500.0,518.0,art.y);
		float north_crossing=1.0-smoothstep(8.0,13.0,abs(art.y-315.0));
		float paving=max(max(max(vertical,crossing),entrance),north_crossing);
		vec3 soil=market_swatch(vec2(1.0,0.0),point,380.0);
		vec3 pavers=market_swatch(vec2(0.0,0.0),point,320.0);
		vec3 local=mix(soil,pavers,paving);
		float shade=0.0;
		for(int i=0;i<4;i++) {
			vec4 s=market_shadows[i];
			vec2 distance=abs(art-(s.xy+s.zw*.5))-s.zw*.5;
			shade=max(shade,1.0-smoothstep(-1.0,5.0,max(distance.x,distance.y)));
			// A little worn stone below each shop joins the authored doorstep.
			vec2 apron=abs(art-(s.xy+vec2(s.z*.5,9.0)))-vec2(s.z*.46,5.0);
			float threshold=1.0-smoothstep(-.3,1.7,max(apron.x,apron.y));
			local=mix(local,market_swatch(vec2(0.0,1.0),point,260.0),threshold*.75);
		}
		local*=1.0-shade*.19;
		final_ink=mix(final_ink,local,region);
	}
	COLOR=vec4(final_ink,base.a);
}
