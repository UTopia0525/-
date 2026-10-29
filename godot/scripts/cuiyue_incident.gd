extends Node
## One automatic story event. Progress is committed after dialogue, favor only at the end.
const ID="cuiyue_incident"
const GIVER="cy_manager"
var game
var phase="dormant"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/cuiyue_incident.json"))
var owned: Array[Node]=[]
var hidden: Array[Node2D]=[]
var signature=""
func _ready() -> void:
 for n in data.characters:game.PORTRAITS.ACTORS[n.id]={"name":n.name,"portrait":n.portrait}
 var stages={}
 for pair in [["confront","막무가내인 무인을 저지하기"],["fight","탁문호를 제압하기"],["settle","취월루주의 수습 지켜보기"],["gratitude","누주의 감사 인사 듣기"],["end","취월루 사건 마무리"]]:stages[pair[0]]={"label":pair[1],"goals":[]}
 game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func eligible() -> bool:
 if game.nanjing_relief_quest.phase!="completed":return false
 for id in data.prerequisites:
  var q=game.hangzhou_quests.get_quest(id)
  if not is_instance_valid(q) or q.phase!="completed":return false
 return true
func safe_to_start() -> bool:
 return game.exploration.area_name=="cuiyue_hall" and game.exploration.active and game.state=="explore" and game.dialogue_lines.is_empty() and not get_tree().paused and not game.adventure_ui.window.visible and not game.player_menu.visible and not game.settings_menu.window.visible and not game.city_service.visible and not game.city_overview.visible and not game.dialogue_history.visible
func status() -> String:return "dormant" if phase=="dormant" else "completed" if phase=="completed" else "active"
func stage() -> String:return {"battle":"fight","aftermath":"settle","private":"gratitude","completed":"end"}.get(phase,"confront")
func marker_for(_id: String) -> String:return ""
func is_target(_id: String) -> bool:return false
func reward_label() -> String:return "하오문 호의도+20" if phase=="completed" else "사건을 정리한 뒤 감사 인사"
func goal(world) -> Dictionary:
 if phase in ["dormant","completed"] or world.area_name!="cuiyue_hall":return {}
 return {"position":world.city_point([1035,585]),"label":game.quest_navigation.definitions[ID].stages[stage()].label,"quest_title":data.title,"goal_id":ID,"quest_id":ID,"stage_id":stage()}
func track() -> void:
 game.quest_navigation.update_quest(ID,stage())
 var w=game.exploration
 game.location.text=w.city_data.name+" · "+w.district_at_player()
 game.chapter_goal.hide();game.quest_heading.position.y=9;game.objective.position.y=38
 game.quest_heading.text=data.title;game.objective.text=game.quest_navigation.definitions[ID].stages[stage()].label
 game.objective_meta.text="취월루 · 진행 중인 사건";game.objective.tooltip_text=game.objective.text
func begin() -> void:
 if phase!="dormant" or not eligible() or not safe_to_start():return
 phase="confront";game.state="story";refresh_world()
 var w=game.exploration;w.player.position=w.safe_player_position(w.city_point([900,600]));w.player.stop();w.player.facing="right";w.camera.snap_to_player();track()
 game.say(data.scenes.confront,_fight)
func _fight() -> void:
 if phase!="confront":return
 phase="battle";track();game.start_battle(data.encounter)
func in_battle() -> bool:return phase=="battle"
func after_victory() -> void:
 _after_battle(data.scenes.defeated)
func after_defeat() -> void:
 _after_battle(data.scenes.player_defeated)
func _after_battle(lines: Array) -> void:
 if phase!="battle":return
 phase="aftermath";game.battle.cancel();game.battle.hide();game.state="story"
 var w=game.exploration;w.show();w.camera.enabled=true;w.camera.snap_to_player();game.top_hud.show();game.bottom_hint.hide()
 refresh_world();track();w.camera.position=Vector2(-100,-300);w.camera.snap_to_player();game.music.play_track("dock");game.say(lines,_warn)
func _warn() -> void:
 if phase!="aftermath":return
 refresh_world();game.say(data.scenes.warning,_private)
func _private() -> void:
 if phase!="aftermath":return
 phase="private";refresh_world();track()
 game.exploration.camera.position=Vector2(0,-game.exploration.camera.focus_height)
 game.exploration.camera.snap_to_player();game.say(data.scenes.private,_complete)
func _complete() -> void:
 if phase!="private":return
 phase="completed";game.progress.add_favor("haomun",20)
 if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
 refresh_world();game.state="explore";game.exploration.set_active(true)
 game.adventure_ui.notify("취월루 사건 완료 · 하오문 호의도+20","quest")
func handle_interaction(id: String) -> bool:
 if phase=="completed" and game.exploration.area_name=="cuiyue_hall" and id=="cy_eunsowol":game.say(data.post[id]);return true
 return false
func clear_world() -> void:
 var w=game.exploration
 for node in owned:
  if not is_instance_valid(node):continue
  w.ambient_nodes.erase(node);node.free()
 owned.clear()
 for n in hidden:
  if is_instance_valid(n):n.show()
 hidden.clear()
func _spawn(id: String):
 var w=game.exploration
 for spec in data.characters:
  if spec.id!=id:continue
  w._populate_residents([spec.duplicate(true)])
  var body=w.ambient_nodes.back();owned.append(body)
  var tag=w.occlusion_roots.pop_back();tag.reparent(body);tag.position=Vector2.ZERO
  return body
 return null
func refresh_world() -> void:
 var w=game.exploration;var key=str(w.load_revision)+":"+phase
 if key==signature:return
 signature=key;clear_world()
 if w.area_name!="cuiyue_hall":return
 if phase in ["confront","battle","aftermath"]:_spawn("cy_tak")
 if phase in ["aftermath","private","completed"]:
  var leader=_spawn("cy_eunsowol")
  if phase=="aftermath":
   # Performance dais is normally solid. This visual-only scene pose has no F access.
   leader.position=w.city_point([768,465]);leader.collision_layer=0;leader.z_index=1
 if phase in ["confront","battle","aftermath"]:
  for n in w.ambient_nodes:
   if n.name=="cy_waiter":n.hide();hidden.append(n)
 if phase=="private":
  for n in w.ambient_nodes:
   if n.name!="cy_eunsowol":n.hide();hidden.append(n)
 if is_instance_valid(w.regional_map):
  w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _process(_delta: float) -> void:
 refresh_world()
 if phase=="dormant" and eligible() and safe_to_start():begin()
func reset() -> void:
 if phase!="dormant":game.exploration.camera.position=Vector2(0,-game.exploration.camera.focus_height)
 phase="dormant";signature="";clear_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(v) -> bool:return v is Dictionary and v.get("phase") in ["dormant","battle","completed"]
func restore(v: Dictionary) -> void:phase=v.get("phase","dormant");signature=""
