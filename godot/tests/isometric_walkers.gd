extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
var failed=false
var checked_frames=0
var min_separation=INF
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ISO_WALKERS: "+message)
func frames(count: int,inspect=false) -> void:
	for i in range(count):
		await physics_frame
		if inspect:_check_clearance()
func _check_clearance() -> void:
	checked_frames+=1
	for i in range(scene.moving_actors.size()):
		var person=scene.moving_actors[i]
		for j in range(i+1,scene.moving_actors.size()):
			var distance=person.logical.distance_to(scene.moving_actors[j].logical)
			min_separation=minf(min_separation,distance)
			check(distance>=.292,"physical actors never overlap")
		for prop in scene.props:
			for r in prop.physical_footprints:
				var near: Vector2=person.logical.clamp(r.position,r.end)
				check(near.distance_to(person.logical)>=.142,"actor never penetrates static ground footprint "+str(prop.name))
func isolate() -> void:
	scene.patrols_enabled=false
	for i in range(scene.npcs.size()):scene.npcs[i].set_logical(Vector2(10,10+i))
func run() -> void:
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(2)
	check(scene.npcs.size()==2 and scene.moving_actors.size()==3,"one controlled and exactly two autonomous actors")
	check(scene.actor.speed==9.6,"existing double movement speed retained")
	isolate()
	var keys=["iso_right","iso_left","iso_down","iso_up"]
	for key in keys:
		scene.actor.set_logical(Vector2(8,10));var seen={};Input.action_press(key)
		for i in range(30):
			await physics_frame;seen[scene.actor.walk_frame]=true
			check(scene.actor.sprite.scale==scene.actor.base_scale and scene.actor.sprite.rotation==0,"constant body transform in four directions")
			var foot=scene.actor.sprite.position+scene.actor.sprite.texture.get_size()*Vector2(.5,1)*scene.actor.base_scale
			check(foot.length()<.001,"common ground pivot in all poses")
		Input.action_release(key);check(seen.size()==8,"full eight-phase gait cycle in "+key);await frames(2)
		check(not scene.actor.moving and scene.actor.sprite.visible and not scene.actor.rig.visible,"idle restores stable atlas")
	for key in ["front","back"]:
		scene.actor.moving=true;scene.actor.phase=PI/2;scene.actor.set_pose(key,false)
		var rig=scene.actor.rig;var first: PackedVector2Array=rig.polygon.duplicate();var first_feet=[rig.joints.legs[0].foot,rig.joints.legs[1].foot]
		scene.actor.phase=PI*1.5;scene.actor.set_pose(key,false)
		var swapped: PackedVector2Array=rig.polygon
		check((first[1]-first[0]).distance_to(swapped[1]-swapped[0])<.001,"head size remains constant while body bobs")
		check((first_feet[0]-rig.joints.legs[0].foot).dot(first_feet[1]-rig.joints.legs[1].foot)<0,"feet lift in opposing phases "+key)
		scene.actor.moving=false;scene.actor.set_pose(key,false)
	# Force a real body contact with a paused NPC; avoidance alone must not hide a missing collider.
	scene.actor.set_logical(Vector2(7,10));scene.npcs[0].set_logical(Vector2(8,10));var contacts=0
	Input.action_press("iso_right",.894427);Input.action_press("iso_down",.447214)
	for i in range(30):
		await frames(1,true)
		for j in range(scene.actor.get_slide_collision_count()):
			if scene.actor.get_slide_collision(j).get_collider()==scene.npcs[0]:contacts+=1
	Input.action_release("iso_right");Input.action_release("iso_down")
	check(contacts>0,"paused NPC physically blocks keyboard actor")
	check(scene.npcs[0].logical.distance_to(Vector2(8,10))<.001,"contact never pushes or teleports paused NPC")
	# All NPCs move without the operator and visit both ends of the authored routes.
	scene.actor.set_logical(Vector2(10.5,10.5));scene.reset_trial();scene.actor.set_logical(Vector2(10.5,10.5));scene.patrols_enabled=true
	var ranges=[Rect2(scene.npcs[0].logical,Vector2.ZERO),Rect2(scene.npcs[1].logical,Vector2.ZERO)]
	for i in range(1500):
		await frames(1,true)
		for j in range(2):ranges[j]=ranges[j].expand(scene.npcs[j].logical)
	check(ranges[0].position.y<3.5 and ranges[0].end.y>9.5,"gate NPC visits yard and inner alley")
	check(ranges[1].position.x<1.6 and ranges[1].end.x>7.4 and ranges[1].position.y<1.65,"rear NPC visits building side and back path")
	check(scene.npcs[0].patrol.arrivals>10 and scene.npcs[1].patrol.arrivals>6,"both patrols repeatedly progress")
	# Deliberately block the gate, then release it. No collision is disabled to yield.
	scene.patrols_enabled=false;scene.reset_trial();scene.actor.set_logical(Vector2(3.12,6.5));scene.npcs[1].set_logical(Vector2(10,10));scene.patrols_enabled=true
	await frames(540,true)
	check(scene.npcs[0].patrol.yields>0,"gate encounter invokes yielding")
	scene.actor.set_logical(Vector2(10.5,10.5));var before=scene.npcs[0].patrol.arrivals
	await frames(600,true)
	check(scene.npcs[0].patrol.arrivals>before+4,"NPC resumes route after gate obstruction is removed")
	# Hold an oncoming input against the NPC in the alley, not only a stationary block.
	scene.patrols_enabled=false;scene.reset_trial();scene.actor.set_logical(Vector2(3.12,4.7));scene.npcs[1].set_logical(Vector2(10,10));scene.patrols_enabled=true
	Input.action_press("iso_left",.894427);Input.action_press("iso_down",.447214)
	await frames(70,true);Input.action_release("iso_left");Input.action_release("iso_down")
	check(scene.actor.logical.y>8.1,"keyboard actor passes oncoming NPC without permanent gate lock")
	# Two autonomous actors also meet; stable priority must let both eventually pass.
	scene.patrols_enabled=false;scene.actor.set_logical(Vector2(10.5,10.5))
	var a=scene.npcs[0];var b=scene.npcs[1]
	a.patrol.setup(a,[[4.72,8.8],[4.72,3.35]]);b.patrol.setup(b,[[4.72,3.35],[4.72,8.8]])
	scene.patrols_enabled=true;await frames(900,true)
	check(a.patrol.arrivals>1 and b.patrol.arrivals>1,"two oncoming patrols both make progress")
	# Three hidden labels stay tied to their owners and do not overlap at any zoom.
	scene.patrols_enabled=false;scene.follow=false;scene.camera.position=Vector2(-85,290)
	for i in range(3):scene.moving_actors[i].set_logical(Vector2(1.2+i*.35,1.5))
	for zoom in [.65,.85,1.25]:
		scene.camera.zoom=Vector2.ONE*zoom;scene.camera.force_update_scroll();scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh()
		var hints=scene.visibility_hint
		check(hints.label_rects.size()==3,"all hidden actors have a locator")
		for i in range(hints.label_rects.size()):
			check(hints.markers[i].foot.distance_to(scene.get_canvas_transform()*scene.moving_actors[i].position)<.01,"locator tracks correct actor after camera zoom")
			for j in range(i+1,hints.label_rects.size()):check(not hints.label_rects[i].intersects(hints.label_rects[j]),"hidden labels never overlap")
		var first_order=scene.actors.get_children();scene.update_depth();check(first_order==scene.actors.get_children(),"stationary depth order remains stable")
	check(scene.depth_cycles==0,"no sorting cycles over all tested routes")
	print("ISOMETRIC_WALKERS: "+("FAIL" if failed else "PASS")+" | clearance frames="+str(checked_frames)+" | minimum actor spacing="+str(min_separation))
	scene.queue_free();await process_frame;quit(1 if failed else 0)
