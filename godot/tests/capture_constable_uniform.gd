extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue"]);game.start_city()
	await create_timer(3.6).timeout
	# Use the existing recruitment dialogue and callback without rewriting story data.
	game.bandit_story.play("notice",game.bandit_story._notice_done)
	await shot("constable-uniform-recruitment")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
