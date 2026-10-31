extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
var failed=false
var travel_frames=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("ISO_DISTRICT: "+message)
func frames(n: int) -> void:
 for i in range(n):await physics_frame
func steer(direction: Vector2) -> void:
 var p=Space.project(direction).normalized()
 for pair in [["iso_left",maxf(0,-p.x)],["iso_right",maxf(0,p.x)],["iso_up",maxf(0,-p.y)],["iso_down",maxf(0,p.y)]]:
  Input.action_release(pair[0])
  if pair[1]>0:Input.action_press(pair[0],pair[1])
func inspect_clearance() -> void:
 travel_frames+=1
 for person in scene.moving_actors:
  for prop in scene.props:
   for r in prop.physical_footprints:
    check(person.logical.distance_to(person.logical.clamp(r.position,r.end))>=.142,"moving actors clear "+prop.name)
 for i in range(scene.moving_actors.size()):
  for j in range(i+1,scene.moving_actors.size()):check(scene.moving_actors[i].logical.distance_to(scene.moving_actors[j].logical)>=.292,"moving actors never overlap")
 check(scene.depth_cycles==0,"acyclic depth across expanded layout")
func walk_to(target: Vector2) -> void:
 for i in range(400):
  if scene.actor.logical.distance_to(target)<.09:break
  steer(target-scene.actor.logical);await physics_frame;inspect_clearance()
 steer(Vector2.ZERO);await physics_frame
 check(scene.actor.logical.distance_to(target)<.11,"real keyboard reaches "+str(target))
func key(code: int) -> void:
 for down in [true,false]:
  var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame;await process_frame
