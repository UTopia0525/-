extends SceneTree
func _initialize() -> void:run.call_deferred()
func shot(file: String) -> void:
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/hangzhou-painted-"+file+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("hangzhou");game.exploration.set_active(true)
	for spot in [["tower",[785,425]],["market",[1315,670]],["slums",[1450,1135]],["warehouse",[1610,218]],["cruise",[460,515]],["workshops",[755,1100]]]:
		var w=game.exploration;w.player.position=w.safe_player_position(w.city_point(spot[1]));w.player.stop();w.camera.snap_to_player();await shot(spot[0])
	root.size=Vector2i(2560,1440);await shot("1440p")
	# Wider architectural view is labelled separately; normal gameplay remains0.8.
	root.size=Vector2i(1280,720);game.exploration.camera.exploration_zoom=.45;game.exploration.camera.set_focus_height(600);game.exploration.camera.set_map_bounds(game.exploration.map_bounds)
	game.exploration.player.position=game.exploration.city_point([785,425]);game.exploration.camera.snap_to_player();await shot("tower-wide")
	root.size=Vector2i(1760,1280);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;game.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1760,1280);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/hangzhou_map.gd").new();map.scale=Vector2.ONE/3.2;view.add_child(map)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	map.actors.hide();await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://assets/maps/hangzhou/painted/overview-floor.png")==OK)
	map.actors.show();await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/hangzhou-painted-full.png")==OK)
	view.queue_free();game.queue_free();await process_frame;print("HANGZHOU_PAINTED_CAPTURE: PASS");quit()
