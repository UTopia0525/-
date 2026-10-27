extends RefCounted
## Shared grid profiles for K previews and live action costs/footprints.
var entries: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/martial_tactics.json")).entries
func get_tactics(id: String) -> Dictionary:return entries.get(id,{"action_cost":null,"shape":"unknown","advance":0,"retreat":0,"push":0,"follow":false,"target":"미정","description":"기술 범위를 정하고 있습니다.","status":"pending"}).duplicate(true)
func action_cost_text(id: String) -> String:
 var value=get_tactics(id).get("action_cost")
 return "미정" if value==null else str(int(value))
func summary_text(id: String) -> String:
 var t=get_tactics(id);var parts: Array[String]=[]
 if int(t.advance)>0:parts.append("전진 %d" % int(t.advance))
 if int(t.retreat)>0:parts.append("후퇴 %d" % int(t.retreat))
 if t.follow:parts.append("추격")
 elif int(t.push)>0:parts.append("밀침 %d" % int(t.push))
 parts.append(str(t.target))
 return " · ".join(parts)
func preview(id: String) -> Dictionary:
 var t=get_tactics(id);var p=t.get("preview_origin",[1,2]);var origin=Vector2i(p[0],p[1]);var caster=origin+Vector2i(int(t.advance),0)
 var attacks: Array[Vector2i]=[];var moves: Array[Vector2i]=[]
 if t.has("attack_offsets"):
  for offset in t.attack_offsets:attacks.append(caster+Vector2i(offset[0],offset[1]))
 else:
  match str(t.shape):
   "adjacent":attacks.append(caster+Vector2i.RIGHT)
   "line2":attacks.append_array([caster+Vector2i.RIGHT,caster+Vector2i(2,0)])
   "fan":attacks.append_array([caster+Vector2i(1,-1),caster+Vector2i.RIGHT,caster+Vector2i(1,1)])
   "surround":
    for y in range(-1,2):
     for x in range(-1,2):
      if x!=0 or y!=0:attacks.append(caster+Vector2i(x,y))
 if int(t.advance)>0:moves.append(caster)
 if int(t.retreat)>0:moves.append(origin-Vector2i(int(t.retreat),0))
 if int(t.push)>0:
  for target in attacks:
   for i in range(int(t.push)):
    var point: Vector2i=target+Vector2i(i+1,0)
    if point not in moves:moves.append(point)
   if t.follow and target not in moves:moves.append(target)
 if t.has("move_offsets"):
  moves.clear()
  for offset in t.move_offsets:moves.append(origin+Vector2i(offset[0],offset[1]))
 return {"origin":origin,"attacks":attacks,"moves":moves,"self_target":t.shape=="self","known":t.shape!="unknown"}
