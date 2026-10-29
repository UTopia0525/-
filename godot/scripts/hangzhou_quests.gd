extends "res://scripts/suzhou_quests.gd"
## Civilian Hangzhou and Cuiyue errands; each has independent progress and reporting.
func _ready() -> void:
 people=JSON.parse_string(FileAccess.get_file_as_string("res://data/hangzhou_residents.json"))
 people.npcs.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://data/cuiyue_hall_residents.json")).npcs)
 for spec in JSON.parse_string(FileAccess.get_file_as_string("res://data/hangzhou_quests.json")):
  var q=preload("res://scripts/hangzhou_errand.gd").new();q.game=game;q.hub=self;q.data=spec;add_child(q);quests.append(q)
func handle_interaction(id: String) -> bool:
 if game.exploration.area_name not in ["hangzhou","cuiyue_hall"]:return false
 var topics=[];var post=false
 for q in quests:
  if q.phase not in ["available","completed"] and q.target()==id:topics.append([("완료 보고 · " if q.phase=="ready" else "진행 · ")+str(q.data.title),q.present])
 for q in quests:
  if q.GIVER==id and q.phase=="available":topics.append(["의뢰 · "+str(q.data.title),q.present])
  elif q.GIVER==id and q.phase not in ["completed","ready"] and q.target()!=id:topics.append(["진행 확인 · "+str(q.data.title),q.remind])
  if q.phase=="completed" and (q.data.participants.has(id) or q.data.get("post",{}).has(id)):post=true
 if topics.is_empty() and not post:return false
 var spec={}
 for n in people.npcs:
  if n.id==id:spec=n;break
 if spec.is_empty():return false
 if spec.has("service_id"):topics.append([{"city_merchant":"영약을 살펴본다","city_artisan":"병장기를 살펴본다","city_instructor":"무공을 전수받는다"}[spec.service_id],trade.bind(id)])
 topics.append(["일상 이야기",chatter.bind(id)])
 if topics.size()==1:chatter(id);return true
 var ui=game.adventure_ui;ui.open_shell("topics");ui.heading.text=spec.name+" · 용건";ui.primary.hide()
 for topic in topics:
  var button=ui.row(topic[0],_pick.bind(topic[1]));button.set_meta("topic",topic[0])
  button.mouse_entered.connect(topic_detail.bind(spec,topic[0]));button.focus_entered.connect(topic_detail.bind(spec,topic[0]))
 topic_detail(spec,topics[0][0]);ui.rows.get_child(0).grab_focus();return true
func refresh_world() -> void:
 var w=game.exploration;var key=str(w.load_revision)+":"+w.area_name
 for q in quests:key+=":"+q.phase+q.branch
 if key==signature:return
 signature=key;clear_world()
 if w.area_name not in ["hangzhou","cuiyue_hall"]:return
 for npc in w.ambient_nodes:
  var mark=""
  for q in quests:
   var symbol=q.marker_for(npc.get_meta("npc_id"))
   if symbol=="?":mark="?";break
   if symbol=="!":mark="!"
  if mark.is_empty():continue
  var label=UI.label(npc,mark,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_color_override("font_outline_color",Color("2b2614"));label.add_theme_constant_override("outline_size",5);owned.append(label)
func _process(_delta: float) -> void:refresh_world()

func chatter(id: String) -> void:
 var scene=[]
 for q in quests:
  if q.phase=="completed":scene.append_array(q.data.post.get(id,[]))
 if is_instance_valid(game.cuiyue_incident) and game.cuiyue_incident.phase=="completed":scene.append_array(game.cuiyue_incident.data.post.get(id,[]))
 if scene.is_empty():
  for n in people.npcs:
   if n.id==id:scene=n.dialogue;break
 if not scene.is_empty():game.say(scene)
