extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(1.5).timeout;await RenderingServer.frame_post_draw
	var frame=root.get_texture().get_image()
	assert(frame.save_png("res://screenshots/faction-favor-"+name+".png")==OK)
	if name=="five":assert(frame.save_png("res://screenshots/impostor-quest-favor.png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue"]);game.start_wuchang();await create_timer(.2).timeout
	game.adventure_ui.open_favor();await shot("empty");game.adventure_ui.close_menu()
	# UI fixtures only: actual story payout is covered by impostor_quest.gd.
	game.progress.add_favor("murim_alliance",5);game.adventure_ui.open_favor();await shot("five");game.adventure_ui.close_menu()
	game.progress.add_favor("murim_alliance",200);game.adventure_ui.open_favor();await shot("maximum");game.adventure_ui.close_menu()
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
