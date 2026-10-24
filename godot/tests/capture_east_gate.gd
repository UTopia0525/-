extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	for spec in [[Vector2i(2048,1920),.25,Vector2.ZERO,"wuchang-full-map"],[Vector2i(1000,1080),1.0,Vector2(-7200,-3040),"wuchang-east-gate"],[Vector2i(1200,1080),.75,Vector2(-4650,-2760),"wuchang-government-walls"]]:
		var view=SubViewport.new();view.world_2d=World2D.new();view.size=spec[0];view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
		var map=load("res://scripts/wuchang_map.gd").new();map.scale=Vector2.ONE*spec[1];map.position=spec[2];view.add_child(map)
		await create_timer(.4).timeout;await RenderingServer.frame_post_draw
		assert(view.get_texture().get_image().save_png("res://screenshots/"+spec[3]+".png")==OK)
		view.free();await process_frame
	var game=load("res://scenes/main.tscn").instantiate();root.size=Vector2i(1280,720);root.add_child(game);await process_frame;game.options.seen.append("city");game.start_wuchang()
	game.exploration.player.position=game.exploration.city_point([1949,945]);game.exploration.player.stop();game.exploration.camera.snap_to_player()
	await create_timer(.4).timeout;game.adventure_ui.toast.hide();await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/wuchang-east-gate-passage.png")==OK)
	game.reset();await create_timer(.2).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
