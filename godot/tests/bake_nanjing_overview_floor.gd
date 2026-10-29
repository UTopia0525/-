extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var view=SubViewport.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var floor=load("res://scripts/nanjing_ground.gd").new();floor.data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/nanjing/layout.json"));view.add_child(floor)
	await create_timer(.35).timeout
	for i in range(3):await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://assets/maps/nanjing/painted/overview-floor.png")==OK)
	view.queue_free();await process_frame;quit()
