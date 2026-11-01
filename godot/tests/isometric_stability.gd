extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var host
var failed=false
var states=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("ISO_STABILITY: "+message)
func reference_order(world) -> Array:
 # Frozen pre-optimization algorithm: independent oracle for the cache/queue.
 var nodes=world.props.duplicate();nodes.append_array(world.moving_actors)
 var edges={};var indegree={}
 for node in nodes:edges[node]=[];indegree[node]=0
 for i in range(nodes.size()):
  for j in range(i+1,nodes.size()):
   var a=nodes[i];var b=nodes[j]
   if world.comes_before(a,b):edges[a].append(b);indegree[b]+=1
   elif world.comes_before(b,a):edges[b].append(a);indegree[a]+=1
 var remaining=nodes.duplicate();var result=[]
 while not remaining.is_empty():
  var ready=remaining.filter(func(n):return indegree[n]==0)
  if ready.is_empty():ready=remaining.duplicate()
  ready.sort_custom(func(a,b):
   var ay=Space.project(a.footprint.get_center()).y;var by=Space.project(b.footprint.get_center()).y
   return ay<by if not is_equal_approx(ay,by) else str(a.name)<str(b.name))
  var next=ready[0];result.append(next);remaining.erase(next)
  for other in edges[next]:indegree[other]-=1
 return result
func reference_occlusion(world) -> Array:
 var items=world.props.duplicate();items.append_array(world.moving_actors);var result=[]
 for person in world.moving_actors:
  var samples=0
  for y in [18,44,70,90]:
   for x in [-10,0,10]:
    var point=person.position+Vector2(x,-y)
    for prop in items:
     if prop.get_index()>person.get_index() and prop.hit(point):samples+=1;break
  result.append(samples)
 return result
func compare() -> void:
 host.last_sorted_positions=[];host.update_depth()
 check(host.actors.get_children()==reference_order(host),"cached sort equals old full graph in state "+str(states))
 host.update_occlusion()
 check(host.moving_actors.map(func(p):return p.occluded_samples)==reference_occlusion(host),"broad phase preserves all exact alpha/mesh/wall samples "+str(states))
 states+=1
func run() -> void:
 var initial_interpolation=physics_interpolation
 create_timer(180).timeout.connect(func():push_error("STABILITY watchdog");quit(2))
 for scene in ["main","district","room"]:
  host=load("res://prototypes/isometric/"+scene+".tscn").instantiate();root.add_child(host);await physics_frame;await physics_frame
  check(physics_interpolation if scene!="main" else physics_interpolation==initial_interpolation,"interpolation enabled only for district/room")
  host.patrols_enabled=false
  for person in host.moving_actors:person.set_physics_process(false)
  # Door crossings and both sides of every existing structure, including walls.
  for prop in host.props:
   for offset in [Vector2(-.2,-.2),Vector2(.2,.2)]:
    host.actor.set_logical(prop.footprint.get_center()+offset)
    host.actor.moving=states%2==0;host.actor.phase=fmod(states*.27,TAU);host.actor.set_pose("front" if states%3==0 else "back",states%2==0)
    compare()
  # Cache invalidation must not rely solely on an actor moving.
  var builds=host.static_depth_builds;host.update_depth();check(host.static_depth_builds==builds,"static graph reused")
  var rect=host.props[0].footprint;host.props[0].footprint=rect.grow(.001);compare()
  check(host.static_depth_builds==builds+1,"changed static footprint invalidates cache")
  host.props[0].footprint=rect;compare()
  var a=host.actor;a.moving=true;a.set_pose("front",false);var rig=a.rig;var initial=rig.hit_index_builds
  for i in range(15):rig.pose(a.images.front,a.hit_images.front,"front",i*.17)
  check(rig.hit_index_builds==initial and rig.hit_index_dirty,"walking does not eagerly rebuild hit triangles")
  rig.hit(Vector2(-10000,-10000));rig.hit(rig.to_global(Vector2(0,rig.tex_size.y*.15)))
  check(rig.hit_index_builds==initial,"miss and head probes need no mesh index")
  var body=rig.to_global(Vector2(0,rig.tex_size.y*.65));var lazy=rig.hit(body)
  check(rig.hit_index_builds==initial+1,"first body hit builds exact index")
  check(rig.hit(body)==lazy and rig.hit_index_builds==initial+1,"subsequent hits reuse same pose index")
  if scene=="district":
   for npc in host.npcs:npc.set_logical(Vector2(19,15))
   var p=host.passage;var threshold=Vector2(p.doorway.threshold[0],p.doorway.threshold[1])
   for offset in [Vector2(1.25,0),Vector2(1.1,.65),Vector2(1.1,-.65)]:
    a.set_logical(threshold+offset);await physics_frame
    check(p.offer(),"expanded front entry offers at "+str(offset))
   for offset in [Vector2(1.41,0),Vector2(-1.2,0),Vector2(.8,.8)]:
    a.set_logical(threshold+offset);await physics_frame
    check(not p.offer(),"range/back/lateral rejection retained at "+str(offset))
   a.set_logical(Vector2(13.5,11.56));await physics_frame;check(not p.offer(),"building/wall blocks back entry")
  host.queue_free();await process_frame;await process_frame
  check(physics_interpolation==initial_interpolation,"interpolation restored after scene removal")
 print("ISOMETRIC_STABILITY: "+("FAIL" if failed else "PASS")+" | exact_reference_states="+str(states));quit(1 if failed else 0)
