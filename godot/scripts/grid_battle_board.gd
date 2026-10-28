extends Control
var battle
var hover=Vector2i(-1,-1)
const AREA=Rect2(270,235,640,300)
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_PASS
func geometry() -> Rect2:
 var columns=battle.grid.field.width;var rows=battle.grid.field.height
 var cell_height=minf(66.0,AREA.size.y/rows);var cell_width=minf(142.0,AREA.size.x/columns)
 var extent=Vector2(cell_width*columns,cell_height*rows)
 return Rect2(AREA.position+(AREA.size-extent)/2,extent)
func cell_size() -> Vector2:return geometry().size/Vector2(battle.grid.field.width,battle.grid.field.height)
func foot(point: Vector2i) -> Vector2:return geometry().position+(Vector2(point)+Vector2(.5,.72))*cell_size()
func pick(point: Vector2) -> Vector2i:
 if not geometry().has_point(point):return Vector2i(-1,-1)
 return Vector2i((point-geometry().position)/cell_size())
func _gui_input(event: InputEvent) -> void:
 if battle.grid==null:return
 if event is InputEventMouseMotion:hover=pick(event.position);queue_redraw()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var point=pick(event.position)
  if battle.grid.field.inside(point):battle.click_cell(point);accept_event()
func _draw() -> void:
 if battle==null or battle.grid==null:return
 var model=battle.grid;var box=geometry();var step=cell_size();var attacks=[];var advance=Vector2i(-1,-1)
 if battle.choice not in ["move","wait",""]:
  var preview=model.footprint(0,battle.choice,battle.facing);attacks=preview.attacks;advance=preview.caster

 for y in range(model.field.height):
  for x in range(model.field.width):
   var point=Vector2i(x,y);var rect=Rect2(box.position+Vector2(point)*step+Vector2(2,2),step-Vector2(4,4))
   var terrain=model.field.cells.get(point,{})
   var color=Color(0,0,0,.045)
   if terrain.has("color"):color=Color(terrain.color)
   if not model.field.walkable(point):color=Color("373d3bdf")
   if point in attacks:color=Color("b85c4488")
   if battle.choice=="move" and model.free_cell(point,0) and (point-model.units[0].position).abs().x+(point-model.units[0].position).abs().y==1:color=Color("5ba68d80")
   draw_rect(rect,color)
   draw_rect(rect.grow(.5),Color("17251db0"),false,3.0)
   draw_rect(rect,Color("ead6abe0"),false,1.5)
   if point in attacks:draw_rect(rect,Color("efac8c"),false,2.0)
   if battle.choice=="move" and model.free_cell(point,0) and absi(point.x-model.units[0].position.x)+absi(point.y-model.units[0].position.y)==1:draw_rect(rect,Color("c6f0d8"),false,2.5)
   if battle.choice=="move" and model.free_cell(point,0) and absi(point.x-model.units[0].position.x)+absi(point.y-model.units[0].position.y)==1:
    var dir=Vector2(point-model.units[0].position).normalized();var side=Vector2(-dir.y,dir.x);var center=rect.get_center()
    draw_colored_polygon(PackedVector2Array([center+dir*12,center-dir*5+side*7,center-dir*2,center-dir*5-side*7]),Color("d5eed9"))
   if not model.field.walkable(point):
    draw_line(rect.position+Vector2(8,8),rect.end-Vector2(8,8),Color("b1aba0"),2)
    draw_line(rect.position+Vector2(8,rect.size.y-8),rect.position+Vector2(rect.size.x-8,8),Color("b1aba0"),2)
   if point==hover:draw_rect(rect,Color("f5d78a"),false,2)
   if point==advance and advance!=model.units[0].position:draw_rect(rect.grow(-5),Color("7dc9b2"),false,2)
 for index in range(2):
  var unit=model.units[index];var center=foot(unit.position)
  draw_actor_ring(center,Vector2(minf(step.x*.28,30),9),Color("82d7bd") if index==0 else Color("db846d"))
  var direction=Vector2(battle.facing if index==0 else unit.facing)*Vector2(14,9)
  draw_line(center,center+direction,Color("f7df9d"),3)
func draw_actor_ring(center: Vector2,extent: Vector2,color: Color) -> void:
 var points=PackedVector2Array()
 for i in range(33):points.append(center+Vector2(cos(TAU*i/32),sin(TAU*i/32))*extent)
 draw_polyline(points,color,2,true)
