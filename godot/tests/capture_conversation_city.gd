extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city()
	var city=game.exploration
	for npc in city.ambient_nodes:
		if npc.name=="city_merchant":
			city.player.position=npc.position+Vector2(75,35);city.player.stop();city.camera.snap_to_player()
	await shot("layered-city-market")
	game.toggle_city_map();await shot("layered-city-overview");game.toggle_city_map()
	for node in city.scenery_nodes:
		if node.name!="government_gate":continue
		var foot: Vector2=node.position
		city.player.position=foot+Vector2(0,55);city.player.stop();city.camera.snap_to_player()
		await shot("layered-gate-front")
		city.player.position=foot-Vector2(0,102);city.player.stop();city.camera.snap_to_player()
		await shot("layered-gate-under")
		city.player.position=foot-Vector2(0,220);city.player.stop();city.camera.snap_to_player()
		await shot("layered-gate-behind")
	game.say([["captain","표행에 나서거든, 제 짐보다 동료의 안위를 먼저 살피거라."],["sailor","표두님 말씀이 맞소. 강물은 물건도 사람도 가려 주지 않으니."],["hero","명심하겠습니다. 함께 돌아오는 일이 먼저겠지요."]])
	game.dialogue_index=1;game._show_line();await shot("conversation-unique-faces")
	game.dialogue_index=2;game._show_line();game.dialogue_history.open_history()
	# Timers continue while the history intentionally pauses the world.
	await shot("conversation-history")
	game.dialogue_history.close_history();game.reset();await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
