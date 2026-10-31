extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var failed=false
var scene
var watch_pillars=false
var pillar_contacts=0
var gate
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ISO_ALLEY: "+message)
func walk(direction: Vector2,frames: int) -> void:
	# Drive the same input actions as the scene; no teleport during collision tests.
	var input=Space.project(direction).normalized()
	var actions={"iso_left":maxf(0,-input.x),"iso_right":maxf(0,input.x),"iso_up":maxf(0,-input.y),"iso_down":maxf(0,input.y)}
	for key in actions:
		if actions[key]>0:Input.action_press(key,actions[key])
	for i in range(frames):
		await physics_frame
		if watch_pillars:
			for j in range(scene.actor.get_slide_collision_count()):
				if scene.actor.get_slide_collision(j).get_collider()==gate:pillar_contacts+=1
			for physical in gate.physical_footprints:
				var near=scene.actor.logical.clamp(physical.position,physical.end)
				check(near.distance_to(scene.actor.logical)>.14,"actor never penetrates pillar footprint")
	for key in actions:Input.action_release(key)
	await physics_frame
func run() -> void:
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await process_frame;await physics_frame
	scene.patrols_enabled=false
	for i in range(scene.npcs.size()):scene.npcs[i].set_logical(Vector2(10,10+i))
	gate=scene.props.filter(func(p):return p.spec.kind=="gate")[0]
	check(gate.physical_footprints.size()==2,"two solid pillars, no solid opening")
	check(is_equal_approx(scene.actor.speed,4.8),"speed doubled from2.4 to4.8")
	scene.actor.set_logical(Vector2(7,10));await physics_frame
	var start: Vector2=scene.actor.logical;await walk(Vector2(1,0),12)
	var travel=scene.actor.logical.distance_to(start)
	check(travel>.8 and travel<1.15,"measured unobstructed movement is4.8 tiles/sec")
	scene.actor.set_logical(Vector2(4.72,8.5));await physics_frame;await walk(Vector2(0,-1),85)
	check(scene.actor.logical.y<1.9 and absf(scene.actor.logical.x-4.72)<.06,"full gate and narrow alley traverse north")
	await walk(Vector2(0,1),85)
	check(scene.actor.logical.y>8.2 and absf(scene.actor.logical.x-4.72)<.06,"full alley and gate traverse south")
	scene.actor.set_logical(Vector2(3.12,8.5));await physics_frame;await walk(Vector2(0,-1),40)
	check(scene.actor.logical.y<5.4,"house gate and private courtyard traverse")
	for x in [2.375,3.875]:
		scene.actor.set_logical(Vector2(x,7.25));await physics_frame;watch_pillars=true;pillar_contacts=0
		await walk(Vector2(0,-1),22);watch_pillars=false
		check(pillar_contacts>0,"actual pillar contact blocks initial path "+str(x))
		check(scene.actor.logical.y<7.25,"actor reaches pillar")
	scene.actor.set_logical(Vector2(4.72,5.5));await physics_frame;await walk(Vector2(-1,0),20)
	check(scene.actor.logical.x>=4.38,"left wall blocks")
	scene.actor.set_logical(Vector2(4.72,5.5));await physics_frame;await walk(Vector2(1,0),20)
	check(scene.actor.logical.x<=5.52,"right wall blocks")
	# Also exercise digital keyboard's equal-strength diagonal through the opening.
	scene.actor.set_logical(Vector2(3.35,7.2));await physics_frame
	Input.action_press("iso_right");Input.action_press("iso_up")
	for i in range(20):await physics_frame
	Input.action_release("iso_right");Input.action_release("iso_up");await physics_frame
	check(scene.actor.logical.y<6.25,"digital W+D traverses gate")

	scene.actor.set_logical(Vector2(3.12,6.5));scene.update_depth();scene.update_occlusion()
	check(scene.actor.get_index()<gate.get_index(),"under-gate canopy renders over actor")
	scene.actor.set_logical(Vector2(3.12,7.15));scene.update_depth()
	check(scene.actor.get_index()>gate.get_index(),"actor in front of gate renders over it")

	scene.actor.set_logical(Vector2(1.6,1.65));scene.update_depth();scene.update_occlusion();await process_frame
	check(scene.actor_occluded and scene.visibility_hint.visible,"hidden actor locator visible")
	check(scene.pick(scene.actor.position+Vector2(0,-45))!=scene.actor,"locator never enables selection through roof")
	scene.show_occlusion_hint=false;await process_frame;await process_frame
	check(not scene.visibility_hint.visible,"locator can be disabled")
	scene.show_occlusion_hint=true;scene.reset_actor();scene.update_depth();scene.update_occlusion();await process_frame;await process_frame
	check(not scene.actor_occluded and not scene.visibility_hint.visible,"locator clears in open courtyard")
	check(scene.depth_cycles==0,"no depth cycle on tested route")
	for prop in scene.props:
		if prop.sprite!=null:check(is_equal_approx(prop.sprite.scale.x,prop.sprite.scale.y),"art aspect ratio maintained")
	scene.queue_free();await process_frame;print("ISOMETRIC_ALLEY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
