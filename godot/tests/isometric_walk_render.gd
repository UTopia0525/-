extends SceneTree
var scene
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ISO_WALK_RENDER: "+message)
func rendered() -> Image:
	await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func differences(a: Image,b: Image,rect: Rect2i) -> int:
	var changed=0
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if a.get_pixel(x,y)!=b.get_pixel(x,y):changed+=1
	return changed
func run() -> void:
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await process_frame
	scene.patrols_enabled=false;scene.follow=false;scene.actor.set_physics_process(false)
	for i in range(scene.npcs.size()):scene.npcs[i].set_logical(Vector2(10,10+i))
	scene.actor.set_logical(Vector2(4.72,8.4));scene.camera.position=scene.actor.position-Vector2(0,30);scene.camera.zoom=Vector2.ONE;scene.camera.force_update_scroll()
	var foot: Vector2=scene.get_canvas_transform()*scene.actor.position
	var body=Rect2i(Vector2i(foot+Vector2(-16,-88)),Vector2i(32,42))
	var feet=Rect2i(Vector2i(foot+Vector2(-40,-30)),Vector2i(80,45))
	var sash=Rect2i(Vector2i(foot+Vector2(-14,-53)),Vector2i(28,29))
	for key in ["front","back"]:
		for flip in [false,true]:
			scene.actor.moving=true;scene.actor.phase=0;scene.actor.set_pose(key,flip);var contact=await rendered()
			scene.actor.phase=PI/2;scene.actor.set_pose(key,flip);var passing=await rendered()
			scene.actor.phase=PI;scene.actor.set_pose(key,flip);var opposite=await rendered()
			scene.actor.phase=PI*1.5;scene.actor.set_pose(key,flip);var other_passing=await rendered()
			var body_changes=differences(contact,passing,body);var step_changes=differences(passing,other_passing,feet)
			var left_arm=Rect2i(Vector2i(foot+Vector2(-36,-70)),Vector2i(24,48))
			var right_arm=Rect2i(Vector2i(foot+Vector2(12,-70)),Vector2i(24,48))
			var arms=differences(contact,opposite,left_arm)+differences(contact,opposite,right_arm)
			print("POSE "+key+str(flip)+" | bob changed pixels="+str(body_changes)+" | knee/foot="+str(step_changes)+" | arm="+str(arms))
			check(body_changes>40,"rendered body rises and falls")
			check(step_changes>60,"rendered alternating bent knees and feet")
			check(arms>60,"rendered arms swing in opposite contacts")
			check(scene.actor.sprite.scale==scene.actor.base_scale,"body movement never changes scale")
	print("ISOMETRIC_WALK_RENDER: "+("FAIL" if failed else "PASS"))
	scene.queue_free();await process_frame;quit(1 if failed else 0)
