extends SceneTree
func _initialize() -> void:run.call_deferred()
func shot(file: String) -> void:
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/wuchang-painted-"+file+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.alliance_visit.grant_visit()
	for spot in [["headquarters",[1480,430]],["inns",[740,850]],["market",[780,1215]],["workshops",[1500,1400]],["gate",[1480,930]]]:
		var w=game.exploration;w.player.position=w.safe_player_position(w.city_point(spot[1]));w.player.stop();w.camera.snap_to_player();await shot(spot[0])
		if spot[0]=="headquarters":
			w.camera.exploration_zoom=.55;w.camera.offset=Vector2(0,-540);w.camera.set_map_bounds(w.map_bounds);w.camera.snap_to_player();await shot("headquarters-wide")
			w.camera.exploration_zoom=.8;w.camera.offset=Vector2.ZERO;w.camera.set_map_bounds(w.map_bounds);w.camera.snap_to_player()
	root.size=Vector2i(2560,1440);await shot("1440p")
	root.size=Vector2i(1536,1440);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;game.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(2048,1920);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/wuchang_map.gd").new();map.scale=Vector2.ONE/4;view.add_child(map)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	map.actors.hide();await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://assets/maps/wuchang/painted/overview-floor.png")==OK)
	map.actors.show();await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/wuchang-painted-full.png")==OK)
	view.queue_free();game.queue_free();await process_frame;print("WUCHANG_PAINTED_CAPTURE: PASS");quit()
