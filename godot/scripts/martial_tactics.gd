extends RefCounted
## Display metadata for the new combat design. Never used to charge runtime resources.
var entries: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/martial_tactics.json")).entries
func get_tactics(id: String) -> Dictionary:return entries.get(id,{"action_cost":null,"shape":"unknown","advance":0,"retreat":0,"push":0,"follow":false,"target":"미정","description":"기술 범위를 정하고 있습니다.","status":"pending"}).duplicate(true)
func action_cost_text(id: String) -> String:
 var value=get_tactics(id).get("action_cost")
 return "미정" if value==null else str(int(value))
func range_text(id: String) -> String:return {"adjacent":"인접1칸","fan":"전방3칸","surround":"주변8칸","line2":"직선2칸","self":"자신"}.get(get_tactics(id).shape,"미정")
func summary_text(id: String) -> String:
 var t=get_tactics(id);var value=range_text(id)
 if int(t.advance)>0:return "전진%d · %s" % [int(t.advance),value]
 if int(t.retreat)>0:return "%s · 후퇴%d" % [value,int(t.retreat)]
 if t.follow:return value+" · 추격"
 if int(t.push)>0:return "%s · 밀침%d" % [value,int(t.push)]
 return value
func preview(id: String) -> Dictionary:
 var t=get_tactics(id);var origin=Vector2i(1,2);var caster=origin+Vector2i(int(t.advance),0)
 var attacks: Array[Vector2i]=[];var moves: Array[Vector2i]=[]
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
  var target=caster+Vector2i.RIGHT
  for i in range(int(t.push)):moves.append(target+Vector2i(i+1,0))
  if t.follow:moves.append(target)
 return {"origin":origin,"attacks":attacks,"moves":moves,"self_target":t.shape=="self","known":t.shape!="unknown"}
