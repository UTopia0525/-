extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var picture = root.get_texture().get_image()
	assert(not picture.is_empty())
	assert(picture.save_png("res://screenshots/" + name + ".png") == OK)
func drain() -> void:
	while not game.dialogue_lines.is_empty(): game.advance_dialogue()
func run() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_city()
	# Fixture: emulate an eligible chapter-one save without granting new-game growth.
	game.chapter_number = 1
	game.chapter_one.intro_started = true
	game.chapter_one.intro_complete = true
	game.chapter_one.banner_shown = true
	game.progress.stats = {"strength":20, "agility":20, "constitution":20, "inner":20, "insight":20}
	game.progress.learned.append("cheongpung")
	game.progress.assign("cheongpung", 1)
	game.exploration.player.position = game.exploration.city_point([1048, 447])
	game.exploration.camera.snap_to_player()
	game.bandit_story.maybe_start()
	await shot("bandit-notice")
	drain()
	game.bandit_story.handle_interaction("bandit_officer")
	for i in range(4): game.advance_dialogue()
	await shot("bandit-enrollment")
	drain()
	game.bandit_story.handle_interaction("bandit_muster")
	drain()
	game.battle.select_skill("cheongpung")
	await shot("bandit-battle")
	# Capture the report/settlement UI independently of combat duration.
	game.battle.cancel()
	game.bandit_story.after_victory()
	await shot("bandit-between-battles")
	game.dialogue_lines.clear()
	game.bandit_story._return_to_city()
	game.exploration.player.position = game.exploration.city_point([1048, 447])
	game.exploration.camera.snap_to_player()
	game.bandit_story.handle_interaction("bandit_officer")
	while game.bandit_story.stage == "settlement": game.advance_dialogue()
	assert(game.money == 500 and game.progress.fame == 5 and game.progress.stats.insight == 25)
	assert(game.story_caption.text.contains("보수500문"))
	await shot("bandit-completed")
	drain()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("BANDIT_CAPTURE: PASS")
	quit()
