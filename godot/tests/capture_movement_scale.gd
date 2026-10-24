extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city()
	for npc in game.exploration.ambient_nodes:
		if npc.name=="city_merchant":game.exploration.player.position=npc.position+Vector2(76,0)
	game.exploration.player.stop();game.exploration.camera.snap_to_player();await shot("movement-scale-market")
	for node in game.exploration.scenery_nodes:
		if node.name=="government_gate":
			game.exploration.player.position=node.position+Vector2(0,75);game.exploration.player.stop();game.exploration.camera.snap_to_player()
	await shot("movement-scale-gate")
	game.start_story()
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	game.exploration.camera.snap_to_player();await shot("movement-scale-dock")
	game.reset();await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
