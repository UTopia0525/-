extends Node2D
## A non-blocking passage marker. Travel is committed only by the shared F action.
const BLUE=Color("50bfff")
const CORE=Color("c1f6ff")
var phase:=0.0
var available:=false
func set_available(value: bool) -> void:
	if available!=value:available=value;queue_redraw()
func _process(delta: float) -> void:
	phase=fmod(phase+delta,TAU*10)
	queue_redraw()
func ellipse(center: Vector2,radius: Vector2,start: float=0.0,end: float=TAU) -> PackedVector2Array:
	var points=PackedVector2Array()
	for i in range(65):
		var angle=lerpf(start,end,i/64.0)
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	return points
func _draw() -> void:
	var pulse=.85+sin(phase*2)*.15
	var center=Vector2(0,-55)
	var radius=Vector2(31,52)*(1.06 if available else 1.0)
	# Soft blue glow and a transparent opening keep terrain and characters visible.
	for i in range(5,0,-1):
		draw_polyline(ellipse(center,radius+Vector2.ONE*i*1.8),Color(BLUE,.025*pulse),3,true)
	draw_colored_polygon(ellipse(center,radius),Color("1d79e0",.19 if available else .11))
	draw_polyline(ellipse(center,radius),Color(BLUE,.95*pulse),3.5 if available else 2.5,true)
	draw_polyline(ellipse(center,radius-Vector2(6,5),phase*1.6,phase*1.6+PI*1.35),Color(CORE,.8),1.8,true)
	draw_polyline(ellipse(Vector2.ZERO,Vector2(47,15)),Color(BLUE,.65),2,true)
	draw_polyline(ellipse(Vector2.ZERO,Vector2(38,11),-phase,TAU-phase),Color(CORE,.6*pulse),1,true)
	for i in range(9):
		var t=fmod(phase*.25+i/9.0,1.0)
		var p=Vector2(sin(i*2.7+phase)*36,-t*115)
		draw_circle(p,1.3 if i%2 else 2.0,Color(CORE,sin(t*PI)*.8))
	if available:
		draw_colored_polygon(PackedVector2Array([Vector2(-6,-129),Vector2(6,-129),Vector2(0,-120)]),CORE)
