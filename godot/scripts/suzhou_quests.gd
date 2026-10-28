extends Node
## Shared NPC topic picker and aggregate markers; every errand keeps its own state.
const UI=preload("res://scripts/ui.gd")
var game
var quests: Array=[]
var owned: Array[Node]=[]
var signature=""
var people: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/suzhou_residents.json"))
func _ready() -> void:
 game.PORTRAITS.ACTORS.sz_extortionist={"name":"나루 갈취범","portrait":"res://assets/portraits/archetypes/bandit.png"}
 for spec in JSON.parse_string(FileAccess.get_file_as_string("res://data/suzhou_quests.json")):
  var q=preload("res://scripts/suzhou_errand.gd").new();q.game=game;q.hub=self;q.data=spec;add_child(q);quests.append(q)
 var q=preload("res://scripts/murong_quest.gd").new();q.game=game;q.hub=self;q.data=JSON.parse_string(FileAccess.get_file_as_string("res://data/murong_quest.json"));add_child(q);quests.append(q)
func reset() -> void:
 clear_world()
 for q in quests:q.reset()
 signature=""
func invalidate() -> void:signature=""
func get_quest(id: String):
 for q in quests:
  if q.ID==id:return q
 return null
func _pick(callback: Callable) -> void:game.adventure_ui.close_menu();callback.call()
func handle_interaction(id: String) -> bool:
 var mq=get_quest("suzhou_murong")
 if mq.is_target(id):mq.present();return true
 if game.exploration.area_name=="murong_estate":
  for n in JSON.parse_string(FileAccess.get_file_as_string("res://data/murong_estate_residents.json")).npcs:
   if n.id==id:game.say(n.dialogue);return true
 if game.exploration.area_name!="suzhou":return false
 if id=="sz_extortionist":
  var q=get_quest("suzhou_quay")
  if q.phase=="confront":q.present();return true
  return false
 var topics=[];var post=false
 for q in quests:
  if q.phase not in ["available","completed"] and q.target()==id:topics.append([("완료 보고 · " if q.phase=="ready" else "진행 · ")+str(q.data.title),q.present])
 for q in quests:
  if q.GIVER==id and q.phase=="available" and (q.ID!="suzhou_murong" or q.eligible()):topics.append(["의뢰 · "+str(q.data.title),q.present])
  elif q.GIVER==id and q.phase not in ["completed","ready"] and q.target()!=id:topics.append(["진행 확인 · "+str(q.data.title),q.remind])
  if q.phase=="completed" and q.data.participants.has(id):post=true
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
func topic_detail(spec: Dictionary,title: String) -> void:
 var ui=game.adventure_ui
 if not ui.window.visible or ui.mode!="topics":return
 var text=spec.name+" · "+spec.role+"\n\n"
 for q in quests:
  if title.ends_with(q.data.title):
   text+=q.data.title+"\n"+{"available":"수락 가능","active":"진행 중","ready":"완료 보고 대기","completed":"완료"}[q.status()]+" · "+q.reward_label()+"\n\n"+game.quest_navigation.definitions[q.ID].stages[q.stage()].label+"\n\n다른 의뢰를 맡고 있어도 이 용건을 함께 진행할 수 있습니다."
   ui.body.text=text;return
 if title=="일상 이야기":text+=spec.character_profile.background+"\n\n"+spec.character_profile.relations
 else:text+={"city_artisan":"검·도·창을 살펴보고 구매할 수 있습니다.\n품값은 삼백·오백·칠백문입니다.","city_instructor":"익힐 수 있는 무공과 전수 조건을 살펴봅니다.\n전수비는 한 문에 삼백오십문입니다.","city_merchant":"하급 영약은 한 알에 백문입니다."}.get(spec.get("service_id",""),"")
 ui.body.text=text
func trade(id: String) -> void:
 for s in people.services:
  if s.actor_id==id:game.pending_service_id=s.id;game.say(s.greeting_lines,game._service_done);return
func chatter(id: String) -> void:
 var scene=[]
 for q in quests:
  if q.phase=="completed":scene.append_array(q.data.post.get(id,[]))
 if scene.is_empty():
  for n in people.npcs:
   if n.id==id:scene=n.dialogue;break
 if not scene.is_empty():game.say(scene)
func in_battle() -> bool:
 for q in quests:
  if q.in_battle():return true
 return false
func after_victory() -> void:
 for q in quests:
  if q.in_battle():q.after_victory();return
func after_defeat() -> void:
 for q in quests:
  if q.in_battle():q.after_defeat();return
func encounters() -> Array:
 var values=[]
 for q in quests:
  if q.data.has("encounter"):values.append(q.data.encounter)
 return values
func clear_world() -> void:
 var w=game.exploration
 for node in owned:
  if not is_instance_valid(node):continue
  if node is CharacterBody2D:w.ambient_nodes.erase(node)
  node.free()
 owned.clear()
func refresh_world() -> void:
 var w=game.exploration;var key=str(w.load_revision)+":"+w.area_name
 for q in quests:key+=":"+q.phase+q.branch
 if key==signature:return
 signature=key;clear_world()
 if w.area_name not in ["suzhou","murong_estate"]:return
 var q=get_quest("suzhou_quay")
 if w.area_name=="suzhou" and q.phase=="confront":
  w._populate_residents([{"id":"sz_extortionist","name":"나루 갈취범","role":"행패꾼","post":"하역 마당","point":q.data.enemy_point,"frame":4,"quest_actor":true,"character_profile":{},"district":"harbor"}])
  var npc=w.ambient_nodes.back();owned.append(npc);var tag=w.occlusion_roots.pop_back();tag.reparent(npc);tag.position=Vector2.ZERO
 for npc in w.ambient_nodes:
  var mark=""
  for errand in quests:
   var symbol=errand.marker_for(npc.get_meta("npc_id"))
   if symbol=="?":mark="?";break
   if symbol=="!":mark="!"
  if mark.is_empty():continue
  var label=UI.label(npc,mark,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_color_override("font_outline_color",Color("2b2614"));label.add_theme_constant_override("outline_size",5);owned.append(label)
 if is_instance_valid(w.regional_map):
  w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _process(_delta: float) -> void:
 refresh_world()
 var q=get_quest("suzhou_quay");var w=game.exploration
 if w.area_name!="suzhou" or q.phase!="confront" or not w.active or game.state!="explore" or not game.dialogue_lines.is_empty() or game.adventure_ui.window.visible:return
 for npc in w.ambient_nodes:
  if npc.get_meta("npc_id")=="sz_extortionist" and npc.position.distance_to(w.player.position)<90:q.present();return
func snapshot() -> Dictionary:
 var result={}
 for q in quests:result[q.ID]=q.snapshot()
 return result
func valid(value) -> bool:
 if not value is Dictionary:return false
 for id in value:
  var q=get_quest(str(id))
  if not is_instance_valid(q) or not q.valid(value[id]):return false
 return true
func restore(value: Dictionary) -> void:
 clear_world()
 for q in quests:q.restore(value.get(q.ID,{}))
 signature=""
