extends SceneTree
var scene
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.18).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await process_frame
	scene.follow=false;scene.camera.position=Vector2(0,310);scene.camera.zoom=Vector2.ONE*.72;scene.camera.force_update_scroll()
	await shot("overview")
	scene.camera.position=Vector2(0,185);scene.camera.zoom=Vector2.ONE*.95;scene.camera.force_update_scroll()
	for spot in [["behind",Vector2(2.8,1.65)],["front",Vector2(3.1,5.4)],["side",Vector2(4.4,3.5)]]:
		scene.actor.set_logical(spot[1]);scene.select_target(scene.actor);await process_frame;scene.update_depth();await shot(spot[0])
	scene.debug_footprints=true;scene.queue_redraw()
	for prop in scene.props:prop.debug_footprint=true;prop.queue_redraw()
	await shot("footprints")
	scene.debug_footprints=false;scene.queue_redraw()
	for prop in scene.props:prop.debug_footprint=false;prop.queue_redraw()
	scene.reset_actor();scene.follow=true;scene.camera.zoom=Vector2.ONE*.85;scene.select_target(null);scene.snap_camera();await shot("play")
	root.size=Vector2i(2560,1440);await process_frame;scene.snap_camera();await shot("1440p")
	scene.queue_free();await process_frame;print("ISOMETRIC_CAPTURE: PASS");quit()
