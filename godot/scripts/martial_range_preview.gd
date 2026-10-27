extends Control
const UI=preload("res://scripts/ui.gd")
var model: Dictionary={}
func configure(value: Dictionary) -> void:
 model=value;mouse_filter=Control.MOUSE_FILTER_IGNORE;queue_redraw()
func _draw() -> void:
 if model.is_empty():return
 var font=UI.BODY_FONT;var cell=Vector2(22,22);var step=Vector2(25,25);var origin=Vector2(12,6)
 for y in range(5):
  for x in range(7):
   var point=Vector2i(x,y);var rect=Rect2(origin+Vector2(x,y)*step,cell)
   var fill=Color("ece7d8");var border=Color("c2bba7")
   if point in model.get("attacks",[]):fill=Color("b77865");border=Color("915b4d")
   if point in model.get("moves",[]):fill=Color("89b4a5");border=Color("497c6b")
   draw_rect(rect,fill);draw_rect(rect,border,false,1)
   if point in model.get("moves",[]) and point in model.get("attacks",[]):draw_line(rect.position,rect.end,Color("915b4d"),3)
   if point==model.origin:
    draw_circle(rect.get_center(),9,Color("28544d"));draw_string(font,rect.position+Vector2(4,16),"나",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f5efde"))
 for i in range(3):
  var point=Vector2(197,19+i*28);var color=[Color("28544d"),Color("b77865"),Color("89b4a5")][i]
  draw_rect(Rect2(point,Vector2(9,9)),color);draw_string(font,point+Vector2(13,10),["자신","공격","이동"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("48564e"))
 draw_string(font,Vector2(194,124),"우측 →",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("716b5d"))
 if not model.known:draw_string(font,Vector2(53,72),"범위 미정",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("48564e"))
