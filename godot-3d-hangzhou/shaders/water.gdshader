shader_type spatial;
render_mode cull_disabled;
varying vec3 point;
void vertex(){point=VERTEX;VERTEX.y+=sin(VERTEX.x*1.3+TIME*.7)*.035+cos(VERTEX.z*.8-TIME*.45)*.025;}
void fragment(){
 float ripple=sin(point.x*6.+sin(point.z*1.9+TIME*.6)*1.3+TIME*.8)*sin(point.z*9.-TIME*.45);
 float thread=pow(max(0.,ripple),18.);
 vec3 deep=vec3(.018,.10,.14);vec3 teal=vec3(.045,.19,.21);
 vec3 color=mix(deep,teal,.5+.5*sin(point.x*.25+point.z*.2));
 float nearbank=exp(-pow((abs(point.x)-9.2)*.7,2.));
 float gold=nearbank*pow(max(0.,sin(point.z*1.35+sin(point.x*4.+TIME)*.35)),14.);
 ALBEDO=color+thread*.075+gold*vec3(.36,.13,.025);
 METALLIC=.5;ROUGHNESS=.27;SPECULAR=.75;
 EMISSION=gold*vec3(.14,.045,.005)+thread*vec3(.01,.025,.03);
}
