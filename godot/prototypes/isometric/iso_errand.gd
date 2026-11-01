extends Node
const Space=preload("res://prototypes/isometric/iso_space.gd")
const Dialogue=preload("res://prototypes/isometric/iso_errand_dialogue.gd")
var world
var passage
var phase="available"
var navigation
var tracked=false
var completion_count=0
var layer: CanvasLayer
var marker: Label
var marker_plate: Panel
var objective: Label
var inspect_hint: Label
var journal: Panel
var dim: ColorRect
var body: Label
var track_button: Button
var prior_pause=false
var input_lock=false
func setup(host,door) -> void:world=host;passage=door;process_mode=Node.PROCESS_MODE_ALWAYS
func _ready() -> void:
 navigation=preload("res://prototypes/isometric/iso_errand_tracking.gd").new();add_child(navigation)
 install_dialogue(world);passage.completed.connect(_transitioned)
 layer=CanvasLayer.new();layer.layer=60;add_child(layer)
 var font=load("res://assets/fonts/NanumMyeongjo-Regular.ttf")
 for kind in range(3):
  var label=Label.new();label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",34 if kind==0 else 17);label.add_theme_color_override("font_color",Color("ffe14b") if kind==0 else Color("ffe4ad"));label.add_theme_color_override("font_outline_color",Color("10221b"));label.add_theme_constant_override("outline_size",4);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
  if kind==0:marker=label
  elif kind==1:objective=label;objective.position=Vector2(815,25)
  else:inspect_hint=label
 marker_plate=Panel.new();marker_plate.size=Vector2(40,48);marker_plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var badge=StyleBoxFlat.new();badge.bg_color=Color("142923eb");badge.border_color=Color("c9ac6b");badge.set_border_width_all(1);badge.set_corner_radius_all(8);marker_plate.add_theme_stylebox_override("panel",badge);layer.add_child(marker_plate);layer.move_child(marker_plate,0)
 dim=ColorRect.new();dim.color=Color(0,0,0,.65);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(dim);dim.hide()
 journal=preload("res://scripts/paper_dialogue_panel.gd").new();journal.position=Vector2(230,110);journal.size=Vector2(820,480);layer.add_child(journal);journal.hide()
 var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=journal
 painter.text(journal,"의뢰 일지 · Q",Rect2(32,25,750,45),30,painter.INK,true)
 body=painter.text(journal,"",Rect2(35,90,750,260),21,painter.INK);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 track_button=painter.button("이 의뢰 추적",Rect2(35,390,300,48),true);track_button.pressed.connect(toggle_track)
 painter.button("닫기 · Q / ESC",Rect2(470,390,310,48)).pressed.connect(close_journal);painter.free()
func install_dialogue(host) -> void:
 var old=host.dialogue;var parent=old.get_parent();parent.remove_child(old);old.queue_free()
 host.dialogue=Dialogue.new();host.dialogue.errand=self;host.dialogue.setup(host);parent.add_child(host.dialogue)
func _transitioned() -> void:
 if is_instance_valid(passage.room):install_dialogue(passage.room)
func active_world():return passage.active_world()
func busy() -> bool:return is_instance_valid(journal) and journal.visible
func lines() -> Array:
 match phase:
  "active":return [["iso_gate_porter","짐이 아직 끝나질 않았소. 아랫골목 민가의 탁자 위를 살펴봐 주시오."],["hero","대패는 그 자리에 두고, 있는지만 확인하면 되는 것이지?"],["iso_gate_porter","그렇소. 빌린 연장이라 혹시 잃었을까 마음이 쓰여서 말이오."]]
  "ready":return [["iso_gate_porter","민가에는 다녀왔소? 연장은 무사하던가?"],["hero","탁자 위에 그대로 있소. 날도 온전해 보였고, 손대지 않고 돌아왔소."],["iso_gate_porter","이제야 마음이 놓이는구려. 품삯도 못 드리는 부탁인데 발품을 팔아 주었소. 고맙소."]]
  "completed":return [["iso_gate_porter","이 짐만 내려놓으면 대패부터 돌려줘야겠소. 남의 물건은 잊지 말아야지."],["hero","다음에는 연장도 짐처럼 챙기시오."],["iso_gate_porter","허허, 그 말이 옳소. 덕분에 오늘은 허리보다 마음이 먼저 펴졌구려."]]
 return [["iso_gate_porter","잠깐 괜찮겠소? 아랫골목 담장 없는 민가에 대패를 놓고 나온 듯하오."],["hero","돌아가서 살펴보면 되지 않겠소?"],["iso_gate_porter","이 짐이 끝나려면 한참이오. 빌린 연장이라 마음이 쓰이는데, 탁자 위에 있는지만 확인해 주시겠소?"]]
