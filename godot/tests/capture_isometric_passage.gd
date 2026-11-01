extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var world
func _initialize() -> void:run.call_deferred()
func frames(n: int) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/passage-"+name+".png")==OK)
func key(code: int,down: bool) -> void:
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func move(world_ref,target: Vector2) -> void:
 for i in range(150):
  var d=target-world_ref.actor.logical
  if d.length()<.18:break
  var p=Space.project(d).normalized()
  for pair in [["iso_left",maxf(0,-p.x)],["iso_right",maxf(0,p.x)],["iso_up",maxf(0,-p.y)],["iso_down",maxf(0,p.y)]]:
   Input.action_release(pair[0])
   if pair[1]>0:Input.action_press(pair[0],pair[1])
  await process_frame
 for a in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(a)
 await frames(2)
func run() -> void:
 create_timer(120).timeout.connect(func():push_error("Passage capture watchdog");quit(2))
 root.size=Vector2i(1280,720);world=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(world);await frames(3)
 world.actor.set_logical(Vector2(15.5,11.562791));world.snap_camera();world.selection_message="외부 · 열린 민가 한 동만 F로 출입"
 await move(world,Vector2(14.605814,11.562791));await shot("outside")
 var p=world.passage;await key(KEY_F,true);await p.completed;await frames(2);await shot("inside-entry")
 await key(KEY_F,false);await frames(2)
 var room=p.room
 room.selection_message="민가 실내 · 8×6 / 기존85% / 도원 속도9.6 유지"
 await shot("overview")
 await move(room,Vector2(4,3.4));await move(room,Vector2(3.5,3.4));await move(room,Vector2(3.5,1.25));await move(room,Vector2(2.6,1.25));await shot("behind-table")
 await move(room,Vector2(3.7,1.25));await move(room,Vector2(3.7,3.4));await move(room,Vector2(2.6,3.4));await shot("front-table")
 await move(room,Vector2(4,3.4));await move(room,Vector2(4,5.1));await shot("exit")
 await key(KEY_F,true);await p.completed;await shot("returned");await frames(15)
 await key(KEY_F,false);await frames(2);await key(KEY_F,true);await p.completed;await key(KEY_F,false);await frames(2)
 await shot("second-entry");await key(KEY_F,true);await p.completed;await key(KEY_F,false);await frames(10)
 world.queue_free();await process_frame;print("ISOMETRIC_PASSAGE_CAPTURE: PASS");quit()
