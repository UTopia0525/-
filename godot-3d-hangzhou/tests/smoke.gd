extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,text: String) -> void:
 if not ok:failed=true;push_error("HANGZHOU_3D: "+text)
func frames(n: int) -> void:
 for i in range(n):await physics_frame
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(50)
 var p=game.player
 check(p.avatar!=null and p.joints.size()==7,"real GLB and articulated joints")
 check(p.is_on_floor(),"spawn stands on bank")
 var before=p.position;Input.action_press("forward");await frames(80);Input.action_release("forward");await frames(10)
 check(p.position.distance_to(before)>4,"W moves character in camera direction")
 check(p.position.z<before.z and absf(p.position.x-before.x)<.2,"movement follows north-facing camera")
 # Both bridges support crossing from the east promenade to the west.
 for z in [-18,24]:
  p.position=Vector3(14,.7,z);p.velocity=Vector3.ZERO;p.yaw=0;await frames(20)
  Input.action_press("left");Input.action_press("sprint");await frames(240);Input.action_release("left");Input.action_release("sprint");await frames(10)
  check(p.position.x< -12 and p.is_on_floor(),"walks over bridge "+str(z))
 # Bank, pier and pleasure-boat deck form a continuous boarding route.
 p.position=Vector3(14,.8,8);p.velocity=Vector3.ZERO;await frames(20)
 Input.action_press("left");await frames(190);Input.action_release("left");await frames(15)
 check(absf(p.position.x)<4.1 and p.position.y>.65 and p.is_on_floor(),"boards barge from pier")
 # The camera retracts at architecture; reset is safe after falling in water.
 p.position=Vector3(0,-5,35);await frames(30);check(p.position.distance_to(p.spawn)<1,"water recovery")
 p.position=Vector3(29,.8,40);p.velocity=Vector3.ZERO;await frames(20)
 Input.action_press("right");await frames(150);Input.action_release("right");await frames(10)
 check(p.position.x<33,"solid buildings block the character")
 check(get_nodes_in_group("npc").is_empty(),"no NPC population")
 check(game.music.stream.loop,"music repeats")
 # Walk through the front door into the real ground-floor hall.
 p.position=Vector3(-31,.7,-29);p.velocity=Vector3.ZERO;p.yaw=0;await frames(20)
 Input.action_press("forward");await frames(100);Input.action_release("forward");await frames(10)
 check(p.position.z< -34.5 and p.is_on_floor(),"enters Cuiyue ground floor through doorway")
 # A camera pitched down still shortens its arm rather than entering a wall.
 p.position=Vector3(32,.6,35);p.yaw=PI/2;p.zoom=8;await frames(30)
 check(p.arm.get_hit_length()<p.arm.spring_length,"camera retracts against architecture")
 var f4=InputEventKey.new();f4.keycode=KEY_F4;f4.pressed=true;game._unhandled_input(f4)
 check(game.low_quality and not game.sun.shadow_enabled,"lightweight graphics toggle")
 game.queue_free();await process_frame;print("HANGZHOU_3D_SMOKE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
