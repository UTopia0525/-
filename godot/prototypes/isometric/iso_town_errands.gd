extends "res://prototypes/isometric/iso_errand.gd"
## Two fixed trial quests; reuse the existing journal, dialogue host and navigation.
const QUESTS=preload("res://prototypes/isometric/iso_town_dialogue.gd")
const Progress=preload("res://scripts/player_progress.gd")
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/town-quests.json"))
var phases={}
var completions={}
var selected_quest=""
var marker_nodes={}
var quest_buttons={}
var shop
var money=300
var progress=Progress.new()
var shop_prior_pause=false
var shop_session_open=false
func initialize_quests() -> bool:
 # Validate IDs before writing anything; content/UI expansion is a separate task.
 var valid_id=RegEx.create_from_string("\\A[A-Za-z][A-Za-z0-9_]*\\z")
 for id in definitions:
  if not id is String or valid_id.search(id)==null:return false
 # Fill only missing entries. This is not a runtime definition migration/reset.
 for id in definitions:
  if not phases.has(id):phases[id]="available"
  if not completions.has(id):completions[id]=0
 if selected_quest=="" and not definitions.is_empty():selected_quest=definitions.keys()[0]
 return true
func _ready() -> void:
 if not initialize_quests():
  push_error("Town quest IDs must match [A-Za-z][A-Za-z0-9_]*.")
  set_process(false);set_process_input(false);return
 super._ready()
 for id in definitions:
  navigation.definitions[id]={"title":definitions[id].title,"stages":{"inspect":{"goals":[]},"report":{"goals":[]},"completed":{"goals":[]}}}
 marker_nodes.iso_errand={"label":marker,"plate":marker_plate}
 var second=marker.duplicate();layer.add_child(second);var plate=marker_plate.duplicate();layer.add_child(plate);layer.move_child(plate,0)
 marker_nodes.iso_cargo={"label":second,"plate":plate}
 body.position.y=160;body.size.y=215
 var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=journal
 var index=0
 for id in definitions:
  var button=painter.button("",Rect2(35+index*380,82,365,56));button.pressed.connect(select_quest.bind(id));quest_buttons[id]=button;index+=1
 painter.free()
 shop=preload("res://prototypes/isometric/iso_town_shop.gd").new();shop.owner_trial=self;layer.add_child(shop);shop.closed.connect(_shop_closed)
func install_dialogue(host) -> void:
 var old=host.dialogue;var parent=old.get_parent();parent.remove_child(old);old.queue_free()
 host.dialogue=QUESTS.new();host.dialogue.errand=self;host.dialogue.setup(host);parent.add_child(host.dialogue)
func quest_for(npc) -> String:
 for id in definitions:
  if definitions[id].giver==str(npc.name):return id
 return ""
func giver(id: String):
 for npc in world.npcs:
  if str(npc.name)==definitions[id].giver:return npc
 return null
func blocked() -> bool:
 return passage.transitioning or input_lock or (is_instance_valid(journal) and journal.visible) or (is_instance_valid(shop) and shop.visible)
func busy() -> bool:
 return input_lock or (is_instance_valid(journal) and journal.visible) or (is_instance_valid(shop) and shop.visible)
func lines_for(id: String,kind="") -> Array:
 var q: Dictionary=definitions[id];var state: String=phases[id] if kind=="" else kind;var result=[];var index=0
 for line in q.lines[state]:
  result.append(["hero" if state=="inspect" or (index%2==1 and state in ["available","ready"]) else q.actor,line]);index+=1
 return result
func resolve_for(id: String,action: String) -> void:
 input_lock=true
 if action=="trade":open_shop();return
 if not definitions.has(id):return
 if action=="accept" and phases[id]=="available":
  phases[id]="active"
  if navigation.quest_id=="":navigation.track(id,"inspect")
 elif action=="inspect" and phases[id]=="active":
  phases[id]="ready"
  if navigation.quest_id==id:navigation.track(id,"report")
 elif action=="report" and phases[id]=="ready":
  phases[id]="completed";completions[id]+=1
  if navigation.quest_id==id:navigation.clear()
 refresh_objective()
func target_label_for(id: String) -> String:
 if phases[id]=="ready":return giver(id).display_name+"에게 보고하세요"
 if id=="iso_errand":return "민가 탁자의 대패를 확인하세요" if is_instance_valid(passage.room) else "담장 없는 민가로 들어가세요"
 return "창고 앞 봉인 항아리를 확인하세요" if not is_instance_valid(passage.room) else "민가를 나와 창고로 가세요"
func refresh_objective() -> void:
 var id: String=navigation.quest_id
 objective.text="" if id=="" else definitions[id].title+"\n"+target_label_for(id)+"\nQ 의뢰 일지"
func _transitioned() -> void:
 super._transitioned();refresh_objective()
