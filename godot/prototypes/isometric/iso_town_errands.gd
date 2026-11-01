extends "res://prototypes/isometric/iso_errand.gd"
## Trial-local quest views; reuse the existing dialogue host and navigation.
const QUESTS=preload("res://prototypes/isometric/iso_town_dialogue.gd")
const Progress=preload("res://scripts/player_progress.gd")
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/town-quests.json"))
var phases={}
var completions={}
var selected_quest=""
var marker_nodes={}
var quest_buttons={}
var quest_scroll: ScrollContainer
var quest_list: VBoxContainer
var detail_scroll: ScrollContainer
var tracked_caption: Label
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
 navigation.definitions.clear()
 marker.hide();marker_plate.hide()
 for id in definitions:
  navigation.definitions[id]={"title":definitions[id].title,"stages":{"inspect":{"goals":[]},"report":{"goals":[]},"completed":{"goals":[]}}}
  var label=marker.duplicate();layer.add_child(label)
  var plate=marker_plate.duplicate();layer.add_child(plate);layer.move_child(plate,0)
  marker_nodes[id]={"label":label,"plate":plate}
 build_journal()
 shop=preload("res://prototypes/isometric/iso_town_shop.gd").new();shop.owner_trial=self;layer.add_child(shop);shop.closed.connect(_shop_closed)
func build_journal() -> void:
 var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=journal
 painter.text(journal,"의뢰 목록 · ↑↓ 선택",Rect2(35,70,285,25),17,painter.MUTED)
 tracked_caption=painter.text(journal,"",Rect2(335,70,450,25),17,painter.MUTED)
 quest_scroll=ScrollContainer.new();quest_scroll.position=Vector2(35,100);quest_scroll.size=Vector2(285,270)
 quest_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;quest_scroll.follow_focus=true;journal.add_child(quest_scroll)
 quest_list=VBoxContainer.new();quest_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;quest_list.add_theme_constant_override("separation",6);quest_scroll.add_child(quest_list)
 painter.content=quest_list
 for id in definitions:
  var button=painter.button("",Rect2(0,0,260,66));button.custom_minimum_size=Vector2(0,66);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.focus_mode=Control.FOCUS_NONE;button.pressed.connect(select_quest.bind(id));quest_buttons[id]=button
 detail_scroll=ScrollContainer.new();detail_scroll.position=Vector2(335,105);detail_scroll.size=Vector2(450,265)
 detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;journal.add_child(detail_scroll)
 body.reparent(detail_scroll);body.position=Vector2.ZERO;body.size=Vector2(430,265);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_font_size_override("font_size",20)
 body.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
 track_button.position=Vector2(335,390);track_button.size=Vector2(260,48);track_button.focus_mode=Control.FOCUS_NONE
 for child in journal.get_children():
  if child is Button and child!=track_button:child.position=Vector2(620,390);child.size=Vector2(165,48);child.focus_mode=Control.FOCUS_NONE
 painter.free()
func has_quest(id: String) -> bool:
 return definitions.has(id) and phases.has(id) and completions.has(id)
func can_track(id: String) -> bool:
 return has_quest(id) and phases[id] in ["active","ready"]
func install_dialogue(host) -> void:
 var old=host.dialogue;var parent=old.get_parent();parent.remove_child(old);old.queue_free()
 host.dialogue=QUESTS.new();host.dialogue.errand=self;host.dialogue.setup(host);parent.add_child(host.dialogue)
func quest_for(npc) -> String:
 for id in definitions:
  if definitions[id].giver==str(npc.name):return id
 return ""
func giver(id: String):
 if not has_quest(id):return null
 for npc in world.npcs:
  if str(npc.name)==definitions[id].giver:return npc
 return null
func blocked() -> bool:
 return passage.transitioning or input_lock or (is_instance_valid(journal) and journal.visible) or (is_instance_valid(shop) and shop.visible)
func busy() -> bool:
 return input_lock or (is_instance_valid(journal) and journal.visible) or (is_instance_valid(shop) and shop.visible)
func lines_for(id: String,kind="") -> Array:
 if not has_quest(id):return []
 var q: Dictionary=definitions[id];var state: String=phases[id] if kind=="" else kind;var result=[];var index=0
 if not q.lines.has(state):return []
 for line in q.lines[state]:
  result.append(["hero" if state=="inspect" or (index%2==1 and state in ["available","ready"]) else q.actor,line]);index+=1
 return result
