extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	for spec in [[Vector2i(2048,1920),.25,Vector2.ZERO,"wuchang-full-map"],[Vector2i(1200,1080),.75,Vector2(-4650,-2760),"wuchang-government-walls"]]:
		var view=SubViewport.new();view.world_2d=World2D.new();view.size=spec[0];view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
		var map=load("res://scripts/wuchang_map.gd").new();map.scale=Vector2.ONE*spec[1];map.position=spec[2];view.add_child(map)
		await create_timer(.4).timeout;await RenderingServer.frame_post_draw
		assert(view.get_texture().get_image().save_png("res://screenshots/"+spec[3]+".png")==OK)
		view.free();await process_frame
	quit()
