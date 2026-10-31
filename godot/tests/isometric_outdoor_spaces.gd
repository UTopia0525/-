extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("ISO_SPACES: "+message)
func frames(count: int) -> void:
 for i in range(count):await physics_frame
func drive(direction: Vector2,count: int) -> int:
 var p=Space.project(direction).normalized();var hits=0
 for pair in [["iso_left",maxf(0,-p.x)],["iso_right",maxf(0,p.x)],["iso_up",maxf(0,-p.y)],["iso_down",maxf(0,p.y)]]:
  if pair[1]>0:Input.action_press(pair[0],pair[1])
 for i in range(count):
  await physics_frame
  hits+=scene.actor.get_slide_collision_count()
 for action in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(action)
 await physics_frame;return hits
func run() -> void:
 create_timer(90).timeout.connect(func():push_error("ISO_SPACES watchdog");quit(2))
 scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(3)
 scene.patrols_enabled=false
 for i in range(2):scene.npcs[i].set_logical(Vector2(10,11+i*.3))
 check(scene.ACCESS.validate(scene).is_empty(),"authored outdoor layout validates")
 var gates=scene.props.filter(func(p):return p.spec.kind=="gate")
 check(gates.size()==2,"house roofed gate and warehouse timber gateway")
 for gate in gates:
  check(gate.sprite!=null and gate.source_image!=null,"each entrance has painted gate art")
  check(gate.physical_footprints.size()==2,"each gate owns solid pillar colliders")
  var opening=scene.ACCESS.rect(gate.spec.opening);var center=opening.get_center()
  var direction=Vector2(0,1) if opening.size.x>opening.size.y else Vector2(1,0)
  scene.actor.set_logical(center-direction*.7);await physics_frame;await drive(direction,19)
  check((scene.actor.logical-center).dot(direction)>.55,"keyboard traversal through "+gate.name)
  scene.update_depth();check(scene.depth_cycles==0,"depth remains acyclic after gate traversal")
  scene.actor.set_logical(center);scene.update_depth()
  check(scene.actor.get_index()<gate.get_index(),"lintel is over actor while underneath")
  scene.actor.set_logical(center+direction*.8);scene.update_depth()
  check(scene.actor.get_index()>gate.get_index(),"actor in front sorts above gateway")
  await drive(-direction,20)
  check((scene.actor.logical-center).dot(direction)<-.6,"return through same passage")
  for post in gate.physical_footprints:
   scene.actor.set_logical(post.get_center()-direction*.7);await physics_frame
   var hits=await drive(direction,19)
   check(hits>0,"actual collision blocks pillar approach")
   var near=scene.actor.logical.clamp(post.position,post.end)
   check(near.distance_to(scene.actor.logical)>=.142,"actor never enters the pillar ground footprint")
 var original=scene.props.duplicate();scene.props.erase(gates[1])
 check(scene.ACCESS.validate(scene).any(func(s):return s.contains("no gate artwork")),"bare gap cannot stand in for gateway art");scene.props=original
 var fake={"id":"unwalled_stall","kind":"building","rect":[9.5,9,1,1],"enclosure":"open"}
 scene.data.props.append(fake)
 check(scene.ACCESS.validate_plots(scene).is_empty(),"unenclosed buildings are not forced to have a courtyard")
 fake.enclosure="walled";check(scene.ACCESS.validate_plots(scene).any(func(s):return s.contains("requires a courtyard")),"declared walls require a real owned courtyard");scene.data.props.pop_back()
 var workspace=scene.data.outdoor_spaces[0];var target=scene.ACCESS.vec(workspace.approach)
 scene.actor.set_logical(Vector2(8,10.3));await physics_frame
 await drive(target-scene.actor.logical,14)
 check(scene.actor.logical.distance_to(target)<.25,"workstation frontage reached directly from public yard")
 check(scene.ACCESS.validate_open_spaces(scene).is_empty(),"open frontage remains clear without walls")
 check(scene.actor.speed==9.6 and scene.npcs.all(func(n):return n.speed==4.8),"player9.6 and unchanged NPC4.8")
 print("ISOMETRIC_OUTDOOR_SPACES: "+("FAIL" if failed else "PASS"));scene.queue_free();await process_frame;quit(1 if failed else 0)