func run() -> void:
 create_timer(150).timeout.connect(func():push_error("ISO_DISTRICT watchdog");quit(2))
 root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(scene);await frames(3)
 check(scene.map_size==Vector2(20,16),"20x16 data-driven floor")
 check(scene.props.filter(func(p):return p.spec.kind=="building").size()==4,"four buildings with two open frontages")
 check(scene.npcs.size()==2 and scene.moving_actors.size()==3,"no new NPCs")
 check(scene.ACCESS.validate(scene).is_empty(),"all doors, courtyards and open workspaces validate")
 scene.actor.set_logical(Vector2(3.5,10));scene.npcs[0].patrol.setup(scene.npcs[0],[[6,11],[12,11]]);scene.npcs[0].patrol.pause=0
 scene.npcs[1].motion_paused=true;scene.npcs[1].set_logical(Vector2(19,15));scene.patrols_enabled=true
 var p0=scene.actor.logical;var n0=scene.npcs[0].logical
 steer(Vector2(1,0));await frames(20);steer(Vector2.ZERO);await physics_frame
 var pd=scene.actor.logical.distance_to(p0);var nd=scene.npcs[0].logical.distance_to(n0)
 check(absf(pd-3.2)<.2 and absf(nd-1.6)<.2,"measured player9.6 and unchanged NPC4.8")
 print("SPEED_MEASURE: player_distance=",pd," NPC_distance=",nd," over20physicsframes")
 scene.npcs[1].motion_paused=false;scene.npcs[0].patrol.setup(scene.npcs[0],scene.data.patrols[0].route);scene.reset_trial()
 scene.patrols_enabled=false
 for i in range(2):scene.npcs[i].set_logical(Vector2(19,14+i*.6))
 var loop_distance=0.0
 for i in range(scene.data.review_loop.size()-1):loop_distance+=Vector2(scene.data.review_loop[i][0],scene.data.review_loop[i][1]).distance_to(Vector2(scene.data.review_loop[i+1][0],scene.data.review_loop[i+1][1]))
 for point in scene.data.review_loop:await walk_to(Space.unproject(Space.project(Vector2(point[0],point[1]))))
 var loop_frames=travel_frames
 check(scene.actor.logical.distance_to(Vector2(scene.data.spawn[0],scene.data.spawn[1]))<.11,"complete loop returns to exact spawn")
 for building in scene.props.filter(func(p):return p.spec.kind=="building"):
  var e=building.spec.entrance;scene.actor.set_logical(Vector2(e.path[0][0],e.path[0][1]));await physics_frame
  for point in e.path:await walk_to(Vector2(point[0],point[1]))
  await walk_to(Vector2(e.threshold[0],e.threshold[1]))
 # Every expanded map edge physically blocks walking; old12 boundaries must be absent.
 for test in [[Vector2(.3,12.7),Vector2(-1,0),0],[Vector2(19.7,12.7),Vector2(1,0),0],[Vector2(10.5,.3),Vector2(0,-1),1],[Vector2(10.5,15.7),Vector2(0,1),1]]:
  scene.actor.set_logical(test[0]);await physics_frame;steer(test[1]);await frames(16);steer(Vector2.ZERO);await physics_frame
  var axis=int(test[2]);var limit=scene.map_size[axis]
  check(scene.actor.logical[axis]>=.142 and scene.actor.logical[axis]<=limit-.142,"map edge blocks at configured size")
 scene.actor.set_logical(Vector2(17.8,12));await physics_frame;steer(Vector2(1,0));await frames(10);steer(Vector2.ZERO)
 check(scene.actor.logical.x>18.5,"old12x12 boundary no longer blocks new street")
 for zoom in [.65,.85,1.25]:
  scene.camera.zoom=Vector2.ONE*zoom
  for point in [Vector2(.25,.25),Vector2(19.75,.25),Vector2(19.75,15.75),Vector2(.25,15.75),Vector2(16.5,7.7)]:
   scene.actor.set_logical(point);scene.snap_camera();await process_frame
   check(scene.camera.position.distance_to(scene.constrained_camera(scene.camera.position))<.01,"camera stays in configured bounds at every zoom")
   var screen=scene.get_canvas_transform()*scene.actor.position
   check(Rect2(15,105,1250,600).has_point(screen-Vector2(0,45*zoom)),"player remains visible at corner/edge "+str(point))
 scene.actor.set_logical(Vector2(16.5,11.5));scene.camera.zoom=Vector2.ONE*.85;scene.follow=true;scene.snap_camera()
 await key(KEY_C);check(not scene.follow,"C disables following")
 var camera_before=scene.camera.position;await walk_to(Vector2(16.5,12.2));check(scene.camera.position==camera_before,"manual camera stays put while player moves")
 await key(KEY_C);check(scene.follow,"C resumes following");await frames(2)
 check(scene.camera.position.distance_to(scene.constrained_camera(scene.actor.position-Vector2(0,96)))<.01,"following returns to player")
 # Real mouse wheel and middle drag share the same map-aware camera bounds.
 scene.follow=false
 var initial_zoom=scene.camera.zoom.x
 var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.position=Vector2(900,500);wheel.pressed=true
 Input.parse_input_event(wheel);await frames(2)
 check(is_equal_approx(scene.camera.zoom.x,initial_zoom+.1),"mouse wheel actually changes zoom")
 var middle=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.position=Vector2(900,500);middle.pressed=true;Input.parse_input_event(middle);await frames(2)
 var motion=InputEventMouseMotion.new();motion.position=Vector2(900,500);motion.relative=Vector2(-10000,10000);Input.parse_input_event(motion);await frames(2)
 check(scene.drag and scene.camera.position.distance_to(scene.constrained_camera(scene.camera.position))<.01,"middle drag clamps at configured map limits")
 middle=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.position=Vector2(900,500);middle.pressed=false;Input.parse_input_event(middle);await frames(2)
 check(not scene.drag,"middle button releases camera drag")
 scene.follow=true;scene.camera.zoom=Vector2.ONE*.85;scene.snap_camera()
 # Real F and H keys use the existing UI even far outside the original map.
 var a=scene.npcs[0];scene.actor.set_logical(Vector2(16.5,10.25));a.set_logical(Vector2(16.5,9.5));scene.npcs[1].set_logical(Vector2(19,15));await frames(2)
 await key(KEY_F);check(scene.dialogue.active and scene.dialogue.target==a,"F conversation works in expanded area")
 if scene.dialogue.active:
  await key(KEY_H);check(scene.dialogue.dialogue_history.visible and paused,"shared history works in expanded scene");await key(KEY_ESCAPE)
  for i in range(5):await key(KEY_F)
  check(not scene.dialogue.active and not scene.actor.motion_paused,"conversation finishes and restores movement")
 scene.reset_trial();scene.actor.set_logical(Vector2(16.5,5.5));scene.patrols_enabled=true;await frames(300)
 check(scene.npcs[1].patrol.yields>0,"NPC beyond old12 boundary yields without teleporting")
 scene.actor.set_logical(Vector2(19,15));var before=scene.npcs[1].patrol.arrivals;var bounds=Rect2(scene.npcs[1].logical,Vector2.ZERO)
 for i in range(720):await physics_frame;inspect_clearance();bounds=bounds.expand(scene.npcs[1].logical)
 check(scene.npcs[1].patrol.arrivals>before+6 and bounds.position.x<11.3 and bounds.end.x>16.2,"rear NPC repeatedly traverses new region")
 for person in scene.moving_actors:check(person.speed==(9.6 if person==scene.actor else 4.8) and is_equal_approx(person.base_scale.y*person.frames.get("canvas_height",person.images.front.get_height()),96),"speed and display height unchanged")
 print("DISTRICT_METRICS: loop_tiles=",loop_distance," | loop_input_seconds=",loop_frames/60.0," | clearance_frames=",travel_frames," | rear_range=",bounds)
 scene.queue_free();await process_frame
 scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(3)
 check(scene.map_size==Vector2(12,12) and scene.props.filter(func(p):return p.spec.kind=="building").size()==2,"original scene retains its own data")
 check(scene.ACCESS.validate(scene).is_empty(),"original12x12 scene remains valid")
 scene.camera.zoom=Vector2.ONE*.65;scene.actor.set_logical(Vector2(10,9));scene.snap_camera()
 check(is_zero_approx(scene.camera.position.x),"small map centers an axis when viewport is wider than map")
 scene.queue_free();await process_frame;check(not InputMap.has_action("iso_interact"),"scene inputs cleaned up")
 print("ISOMETRIC_DISTRICT: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
