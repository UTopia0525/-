extends Node2D
var token=0
var kind="hit"
var elapsed=0.0
var duration=.38
var direction=Vector2.RIGHT
func _process(delta: float) -> void:
 if get_parent().generation!=token or not get_parent().running:queue_free();return
 elapsed+=delta
 if elapsed>=duration:queue_free();return
 modulate.a=pow(1-elapsed/duration,.65);queue_redraw()
func _draw() -> void:
 var t=elapsed/duration
 if kind=="attack":
  var angle=direction.angle()
  for i in range(3):draw_arc(Vector2.ZERO,28+i*4,angle-1.3+t*.7,angle+1.0+t*.7,24,Color(1,.91,.64,.8-i*.2),3-i*.7,true)
 elif kind=="guard":
  draw_arc(Vector2.ZERO,22+t*10,-PI*.9,-PI*.1,25,Color("a4e4de"),3,true)
  draw_circle(Vector2.ZERO,20+t*8,Color(.3,.8,.8,.12))
 elif kind=="step":
  for i in range(5):draw_circle(Vector2(cos(i*2.4)*t*24,sin(i*2.4)*t*7),2*(1-t),Color("cabb98"))
 else:
  for i in range(8):
   var dir=Vector2.from_angle(i*TAU/8+.2)
   draw_line(dir*(5+t*12),dir*(11+t*24),Color("ffe6b5"),2*(1-t),true)
