extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var failed=false
var scene
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ISO_TEST: "+message)
func press(action: String,frames: int) -> void:
	Input.action_press(action)
	for i in range(frames):await physics_frame
	Input.action_release(action);await physics_frame
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	for u in range(-5,18):
		for v in range(-5,18):
			var p=Vector2(u+.37,v+.19);check(p.distance_to(Space.unproject(Space.project(p)))<.00001,"projection round trip")
	check(Space.from_legacy([128,256,256,128],128)==Rect2(1,2,2,1),"legacy coordinate adapter")
	var initial_actions=InputMap.get_actions()
	scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await process_frame;await physics_frame
	check(scene.props.filter(func(p):return p.spec.kind=="building").size()==2,"two original buildings retained")
	check(scene.actor.sprite.texture!=null,"NPC atlas loaded")
	for prop in scene.props:
		if prop.sprite!=null:check(is_equal_approx(prop.sprite.scale.x,prop.sprite.scale.y),"unwarped building art")
	for prop in scene.props:
		if prop.spec.kind!="building":continue
		var r: Rect2=prop.footprint
		for entry in [[Vector2(r.position.x-.4,r.get_center().y),true],[Vector2(r.end.x+.4,r.get_center().y),false],[Vector2(r.get_center().x,r.position.y-.4),true],[Vector2(r.get_center().x,r.end.y+.4),false]]:
			scene.actor.set_logical(entry[0]);scene.update_depth()
			check((scene.actor.get_index()<prop.get_index())==entry[1],"front/back and side occlusion "+prop.name+str(entry[0]))
	check(scene.depth_cycles==0,"no cyclic occlusion in test layout")
	scene.actor.set_logical(Vector2(4.55,3.3));await physics_frame
	Input.action_press("iso_left");await press("iso_up",22);Input.action_release("iso_left")
	check(scene.actor.logical.x>=4.12,"actual keyboard movement collides with house side")
	check(scene.actor.logical.x<4.55,"actor moved before contacting wall")
	scene.actor.set_logical(Vector2(.3,7));await physics_frame
	Input.action_press("iso_left");await press("iso_up",70);Input.action_release("iso_left")
	check(scene.actor.logical.x>=.13 and scene.actor.logical.y>=.13,"map edge is physically closed")
	scene.reset_actor();await physics_frame
	var start: Vector2=scene.actor.position;await press("iso_right",10)
	check(scene.actor.position.x>start.x and absf(scene.actor.position.y-start.y)<.1,"D moves horizontally on screen")
	check(is_equal_approx(scene.actor.sprite.scale.x,scene.actor.base_scale.x),"body width stable")
	scene.select_target(scene.actor);check(scene.actor.picked,"NPC selection")
	for zoom in [.65,.85,1.25]:
		scene.camera.zoom=Vector2.ONE*zoom;scene.snap_camera()
		var sample=scene.actor.position+Vector2(0,-45);var screen_point=scene.get_canvas_transform()*sample
		check(scene.pick(scene.get_canvas_transform().affine_inverse()*screen_point)==scene.actor,"NPC picking after camera transform")
		scene.select_target(null);var before_click: Vector2=scene.actor.position
		await click(screen_point)
		check(scene.selected==scene.actor,"real mouse event selects NPC after zoom")
		check(scene.actor.position.distance_to(before_click)<.01,"mouse selection never moves actor")
	var house=scene.props[0]
	await click(scene.get_canvas_transform()*(Space.project(house.footprint.end)+Vector2(15,-110)))
	check(scene.selected==house,"real mouse event selects visible house")
	check(not house.hit(house.sprite.to_global(Vector2(1,1))),"transparent roof corners cannot be selected")
	scene.actor.set_logical(Vector2(2.8,1.65));scene.update_depth()
	check(scene.pick(scene.actor.position+Vector2(0,-45))==house,"occluding roof intercepts selection of hidden actor")
	var foot=scene.actor.sprite.position+(Vector2(scene.actor.sprite.texture.get_width()/2.0,scene.actor.sprite.texture.get_height())*scene.actor.sprite.scale).rotated(scene.actor.sprite.rotation)
	check(foot.length()<.01,"animation remains anchored at feet")
	scene.queue_free();await process_frame
	check(InputMap.get_actions()==initial_actions,"prototype input actions cleaned up")
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/main.tscn","original main scene retained")
	print("ISOMETRIC_PROTOTYPE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
