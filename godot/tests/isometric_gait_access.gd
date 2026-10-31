extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("GAIT_ACCESS: "+message)
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func walk_to(point: Vector2) -> void:
	for i in range(240):
		var delta=point-scene.actor.logical
		if delta.length()<.05:break
		var direction=Space.project(delta).normalized()
		var actions={"iso_left":maxf(0,-direction.x),"iso_right":maxf(0,direction.x),"iso_up":maxf(0,-direction.y),"iso_down":maxf(0,direction.y)}
		for action in actions:
			Input.action_release(action)
			if actions[action]>0:Input.action_press(action,actions[action])
		await physics_frame
	for action in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(action)
	await physics_frame;check(scene.actor.logical.distance_to(point)<.11,"actual keyboard route reaches "+str(point))
func run() -> void:
	create_timer(120).timeout.connect(func():push_error("GAIT_ACCESS watchdog");quit(2))
	scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(3);scene.patrols_enabled=false
	for i in range(scene.npcs.size()):scene.npcs[i].set_logical(Vector2(10,10+i))
	var errors=scene.ACCESS.validate(scene);check(errors.is_empty(),"valid entrances: "+str(errors))
	var buildings=scene.props.filter(func(p):return p.spec.kind=="building")
	for prop in buildings:
		check(prop.spec.entrance.interior==null,"non-enterable building still declares entrance")
		var e=prop.spec.entrance
		scene.actor.set_logical(Space.unproject(Space.project(scene.ACCESS.vec(e.path[0]))));await physics_frame
		for point in e.path:await walk_to(scene.ACCESS.vec(point))
		await walk_to(scene.ACCESS.vec(e.threshold))
		check(scene.actor.logical.distance_to(scene.ACCESS.vec(e.threshold))<.11,"player stands at visible "+str(prop.name)+" doorway")
	var warehouse=buildings[1];var original=warehouse.spec.entrance.duplicate(true)
	warehouse.spec.erase("entrance");check(not scene.ACCESS.validate(scene).is_empty(),"missing entrance rejected for no-interior building");warehouse.spec.entrance=original.duplicate(true)
	warehouse.spec.entrance.facing=[-1,0];check(scene.ACCESS.validate(scene).any(func(s):return s.contains("front of")),"backwards doorway approach rejected");warehouse.spec.entrance=original.duplicate(true)
	warehouse.spec.entrance.threshold[0]+=1;check(scene.ACCESS.validate(scene).any(func(s):return s.contains("visual door")),"wrong painted door registration rejected");warehouse.spec.entrance=original.duplicate(true)
	var body=StaticBody2D.new();body.collision_layer=1;var shape=CollisionPolygon2D.new();shape.polygon=Space.diamond(Rect2(7,6.3,1.4,.2));body.add_child(shape);scene.add_child(body);await frames(2)
	check(scene.ACCESS.validate(scene).any(func(s):return s.contains("blocked route")),"closing loading gate invalidates entrance access")
	body.queue_free();await frames(2);check(scene.ACCESS.validate(scene).is_empty(),"opening loading gate restores access")
	for person in [scene.actor,scene.npcs[0]]:
		check(person.speed==4.8,"movement speed remains unchanged")
		for key in ["front","back"]:
			var poses=[];var body_y=[];var arms=[];var feet=[];var bends=[]
			for i in range(8):
				person.moving=true;person.phase=i*TAU/8;person.set_pose(key,false);var rig=person.rig
				poses.append(JSON.stringify(rig.joints));body_y.append(rig.body_offset.y*person.base_scale.y)
				arms.append(rig.joints.arms[0].hand);feet.append(rig.joints.legs[0].foot)
				var flex=[]
				for side in range(2):
					var leg=rig.joints.legs[side];var src_hip=rig.point(rig.rest.hips[side]);var src_knee=rig.point(rig.rest.knees[side]);var src_foot=rig.point(rig.rest.feet[side])
					check(absf(leg.hip.distance_to(leg.knee)-src_hip.distance_to(src_knee))<.02,"thigh never scales")
					check(absf(leg.knee.distance_to(leg.foot)-src_knee.distance_to(src_foot))<.02,"shin never scales")
					flex.append(PI-absf((leg.hip-leg.knee).angle_to(leg.foot-leg.knee)))
					if leg.stance:
						var forward=Vector2(1,.466667) if key=="front" else Vector2(-1,-.466667)
						var expected=src_foot+forward*float(rig.profile.stride)*rig.tex_size.y*cos(person.phase+side*PI)
						check(leg.foot.distance_to(expected)*person.base_scale.y<.15,"supporting foot stays on its ground trajectory")
				bends.append(flex)
			check(body_y.max()-body_y.min()>.7 and body_y.max()-body_y.min()<5,"visible restrained body bob")
			check(bends[2][1]>.30 and bends[6][0]>.30,"opposite swing knees visibly bend")
			check((arms[0]-arms[4]).dot(feet[0]-feet[4])<0,"arm swings opposite its leg")
			var unique={}
			for pose in poses:unique[pose]=true
			check(unique.size()==8,"eight distinct whole-body gait poses")
			print("GAIT ",person.display_name," ",key," | bob_px=",body_y.max()-body_y.min()," | swing_knee_rad=",bends[2][1],"/",bends[6][0])
		person.stop_motion()
	scene.queue_free();await process_frame;print("ISOMETRIC_GAIT_ACCESS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
