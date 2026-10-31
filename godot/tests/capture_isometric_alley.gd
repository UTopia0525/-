extends SceneTree
var scene
func _initialize() -> void:run.call_deferred()
func shot(name: String,point: Vector2) -> void:
	scene.actor.set_logical(point);await physics_frame;await process_frame;scene.update_depth();scene.update_occlusion()
	await create_timer(.15).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/alley-"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await process_frame
	scene.follow=false;scene.camera.position=Vector2(0,290);scene.camera.zoom=Vector2.ONE*.75;scene.camera.force_update_scroll()
	await shot("overview",Vector2(4.72,8.4))
	scene.camera.position=Vector2(-85,290);scene.camera.zoom=Vector2.ONE*1.05;scene.camera.force_update_scroll()
	await shot("gate-front",Vector2(4.72,7.15))
	await shot("gate-under",Vector2(4.72,6.5))
	await shot("gate-back",Vector2(4.72,5.95))
	await shot("hidden",Vector2(2.8,1.65))
	scene.show_occlusion_hint=false;await shot("hidden-no-hint",Vector2(2.8,1.65));scene.show_occlusion_hint=true
	scene.debug_footprints=true;scene.queue_redraw()
	for prop in scene.props:prop.debug_footprint=true;prop.queue_redraw()
	await shot("collision",Vector2(4.72,6.5))
	scene.debug_footprints=false;scene.queue_redraw()
	for prop in scene.props:prop.debug_footprint=false;prop.queue_redraw()
	scene.follow=true;scene.camera.zoom=Vector2.ONE*.85;scene.reset_actor();scene.snap_camera();await shot("play",Vector2(4.72,8.4))
	root.size=Vector2i(2560,1440);await process_frame;scene.snap_camera();await shot("1440p",Vector2(4.72,8.4))
	scene.queue_free();await process_frame;print("ISOMETRIC_ALLEY_CAPTURE: PASS");quit()
