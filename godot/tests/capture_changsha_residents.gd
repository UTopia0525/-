extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.18).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue"]);game.start_city();await create_timer(.2).timeout
	var world=game.exploration
	game.toggle_city_map();await shot("changsha-residents-overview");game.toggle_city_map()
	var npc=world.decorations.get_node("vegetable_vendor");var path=world.path_to(npc.position,true)
	world.player.position=path[-1];world.player.stop();world.camera.snap_to_player();await shot("changsha-named-quest-npc")
	game.interact();await shot("changsha-named-quest-dialogue")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
