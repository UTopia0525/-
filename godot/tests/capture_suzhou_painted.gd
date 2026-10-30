extends SceneTree
func _initialize() -> void:run.call_deferred()
func shot(file: String) -> void:
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/suzhou-painted-"+file+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("suzhou");game.exploration.set_active(true)
	for spot in [["rice-shop",[425,225]],["grain-harbor",[1120,970]],["mill",[495,975]],["silk",[1125,765]],["canal",[768,512]]]:
		var w=game.exploration;w.player.position=w.safe_player_position(w.city_point(spot[1]));w.player.stop();w.camera.snap_to_player();await shot(spot[0])
	root.size=Vector2i(2560,1440);await shot("1440p")
	root.size=Vector2i(1536,1024);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;game.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/suzhou_map.gd").new("suzhou");map.scale=Vector2.ONE/3;view.add_child(map)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	map.actors.hide();await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://assets/maps/suzhou/painted/overview-floor.png")==OK)
	map.actors.show();await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/suzhou-painted-full.png")==OK)
	view.queue_free();game.queue_free();await process_frame;print("SUZHOU_PAINTED_CAPTURE: PASS");quit()
