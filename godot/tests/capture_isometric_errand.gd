extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var world
func _initialize() -> void:run.call_deferred()
func frames(n: int) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/errand-"+name+".png")==OK)
func key(code: int) -> void:
 for down in [true,false]:
  var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func walk(host,target: Vector2) -> void:
 for i in range(300):
  var d=target-host.actor.logical
  if d.length()<.10:break
  var p=Space.project(d).normalized()
  for pair in [["iso_left",maxf(0,-p.x)],["iso_right",maxf(0,p.x)],["iso_up",maxf(0,-p.y)],["iso_down",maxf(0,p.y)]]:
   Input.action_release(pair[0])
   if pair[1]>0:Input.action_press(pair[0],pair[1])
  await process_frame
 for a in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(a)
 await frames(2)
 assert(host.actor.logical.distance_to(target)<.18,"capture path blocked")
func run() -> void:
 create_timer(180).timeout.connect(func():push_error("Errand capture watchdog");quit(2))
 root.size=Vector2i(1280,720);world=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(world);await frames(3)
 # Controlled staging keeps the giver available; all travel after this uses inputs.
 world.patrols_enabled=false;world.npcs[0].set_logical(Vector2(3.12,9.7));world.npcs[1].set_logical(Vector2(16.5,6.7));world.actor.set_logical(Vector2(3.12,9));world.snap_camera()
 await frames(2);await shot("available");await key(KEY_F);await shot("offer")
 await key(KEY_F);await key(KEY_F);await key(KEY_F);await shot("choice")
 await key(KEY_1);await key(KEY_F);await key(KEY_F);await frames(3);await shot("accepted")
 await key(KEY_Q);await shot("journal-active");await key(KEY_Q)
 for point in [[4.72,9],[4.72,7.7],[16.5,7.7],[16.5,11.562791],[14.605814,11.562791]]:await walk(world,Vector2(point[0],point[1]))
 await key(KEY_F);await world.passage.completed;await frames(2)
 var room=world.passage.room
 for point in [[4,3.4],[2.7,3.4],[2.7,2.8]]:await walk(room,Vector2(point[0],point[1]))
 await shot("investigate-target");await key(KEY_F);await shot("inspect")
 await key(KEY_H);await shot("history");await key(KEY_ESCAPE);await key(KEY_F);await key(KEY_F)
 await frames(3);await shot("ready-inside")
 for point in [[4,2.8],[4,4.6],[3.7,5.35]]:await walk(room,Vector2(point[0],point[1]))
 await key(KEY_F);await world.passage.completed;await frames(2)
 for point in [[16.5,11.562791],[16.5,7.7],[4.72,7.7],[4.72,9],[3.12,9]]:await walk(world,Vector2(point[0],point[1]))
 await shot("report-marker");await key(KEY_F);await shot("report-dialogue");await key(KEY_F);await key(KEY_F);await key(KEY_F)
 await frames(3);await shot("completed");await key(KEY_Q);await shot("journal-completed");await key(KEY_Q)
 assert(world.errand.phase=="completed" and world.errand.completion_count==1)
 world.queue_free();await process_frame;print("ISOMETRIC_ERRAND_CAPTURE: PASS");quit()
