extends Node
signal completed
signal transition_wake
const Space=preload("res://prototypes/isometric/iso_space.gd")
var outside
var doorway: Dictionary
var room
var transitioning=false
var require_release=false
var state={}
var ui_states=[]
var caption: Label
var shade: ColorRect
var layer: CanvasLayer
var transitions=0
var closing=false
var fade_tween: Tween
func setup(world) -> void:
 outside=world;process_mode=Node.PROCESS_MODE_ALWAYS
 doorway=world.data.props.filter(func(p):return p.id=="lane_house")[0].entrance
func _ready() -> void:
 layer=CanvasLayer.new();layer.layer=100;add_child(layer)
 caption=Label.new();caption.add_theme_font_override("font",load("res://assets/fonts/NanumMyeongjo-Regular.ttf"));caption.add_theme_font_size_override("font_size",18);caption.add_theme_color_override("font_color",Color("ffe0a0"));caption.add_theme_color_override("font_outline_color",Color("10221b"));caption.add_theme_constant_override("outline_size",5);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(caption)
 shade=ColorRect.new();shade.color=Color(0,0,0,0);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(shade)
func active_world():return room if is_instance_valid(room) else outside
func offer() -> bool:
 if transitioning or require_release:return false
 if is_instance_valid(outside.errand) and outside.errand.busy():return false
 var world=active_world()
 if world.dialogue.active or world.interaction.choose_target()!=null:return false
 var threshold=Vector2(4,5.8) if is_instance_valid(room) else Vector2(doorway.threshold[0],doorway.threshold[1])
 var facing=Vector2(0,-1) if is_instance_valid(room) else Vector2(doorway.facing[0],doorway.facing[1])
 var offset=world.actor.logical-threshold
 # Wider exterior approach, retaining the front-side test and all three rays.
 # The small interior keeps its existing exit range.
 var reach=.9 if is_instance_valid(room) else 1.4
 var lateral=.45 if is_instance_valid(room) else .75
 if offset.length()>reach or offset.dot(facing)<.05 or absf(offset.cross(facing))>lateral:return false
 var goal=Vector2(4,5.1) if is_instance_valid(room) else Vector2(doorway.approach[0],doorway.approach[1])
 var side=facing.orthogonal()*.10
 for delta in [Vector2.ZERO,side,-side]:
  var query=PhysicsRayQueryParameters2D.create(Space.project(world.actor.logical+delta),Space.project(goal+delta),3,[world.actor.get_rid()]);query.hit_from_inside=true
  if not world.get_world_2d().direct_space_state.intersect_ray(query).is_empty():return false
 return true
func _process(_delta: float) -> void:
 if require_release and not Input.is_action_pressed("iso_interact"):require_release=false
 caption.visible=offer()
 if caption.visible:
  var world=active_world();caption.text="F 나가기" if is_instance_valid(room) else "F 들어가기"
  var foot=world.get_canvas_transform()*world.actor.visual_position()
  caption.position=foot-Vector2(caption.get_combined_minimum_size().x/2,(155 if world.actor.occluded else 115)*world.camera.zoom.y)
func _input(event: InputEvent) -> void:
 if transitioning:
  get_viewport().set_input_as_handled();return
 if event.is_action_pressed("iso_interact") and not event.is_echo():
  if require_release:get_viewport().set_input_as_handled();return
  if offer():get_viewport().set_input_as_handled();transition()
func _wake_transition() -> void:transition_wake.emit()
func _wait_transition_step(event: Signal) -> void:
 # An owned tween alone never emits finished when its scene is freed.
 # Wake/disconnect pending waits explicitly on exit, including frame waits.
 event.connect(_wake_transition,CONNECT_ONE_SHOT)
 await transition_wake
 if event.is_connected(_wake_transition):event.disconnect(_wake_transition)
func fade(alpha: float) -> void:
 fade_tween=create_tween();fade_tween.tween_property(shade,"color:a",alpha,.16)
 await _wait_transition_step(fade_tween.finished)
func transition() -> void:
 if transitioning:return
 transitioning=true;require_release=true;caption.hide();var entering=not is_instance_valid(room);var world=active_world()
 world.drag=false;world.actor.motion_paused=true;world.actor.stop_motion()
 # Freeze all exterior progress for the full transition, not just the black frame.
 if entering:
  state={"zoom":outside.camera.zoom,"follow":outside.follow,"camera":outside.camera.position,"process":outside.process_mode,"patrols":outside.patrols_enabled}
  outside.process_mode=Node.PROCESS_MODE_DISABLED
 else:room.process_mode=Node.PROCESS_MODE_DISABLED
 await fade(1)
 if closing:return
 if entering:
  ui_states.clear()
  for child in outside.get_children():
   if child is CanvasLayer:ui_states.append([child,child.visible]);child.hide()
  outside.hide();outside.camera.enabled=false
  await _wait_transition_step(get_tree().physics_frame)
  if closing:return
  room=load(doorway.interior).instantiate();get_tree().root.add_child(room)
  room.selection_message="소박한 민가 · 문 앞에서 F 나가기"
  room.actor.motion_paused=true;room.actor.input_neutral_required=true;room.actor.set_pose("back",false)
 else:
  room.queue_free();room=null;await _wait_transition_step(get_tree().process_frame)
  if closing:return
  outside.show()
  for entry in ui_states:entry[0].visible=entry[1]
  outside.patrols_enabled=state.patrols
  outside.actor.set_logical(Vector2(doorway.approach[0],doorway.approach[1]));outside.actor.set_pose("front",false)
  outside.camera.enabled=true;outside.camera.make_current();outside.camera.zoom=state.zoom;outside.follow=state.follow
  outside.camera.position=state.camera;outside.camera.reset_physics_interpolation();outside.camera.force_update_scroll()
  outside.reset_physics_interpolation()
  outside.actor.input_neutral_required=true;outside.interaction.require_release=true
 await fade(0)
 if closing:return
 if not entering:outside.process_mode=state.process
 world=active_world();world.actor.motion_paused=false;world.actor.input_neutral_required=true
 transitions+=1;transitioning=false
 completed.emit()
func _exit_tree() -> void:
 closing=true
 if is_instance_valid(fade_tween):fade_tween.kill()
 transition_wake.emit()
 if is_instance_valid(room):room.queue_free()
