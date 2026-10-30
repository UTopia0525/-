extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var tag="before" if "before" in OS.get_cmdline_user_args() else "after"
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	game.exploration.load_area("nanjing");game.exploration.set_active(true)
	var locations=[["market",[888,410]],["alley",[888,360]]]
	if tag=="after":locations.append(["front",[888,410]])
	for location in locations:
		var world=game.exploration
		var point=world.city_point(location[1])
		assert(world.can_stand(point),"Comparison camera point must remain walkable")
		world.player.position=point;world.player.facing="down" if location[0]=="front" else "up";world.player.stop();world.camera.snap_to_player()
		for resolution in [Vector2i(1280,720),Vector2i(2560,1440)]:
			root.size=resolution
			await create_timer(.3).timeout;await RenderingServer.frame_post_draw
			var file="res://screenshots/nanjing-market-"+tag+"-"+str(location[0])+"-"+str(resolution.y)+".png"
			assert(root.get_texture().get_image().save_png(file)==OK)
	game.queue_free();await process_frame;print("MARKET_SLICE_CAPTURE: "+tag+" PASS");quit()
