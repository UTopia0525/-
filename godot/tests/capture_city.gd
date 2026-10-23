extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_city()
	await create_timer(0.3).timeout
	await _capture("changsha-exploration")
	game.exploration.player.position = game.exploration.city_point([515, 440])
	game.exploration.player.stop()
	game.exploration.camera.snap_to_player()
	await create_timer(0.2).timeout
	await _capture("changsha-market-ui-revised")
	game.toggle_city_map()
	await _capture("changsha-overview")
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("CHANGSHA_CAPTURE: PASS")
	quit()

func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture = root.get_texture().get_image()
	assert(picture != null and not picture.is_empty(), "Graphical display required")
	assert(picture.save_png("res://screenshots/" + filename + ".png") == OK)
