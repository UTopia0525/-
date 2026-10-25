extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.18).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();await create_timer(3.6).timeout
	var world=game.exploration
	for entry in world.city_data.residents:
		var npc=world.decorations.get_node(entry.id)
		var path=world.path_to(npc.position,true)
		assert(not path.is_empty())
		world.player.position=path[-1];world.player.stop();world.camera.snap_to_player();await process_frame
		await shot("wuchang-npc-"+str(entry.id).trim_prefix("wc_"))
		game.interact()
		if entry.id in ["wc_liu_baicao","wc_shi_dayong"]:game.adventure_ui.secondary_action()
		await shot("wuchang-dialogue-"+str(entry.id).trim_prefix("wc_"))
		while not game.dialogue_lines.is_empty():game.advance_dialogue()
		if game.city_service.visible:
			await shot("wuchang-counter-"+str(entry.id).trim_prefix("wc_"));game.city_service.close_counter()
	game.toggle_city_map();await shot("wuchang-residents-overview");game.toggle_city_map()
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
