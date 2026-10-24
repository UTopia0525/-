extends SceneTree
var scene
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	scene=load("res://scenes/wuchang.tscn").instantiate();root.add_child(scene);await process_frame
	await shot("wuchang-south-entry")
	scene.toggle_map();await shot("wuchang-overview");scene.toggle_map()
	for landmark in scene.city.data.landmarks:
		if landmark.id in ["alliance_gate","main_hall","training"]:
			scene.player.position=scene.city.point(landmark.point);scene.player.stop();scene.camera.snap_to_player()
			await shot("wuchang-"+landmark.id)
	# Export terrain and the exact prop layout at full art resolution, not a concept image.
	scene.atlas_view.size=Vector2i(scene.city.data.art_size[0],scene.city.data.art_size[1])
	scene.atlas_view.get_child(0).scale=Vector2.ONE*.25
	scene.atlas_view.render_target_update_mode=SubViewport.UPDATE_ONCE
	await create_timer(.5).timeout;await RenderingServer.frame_post_draw
	assert(scene.atlas_view.get_texture().get_image().save_png("res://screenshots/wuchang-full-map.png")==OK)
	scene.queue_free();await process_frame;quit()
