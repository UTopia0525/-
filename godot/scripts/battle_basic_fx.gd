extends Node2D
var profile: Dictionary={}
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
 if not profile.is_empty() and kind in ["attack","hit"]:
  _personal(t);return
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

func _personal(t: float) -> void:
 var tint=Color(profile.get("color","ffe6b5"))
 var style=str(profile.get("style","swift_sword"))
 var angle=direction.angle()
 if kind=="hit":
  if style=="heavy_fist":
   draw_arc(Vector2.ZERO,8+t*32,0,TAU,16,tint,3*(1-t))
  for i in range(6 if style=="swift_sword" else 8):
   var ray=Vector2.from_angle(i*TAU/8+angle)
   draw_line(ray*(3+t*10),ray*(10+t*27),tint,2.5*(1-t),true)
  return
 if style=="heavy_fist":
  draw_circle(direction*t*16,10+t*12,Color(tint,.15))
  draw_arc(direction*t*16,12+t*20,0,TAU,16,tint,4*(1-t))
  for i in range(5):
   var p=Vector2(-14+i*7,18+t*8);draw_line(p,p-direction*12*(1-t),Color("baa07a"),2)
 elif style=="heavy_saber":
  draw_arc(Vector2.ZERO,28+t*9,angle-1.2+t*.5,angle+1.1+t*.5,18,Color(tint,.32),9*(1-t))
  draw_arc(Vector2.ZERO,32+t*9,angle-1.2+t*.5,angle+1.1+t*.5,18,tint,4*(1-t))
 elif style=="cloud_sword":
  for i in range(3):
   var center=direction*(i*9-5)+Vector2(0,(i%2)*7-8)
   draw_arc(center,13+t*15,angle-1.7,angle+.7,18,Color(tint,1-i*.2),2)
 else:
  draw_line(-direction*(18-t*8),direction*(30+t*20),Color(tint,.3),5*(1-t),true)
  draw_line(-direction*(18-t*8),direction*(30+t*20),tint,2*(1-t),true)
  draw_arc(Vector2.ZERO,25+t*9,angle-1,angle+.7,18,tint,1.5,true)
