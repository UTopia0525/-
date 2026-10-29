extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func drain() -> void:
	var limit := 0
	while not game.dialogue_lines.is_empty() and limit < 350:
		game.advance_dialogue()
		limit += 1
	assert(limit < 350)
func store(slot: int) -> void:
	game.settings_menu.open_menu()
	game.settings_menu.set_mode("save")
	game.settings_menu.select_slot(slot)
	game.settings_menu.perform_action()
func run() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_story()
	drain()
	game.exploration.load_area("deck")
	game.prologue.after_victory()
	drain()
	store(1)
	await capture("save-slots-choice")
	game.settings_menu.close_menu()
	game.select_story_choice("treasure")
	game.confirm_story_choice()
	var count := 0
	while game.money == 0 and count < 200:
		game.advance_dialogue()
		count += 1
	assert(game.money == 500)
	drain()
	if game.state == "chapter_transition": await create_timer(2.6).timeout
	store(2)
	game.settings_menu.close_menu()
	drain()
	if game.state == "chapter_transition": await create_timer(2.6).timeout
	store(3)
	game.settings_menu.set_mode("load")
	game.settings_menu.select_slot(1)
	await capture("load-slots")
	game.settings_menu.request_action()
	await capture("load-confirmation")
	game.settings_menu.close_menu()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("SAVE_CAPTURE: PASS")
	quit()
func capture(filename: String) -> void:
	await create_timer(0.15).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var picture = root.get_texture().get_image()
	assert(not picture.is_empty())
	assert(picture.save_png("res://screenshots/" + filename + ".png") == OK)
