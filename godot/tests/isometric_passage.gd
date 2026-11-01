extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var world
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("ISO_PASSAGE: "+message)
func frames(n: int) -> void:
 for i in range(n):await physics_frame
func key(code: int,down: bool,echo=false) -> void:
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;e.echo=echo
 Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func snapshot() -> Array:
 return world.npcs.map(func(n):return [n.get_instance_id(),n.logical,n.phase,n.patrol.index,n.patrol.step,n.patrol.pause,n.patrol.blocked,n.patrol.detour])
func run() -> void:
 create_timer(90).timeout.connect(func():push_error("PASSAGE watchdog");quit(2))
 world=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(world);await frames(3)
 var p=world.passage;world.patrols_enabled=false
 for i in range(2):world.npcs[i].set_logical(Vector2(19,14+i*.6))
 for point in [Vector2(13.5,11.56),Vector2(14.6,12.5),Vector2(14.6,10.5)]:
  world.actor.set_logical(point);check(not p.offer(),"no entry through wall/back/side")
 world.actor.set_logical(Vector2(14.605814,11.562791));await frames(2);check(p.offer(),"front approach offers entry")
 world.npcs[0].set_logical(Vector2(14.9,11.9));await frames(2)
 check(world.interaction.choose_target()==world.npcs[0] and not p.offer(),"NPC priority produces only one F target")
 await key(KEY_F,true);await key(KEY_F,false);check(world.dialogue.active,"F still opens shared NPC dialogue")
 for i in range(5):await key(KEY_F,true);await key(KEY_F,false)
 check(not world.dialogue.active,"existing dialogue ends")
 world.reset_trial();world.actor.set_logical(Vector2(14.605814,11.562791));world.camera.zoom=Vector2.ONE*1.05;world.follow=false;world.place_camera(Vector2(250,500));world.patrols_enabled=true;await frames(3)
 check(not world.ACCESS.clear(world,Vector2(4.15,3.5)),"control point really is blocked by exterior wall")
 var camera=world.camera.position;var original_world=world.get_instance_id()
 for cycle in range(3):
  await key(KEY_W,true);await key(KEY_F,true)
  var state=snapshot();await p.completed
  check(is_instance_valid(p.room) and p.room.map_size==Vector2(8,6),"8x6 room entered")
  check(not world.visible and world.process_mode==Node.PROCESS_MODE_DISABLED,"exterior suspended without freeing")
  check(snapshot()==state,"NPC positions and all route progress frozen across entry")
  var room=p.room;var start=room.actor.logical
  await frames(30);await key(KEY_F,true,true)
  check(p.room==room and p.transitions==cycle*2+1,"held F/echo cannot bounce out")
  check(room.actor.logical.distance_to(start)<.001,"held W does not move room actor")
  check(snapshot()==state,"exterior remains frozen inside")
  check(room.actor.speed==9.6 and world.npcs.all(func(n):return n.speed==4.8),"speeds retained")
  # Real room collision space must contain only room bodies, not exterior walls.
  check(room.ACCESS.clear(room,Vector2(4.15,3.5)),"exterior courtyard wall is absent from room physics")
  var table=room.props.filter(func(n):return n.spec.id=="table")[0]
  room.actor.set_logical(Vector2(2.6,1.35));room.update_depth();check(room.actor.get_index()<table.get_index(),"furniture sorts over actor behind")
  room.actor.set_logical(Vector2(2.6,2.65));room.update_depth();check(room.actor.get_index()>table.get_index(),"actor sorts in front of table")
  check(not room.ACCESS.clear(room,table.footprint.get_center()),"table has ground collision")
  room.actor.set_logical(Vector2(4,5.05));room.update_depth();room.update_occlusion();room.visibility_hint.refresh()
  check(room.actor.occluded and room.visibility_hint.visible,"existing locator identifies actor behind doorway")
  room.actor.set_logical(start)
  await key(KEY_W,false);await key(KEY_F,false);await frames(2)
  room.actor.set_logical(Vector2(2.6,2.8));await frames(1)
  Input.action_press("iso_right",.894427);Input.action_press("iso_up",.447214);await frames(10)
  Input.action_release("iso_right");Input.action_release("iso_up");await frames(1)
  check(room.actor.logical.y>=2.44,"real movement is blocked by table")
  room.actor.set_logical(start);await frames(2)
  await key(KEY_W,true);await key(KEY_F,true);await p.completed
  check(not is_instance_valid(p.room) and world.get_instance_id()==original_world,"same exterior instance restored")
  check(snapshot()==state,"NPC state restored at fade completion")
  check(world.actor.logical.distance_to(Vector2(14.605814,11.562791))<.001,"return outside doorway without overlap")
  check(world.camera.zoom==Vector2.ONE*1.05 and not world.follow and world.camera.position==camera,"manual camera/zoom/follow restored")
  check(world.actor.facing=="front" and not world.actor.facing_flipped,"faces away from house on return")
  var before=world.actor.logical;await frames(8);print("RETURN_DELTA ",world.actor.logical-before," neutral=",world.actor.input_neutral_required," W=",Input.is_action_pressed("iso_up"));check(world.actor.logical.distance_to(before)<.001,"held W cannot cause return jump")
  await key(KEY_F,true,true);check(p.transitions==(cycle+1)*2,"held F cannot reenter")
  await key(KEY_W,false);await key(KEY_F,false);await frames(2)
 check(world.ACCESS.clear(world,world.actor.logical),"return ground is clear")
 var point=world.npcs[1].logical;await frames(30);check(world.npcs[1].logical.distance_to(point)>.1,"NPC patrol resumes after return")
 world.actor.set_logical(Vector2(14.605814,11.562791));await frames(2);await key(KEY_F,true);await p.completed
 var room_id=p.room.get_instance_id()
 await key(KEY_F,false);world.queue_free();await process_frame;await process_frame
 check(not is_instance_id_valid(room_id),"removing district while inside also removes room")
 check(not InputMap.has_action("iso_interact"),"scene inputs cleaned up")
 print("ISOMETRIC_PASSAGE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