func inspect_id() -> String:
 if blocked() or passage.require_release:return ""
 var host=active_world()
 if host.dialogue.active or host.interaction.choose_target()!=null or passage.offer():return ""
 for id in definitions:
  var q: Dictionary=definitions[id]
  if phases[id]!="active" or (q.place=="room")!=is_instance_valid(passage.room):continue
  var target_id: String=str(q.get("target_id",""))
  if target_id.is_empty() or not is_instance_valid(host.actors.get_node_or_null(NodePath(target_id))):continue
  var point=Vector2(q.point[0],q.point[1]);var approach=Vector2(q.approach[0],q.approach[1])
  if host.actor.logical.distance_to(point)>1.25 or (host.actor.logical-approach).dot(approach-point)<-.05:continue
  var clear=true;var side=(approach-point).orthogonal().normalized()*.1
  for offset in [Vector2.ZERO,side,-side]:
   var query=PhysicsRayQueryParameters2D.create(Space.project(host.actor.logical+offset),Space.project(approach+offset),3,[host.actor.get_rid()]);query.hit_from_inside=true
   if not host.get_world_2d().direct_space_state.intersect_ray(query).is_empty():clear=false;break
  if clear:return id
 return ""
func _process(_delta: float) -> void:
 if input_lock and not Input.is_action_pressed("iso_interact"):input_lock=false
 var host=active_world();var hidden=blocked() or host.dialogue.active
 for id in definitions:
  var pair: Dictionary=marker_nodes[id];var label: Label=pair.label;var plate: Panel=pair.plate
  label.visible=not hidden and not is_instance_valid(passage.room) and phases[id] in ["available","ready"];plate.visible=label.visible
  if label.visible:
   label.text="!" if phases[id]=="available" else "?"
   var foot=world.get_canvas_transform()*giver(id).visual_position();label.position=foot-Vector2(label.get_combined_minimum_size().x/2,112*world.camera.zoom.y+50);plate.position=Vector2(foot.x-20,label.position.y-1)
 objective.visible=not hidden and navigation.quest_id!=""
 var id=inspect_id() if not hidden else "";inspect_hint.visible=id!=""
 if inspect_hint.visible:
  inspect_hint.text="F "+definitions[id].label
  var foot=host.get_canvas_transform()*host.actor.visual_position();inspect_hint.position=foot-Vector2(inspect_hint.get_combined_minimum_size().x/2,120*host.camera.zoom.y)
func _input(event: InputEvent) -> void:
 if journal.visible:
  if event is InputEventKey:
   if event.pressed and not event.echo and event.keycode in [KEY_Q,KEY_ESCAPE]:close_journal()
   get_viewport().set_input_as_handled()
  return
 if is_instance_valid(shop) and shop.visible:
  if event is InputEventKey:get_viewport().set_input_as_handled()
  return
 if passage.transitioning or active_world().dialogue.active:return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_Q:
  open_journal();get_viewport().set_input_as_handled();return
 if event.is_action_pressed("iso_interact") and not event.is_echo():
  if input_lock:get_viewport().set_input_as_handled();return
  var id=inspect_id()
  if id!="":active_world().dialogue.inspect_quest(id);input_lock=true;get_viewport().set_input_as_handled()
  elif active_world().interaction.choose_target()==null and not passage.offer():
   active_world().selection_message="대화하거나 조사할 대상 가까이 다가가세요.";get_viewport().set_input_as_handled()
func select_quest(id: String) -> void:selected_quest=id;refresh_journal()
func refresh_journal() -> void:
 var states={"available":"수락 가능","active":"진행 중","ready":"보고 가능","completed":"완료"}
 for id in definitions:quest_buttons[id].text=definitions[id].title+" · "+states[phases[id]];quest_buttons[id].disabled=id==selected_quest
 body.text=definitions[selected_quest].title+"\n상태: "+states[phases[selected_quest]]+"\n\n"+(target_label_for(selected_quest) if phases[selected_quest] in ["active","ready"] else "짐꾼에게 말을 걸어 부탁을 들어 보세요." if phases[selected_quest]=="available" else "확인을 마치고 보고했습니다.")+"\n\n보수 없음 · 물건은 가져오지 않습니다."
 track_button.disabled=phases[selected_quest] not in ["active","ready"];track_button.text="추적 해제" if navigation.quest_id==selected_quest else "이 의뢰 추적"
func toggle_track() -> void:
 if phases[selected_quest] not in ["active","ready"]:return
 if navigation.quest_id==selected_quest:navigation.clear()
 else:navigation.track(selected_quest,"inspect" if phases[selected_quest]=="active" else "report")
 refresh_objective();refresh_journal()
func open_shop() -> void:
 if shop_session_open or shop.visible or journal.visible or passage.transitioning or active_world().dialogue.active:return
 shop_session_open=true
 shop_prior_pause=get_tree().paused;get_tree().paused=true;world.drag=false;shop.open_counter({})
func _shop_closed() -> void:
 if not shop_session_open:return
 shop_session_open=false
 get_tree().paused=shop_prior_pause;active_world().actor.input_neutral_required=true;active_world().interaction.require_release=true;input_lock=true
func _exit_tree() -> void:
 if shop_session_open and get_tree()!=null:get_tree().paused=shop_prior_pause
 if is_instance_valid(journal) and journal.visible and get_tree()!=null:get_tree().paused=prior_pause
