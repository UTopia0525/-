extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	for id in ["wuchang","changsha-wuchang"]:
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/"+id+"/layout.json"))
		var viewport=SubViewport.new();viewport.world_2d=World2D.new();viewport.size=Vector2i(data.art_size[0],data.art_size[1]);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var ground=load("res://scripts/"+("wuchang_ground.gd" if id=="wuchang" else "mountain_road_ground.gd")).new();ground.data=data;viewport.add_child(ground)
		await create_timer(.3).timeout;await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png("res://assets/maps/"+id+"/ground.png")==OK)
		viewport.queue_free();await process_frame
	quit()