func resolve_for(id: String,action: String) -> void:
 input_lock=true
 if action=="trade":open_shop();return
 if not has_quest(id):return
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
 if not has_quest(id):return ""
 if phases[id]=="ready":
  var npc=giver(id)
  return npc.display_name+"에게 보고하세요" if is_instance_valid(npc) else "의뢰인 정보가 없습니다."
 var place="room" if is_instance_valid(passage.room) else "outside"
 return str(definitions[id].get("objectives",{}).get(place,"목표 안내가 없습니다."))
func refresh_objective() -> void:
 var id: String=navigation.quest_id
 objective.text="" if not can_track(id) else definitions[id].title+"\n"+target_label_for(id)+"\nQ 의뢰 일지"
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
  var npc=giver(id)
  label.visible=not hidden and not is_instance_valid(passage.room) and is_instance_valid(npc) and phases[id] in ["available","ready"];plate.visible=label.visible
  if label.visible:
   label.text="!" if phases[id]=="available" else "?"
   var foot=world.get_canvas_transform()*npc.visual_position();label.position=foot-Vector2(label.get_combined_minimum_size().x/2,112*world.camera.zoom.y+50);plate.position=Vector2(foot.x-20,label.position.y-1)
 objective.visible=not hidden and can_track(navigation.quest_id)
 var id=inspect_id() if not hidden else "";inspect_hint.visible=id!=""
 if inspect_hint.visible:
  inspect_hint.text="F "+definitions[id].label
  var foot=host.get_canvas_transform()*host.actor.visual_position();inspect_hint.position=foot-Vector2(inspect_hint.get_combined_minimum_size().x/2,120*host.camera.zoom.y)
func _input(event: InputEvent) -> void:
 if journal.visible:
  if event is InputEventKey:
   if event.pressed and not event.echo and event.keycode in [KEY_Q,KEY_ESCAPE]:close_journal()
   elif event.pressed and event.keycode in [KEY_UP,KEY_DOWN,KEY_PAGEUP,KEY_PAGEDOWN,KEY_HOME,KEY_END]:move_selection(event.keycode)
   elif event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:toggle_track()
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
func open_journal() -> void:
 super.open_journal()
 if journal.visible:get_viewport().gui_release_focus()
func select_quest(id: String) -> void:
 if not has_quest(id) or not quest_buttons.has(id):return
 selected_quest=id;detail_scroll.scroll_vertical=0;refresh_journal()
 if journal.visible:quest_scroll.ensure_control_visible(quest_buttons[id])
func move_selection(code: int) -> void:
 var ids=definitions.keys()
 if ids.is_empty():return
 var index=ids.find(selected_quest)
 if code==KEY_HOME:index=0
 elif code==KEY_END:index=ids.size()-1
 else:index=clampi(maxi(index,0)+{KEY_UP:-1,KEY_DOWN:1,KEY_PAGEUP:-4,KEY_PAGEDOWN:4}[code],0,ids.size()-1)
 select_quest(ids[index])
func refresh_journal() -> void:
 var states={"available":"수락 가능","active":"진행 중","ready":"보고 가능","completed":"완료"}
 for id in definitions:
  quest_buttons[id].text=definitions[id].title+" · "+states[phases[id]]
  preload("res://scripts/ui.gd").selection(quest_buttons[id],id==selected_quest,true)
 # Tracking is independent of the selected detail row.
 tracked_caption.text="추적 중: "+definitions[navigation.quest_id].title if can_track(navigation.quest_id) else "추적 중인 의뢰 없음"
 tracked_caption.tooltip_text=tracked_caption.text
 if not has_quest(selected_quest):
  body.text="표시할 의뢰가 없습니다." if definitions.is_empty() else "의뢰를 선택하세요."
  track_button.disabled=true;track_button.text="이 의뢰 추적";return
 body.text=definitions[selected_quest].title+"\n상태: "+states[phases[selected_quest]]+"\n\n"+(target_label_for(selected_quest) if phases[selected_quest] in ["active","ready"] else "짐꾼에게 말을 걸어 부탁을 들어 보세요." if phases[selected_quest]=="available" else "확인을 마치고 보고했습니다.")+"\n\n보수 없음 · 물건은 가져오지 않습니다."
 track_button.disabled=not can_track(selected_quest);track_button.text="추적 해제 · Enter" if navigation.quest_id==selected_quest else "이 의뢰 추적 · Enter"
func toggle_track() -> void:
 if not can_track(selected_quest):return
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
