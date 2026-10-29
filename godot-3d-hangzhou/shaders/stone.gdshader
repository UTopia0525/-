shader_type spatial;
render_mode cull_disabled;
varying vec3 p;
float hash(vec2 v){return fract(sin(dot(v,vec2(127.1,311.7)))*43758.5453);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 uv=vec2(p.x*1.3+mod(floor(p.z*1.8),2.)*.5,p.z*1.8);
 vec2 tile=floor(uv);vec2 f=fract(uv);float seam=step(.025,f.x)*step(.035,f.y)*step(f.x,.975)*step(f.y,.965);
 float n=hash(tile);vec3 base=mix(vec3(.23,.27,.28),vec3(.39,.38,.34),n);
 ALBEDO=mix(vec3(.12,.15,.16),base,seam);ROUGHNESS=.72;
}
