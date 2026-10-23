extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://screenshots")
	game.start_story()
	while not game.dialogue_lines.is_empty(): game.advance_dialogue()
	await _capture("exploration")
	game.exploration.player.position = Vector2(595, 420)
	game.interact()
	await _capture("dialogue")
	while not game.dialogue_lines.is_empty(): game.advance_dialogue()
	game.exploration.player.position = Vector2(810, 410)
	game.interact()
	while not game.dialogue_lines.is_empty(): game.advance_dialogue()
	await _capture("deck")
	game.start_battle()
	game.battle.select_samjae()
	await _capture("battle")
	game.queue_free()
	await process_frame
	print("GODOT_CAPTURE: PASS")
	quit()

func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("A graphical display is required for captures.")
		quit(1)
		return
	var result = image.save_png("res://screenshots/%s.png" % filename)
	if result != OK:
		push_error("Screenshot save failed: %s" % result)
		quit(1)
