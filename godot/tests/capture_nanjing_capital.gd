extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	game.exploration.load_area("nanjing");game.exploration.set_active(true)
	for district in [["market",[888,410]],["workshops",[420,470]],["commerce",[975,280]],["inn",[870,735]],["government",[1210,495]],["martial",[1200,715]],["waterfront",[1320,958]]]:
		game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point(district[1]));game.exploration.player.stop();game.exploration.camera.snap_to_player()
		await shot("nanjing-capital-"+str(district[0]))
	root.size=Vector2i(2560,1440)
	await shot("nanjing-capital-1440p")
	root.size=Vector2i(1536,1024);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	game.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/nanjing_map.gd").new();map.scale=Vector2.ONE/4;view.add_child(map)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/nanjing-capital-full.png")==OK)
	view.queue_free();game.queue_free();await process_frame;print("NANJING_CAPITAL_CAPTURE: PASS");quit()
