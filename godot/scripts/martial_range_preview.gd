extends Control
## Shared data-driven range artwork for battle and K. No per-art raster crop needed.
const UI=preload("res://scripts/ui.gd")
const Arts=preload("res://scripts/martial_arts.gd")
var model: Dictionary={}
var skill: Dictionary={}
var art_id=""
var sheet: Texture2D=preload("res://assets/battle/hero-poses.png")
var frames: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/battle/frames.json")).hero.frames
const RED=Color("f18b79")
const CYAN=Color("6de0d3")
const GOLD=Color("f9cc71")
func configure(value: Dictionary) -> void:
 model=value;art_id=str(model.get("id",""));skill=Arts.new().get_skill(art_id)
 mouse_filter=Control.MOUSE_FILTER_IGNORE;queue_redraw()
func point(cell: Vector2) -> Vector2:return Vector2(8,12)+cell*Vector2(25,25)+Vector2(11,11)
func arrow(a: Vector2,b: Vector2,color: Color,dashed: bool=false) -> void:
 if dashed:draw_dashed_line(a,b,color,2,4)
 else:draw_line(a,b,color,2)
 var dir=(b-a).normalized();var side=Vector2(-dir.y,dir.x)
 draw_colored_polygon(PackedVector2Array([b,b-dir*7+side*3,b-dir*7-side*3]),color)
func actor(cell: Vector2,alpha: float=1.0) -> void:
 var kind=str(skill.get("required_weapon_type","sword"));var col=int({"sword":0,"saber":1,"spear":2,"none":3}.get(kind,0))
 var r=frames[str(col)].region;var source=Rect2(r[0],r[1],r[2],r[3]);var p=point(cell)
 draw_texture_rect_region(sheet,Rect2(p-Vector2(15,30),Vector2(34,34)),source,Color(1,1,1,alpha))
func _draw() -> void:
 if model.is_empty():return
 # Reference canvas250x164 scales into either HUD without changing its footprint.
 draw_set_transform(Vector2.ZERO,0,size/Vector2(250,164))
 draw_style_box(_background(),Rect2(0,0,250,164))
 var origin=Vector2(model.origin);var caster=Vector2(model.get("caster",model.origin))
 for y in range(5):
  for x in range(7):
   var cell=Vector2i(x,y);var rect=Rect2(Vector2(8,12)+Vector2(x,y)*25,Vector2(23,23));var hit=cell in model.get("attacks",[])
   draw_rect(rect,Color("a54d46") if hit else Color("21343b"));draw_rect(rect,RED if hit else Color("526066"),false,1)
   if hit:
    for offset in [5,11,17]:draw_line(rect.position+Vector2(offset-2,16),rect.position+Vector2(offset+3,6),Color("ffd5ae"),1)
 draw_arc(point(caster),9,0,TAU,24,CYAN,2)
 if caster!=origin:
  actor(origin,.22);arrow(point(origin)+Vector2(0,9),point(caster)+Vector2(0,9),CYAN)
 actor(caster)
 if int(model.get("retreat",0))>0:
  var end=caster-Vector2(int(model.retreat),0);actor(end,.22)
  arrow(point(caster)+Vector2(0,9),point(end)+Vector2(0,9),CYAN,true)
 if int(model.get("push",0))>0:
  for target in model.get("attacks",[]):
   var p=point(Vector2(target));draw_circle(p,2,GOLD);arrow(p+Vector2(3,3),p+Vector2(25*int(model.push),3),GOLD)
 var guard=int(skill.get("guard_percent",20 if skill.get("weapon_style","")=="sword" or art_id=="basic_defense" else 0))
 if guard>0:
  var p=point(caster)-Vector2(13,12)
  draw_colored_polygon(PackedVector2Array([p+Vector2(-6,-6),p+Vector2(6,-6),p+Vector2(5,3),p+Vector2(0,8),p+Vector2(-5,3)]),Color("86c9f4"))
  label(Vector2(190,110),"방어 %d%%" % guard,Color("86c9f4"),10)
 if int(skill.get("qi_restore_inner_percent",0))>0:
  for radius in [13,18,23]:draw_arc(point(caster),radius,0,TAU,36,CYAN,1)
  label(Vector2(190,127),"내기 +%d%%" % int(skill.qi_restore_inner_percent),CYAN,9)
 var cooldown=int(skill.get("cooldown_turns",0))
 if cooldown>0:label(Vector2(190,144),"대기 %d행동" % cooldown,GOLD,9)
 for i in range(3):
  var p=Vector2(190,25+i*24);draw_rect(Rect2(p-Vector2(0,8),Vector2(7,7)),[RED,CYAN,GOLD][i])
  label(p+Vector2(11,0),["공격","이동","밀침"][i],Color("f2ead9"),11)
 label(Vector2(9,155),"시전 → · 점선은 공격 후 후퇴",Color("b3c3c8"),10)
 if not model.get("known",false):label(Vector2(45,78),"범위 미정",GOLD,14)
func label(p: Vector2,text: String,color: Color,font_size: int) -> void:
 draw_string(UI.BODY_FONT,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _background() -> StyleBoxFlat:
 var style=StyleBoxFlat.new();style.bg_color=Color("101b24");style.set_corner_radius_all(5);return style
