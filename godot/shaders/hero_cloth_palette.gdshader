shader_type canvas_item;
// Costume palette only: original texture, alpha, UVs and silhouettes are unchanged.
varying vec4 actor_tint;
vec3 rgb_hsv(vec3 c) {
 vec4 k=vec4(0.0,-1.0/3.0,2.0/3.0,-1.0);
 vec4 p=mix(vec4(c.bg,k.wz),vec4(c.gb,k.xy),step(c.b,c.g));
 vec4 q=mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));
 float d=q.x-min(q.w,q.y);float e=0.000001;
 return vec3(abs(q.z+(q.w-q.y)/(6.0*d+e)),d/(q.x+e),q.x);
}
vec3 hsv_rgb(vec3 c) {
 vec3 p=abs(fract(c.xxx+vec3(0.0,2.0/3.0,1.0/3.0))*6.0-3.0);
 return c.z*mix(vec3(1.0),clamp(p-1.0,0.0,1.0),c.y);
}
void vertex(){actor_tint=COLOR;}
void fragment(){
 vec4 source=texture(TEXTURE,UV);vec3 hsv=rgb_hsv(source.rgb);vec3 result=source.rgb;
 float cloth=smoothstep(.22,.25,hsv.x)*(1.0-smoothstep(.47,.50,hsv.x))*smoothstep(.12,.20,hsv.y);
 vec3 blue=hsv_rgb(vec3(.602,clamp(hsv.y*.55,.16,.40),min(1.0,hsv.z*1.16+.015)));
 result=mix(result,blue,cloth);
 // Belt and trailing cloth lie near the torso, not at the spearhead's red tassel.
 vec2 cell=fract(UV*4.0);
 float red_distance=min(hsv.x,1.0-hsv.x);
 float belt=(1.0-smoothstep(.045,.070,red_distance))*smoothstep(.50,.65,hsv.y);
 belt*=step(cell.x,.72)*step(.50,cell.y);
 vec3 taupe=hsv_rgb(vec3(.075,.21,hsv.z*.80));
 result=mix(result,taupe,belt);
 COLOR=vec4(result,source.a)*actor_tint;
}
