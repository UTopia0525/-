extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var picture = root.get_texture().get_image()
	assert(not picture.is_empty())
	assert(picture.save_png("res://screenshots/" + name + ".png") == OK)
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_city()
	# Screenshot-only funds; new games and exploration preview do not grant money.
	game.money = 3000
	for definition in game.exploration.city_data.services:
		var actor
		for npc in game.exploration.ambient_nodes:
			if npc.get_meta("npc_id") == definition.npc_id: actor = npc
		game.exploration.player.position = actor.position + Vector2(36, 12)
		game.exploration.camera.snap_to_player()
		game.interact()
		await shot("dialogue-" + str(definition.kind))
		while not game.dialogue_lines.is_empty(): game.advance_dialogue()
		var id: String = {"market":"bear_strength_pill", "workshop":"refined_sword", "training":"cheongpung"}[definition.kind]
		game.city_service.select_item(id)
		await shot("trading-" + str(definition.kind))
		game.city_service.close_counter()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("TRADING_CAPTURE: PASS")
	quit()
