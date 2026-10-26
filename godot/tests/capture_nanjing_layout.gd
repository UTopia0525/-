extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1536,1024);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var view=SubViewport.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/nanjing_map.gd").new();map.scale=Vector2.ONE/4;view.add_child(map)
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/nanjing-full.png")==OK)
	view.queue_free();await process_frame;quit()