func resolve(action: String) -> void:
 if action=="accept" and phase=="available":phase="active";tracked=true
 elif action=="inspect" and phase=="active":phase="ready"
 elif action=="report" and phase=="ready":phase="completed";tracked=false;completion_count+=1
 input_lock=true;sync_tracking()
func sync_tracking() -> void:
 if tracked:navigation.track("iso_errand","inspect" if phase=="active" else "report")
 else:navigation.clear()
func target_label() -> String:
 if phase=="active":return "민가 탁자 위 대패를 확인하세요" if is_instance_valid(passage.room) else "담장 없는 민가로 들어가세요"
 if phase=="ready":return "민가를 나가 문길 짐꾼에게 보고하세요" if is_instance_valid(passage.room) else "문길 짐꾼에게 확인 결과를 전하세요"
 return ""
func inspect_offer() -> bool:
 if phase!="active" or not is_instance_valid(passage.room) or passage.transitioning or passage.require_release or busy() or input_lock:return false
 var room=passage.room
 if room.dialogue.active or passage.offer():return false
 if room.actor.logical.distance_to(Vector2(2.7,2))>1.25:return false
 var side=Vector2(.1,0)
 for offset in [Vector2.ZERO,side,-side]:
  var query=PhysicsRayQueryParameters2D.create(Space.project(room.actor.logical+offset),Space.project(Vector2(2.7,2.55)+offset),3,[room.actor.get_rid()]);query.hit_from_inside=true
  if not room.get_world_2d().direct_space_state.intersect_ray(query).is_empty():return false
 return true
func _process(_delta: float) -> void:
 if input_lock and not Input.is_action_pressed("iso_interact"):input_lock=false
 var host=active_world();var hide=passage.transitioning or busy() or host.dialogue.active
 marker.visible=not hide and not is_instance_valid(passage.room) and phase in ["available","ready"]
 if marker.visible:
  marker.text="!" if phase=="available" else "?"
  var foot=world.get_canvas_transform()*world.npcs[0].visual_position();marker.position=foot-Vector2(marker.get_combined_minimum_size().x/2,112*world.camera.zoom.y+50)
  marker_plate.position=Vector2(foot.x-20,marker.position.y-1)
 marker_plate.visible=marker.visible
 objective.visible=navigation.quest_id=="iso_errand" and not hide
 if objective.visible:objective.text="민가에 두고 온 연장\n"+target_label()+"\nQ 의뢰 일지"
 inspect_hint.visible=not hide and inspect_offer()
 if inspect_hint.visible:
  var foot=host.get_canvas_transform()*host.actor.visual_position();inspect_hint.text="F 탁자 위 대패 확인";inspect_hint.position=foot-Vector2(95,120*host.camera.zoom.y)
func _input(event: InputEvent) -> void:
 if busy():
  if event is InputEventKey:
   if event.pressed and not event.echo and event.keycode in [KEY_Q,KEY_ESCAPE]:close_journal()
   get_viewport().set_input_as_handled()
  return
 if passage.transitioning or active_world().dialogue.active:return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_Q:
  open_journal();get_viewport().set_input_as_handled();return
 if event.is_action_pressed("iso_interact") and not event.is_echo() and inspect_offer():
  active_world().dialogue.inspect();input_lock=true;get_viewport().set_input_as_handled()
func open_journal() -> void:
 if busy():return
 active_world().drag=false
 prior_pause=get_tree().paused;get_tree().paused=true;dim.show();journal.show();refresh_journal()
func refresh_journal() -> void:
 body.text="민가에 두고 온 연장\n상태: "+{"available":"수락 가능","active":"진행 중","ready":"보고 가능","completed":"완료"}[phase]+"\n\n"+({"available":"문길 짐꾼에게 말을 걸어 부탁을 들어 보세요.","completed":"탁자 위 대패를 확인하고 문길 짐꾼에게 무사하다고 전했습니다."}.get(phase,target_label()))+"\n\n보수 없음 · 물건은 가져오지 않습니다."
 track_button.disabled=phase not in ["active","ready"];track_button.text="추적 해제" if tracked else "이 의뢰 추적"
func toggle_track() -> void:
 tracked=not tracked;sync_tracking();refresh_journal()
func close_journal() -> void:
 if not is_instance_valid(journal) or not journal.visible:return
 journal.hide();dim.hide();get_tree().paused=prior_pause;active_world().actor.input_neutral_required=true
func _exit_tree() -> void:
 if busy() and get_tree()!=null:get_tree().paused=prior_pause
