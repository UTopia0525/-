extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func drain() -> void:
	var limit := 0
	while not game.dialogue_lines.is_empty() and limit < 300:
		game.advance_dialogue()
		limit += 1
	assert(limit < 300)
func run() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for branch in ["treasure", "rescue"]:
		game.start_story()
		drain()
		game.exploration.player.position = Vector2(640, 395)
		game.interact()
		drain()
		game.exploration.player.position = Vector2(810, 410)
		game.interact()
		drain()
		game.exploration.player.position = Vector2(715, 365)
		game.interact()
		drain()
		game.battle.select_samjae()
		for i in range(4):
			game.battle.use_selected()
			var deadline = Time.get_ticks_msec() + 10000
			while game.battle.busy and Time.get_ticks_msec() < deadline:
				await create_timer(0.05).timeout
			assert(Time.get_ticks_msec() < deadline)
		drain()
		assert(game.state == "choice")
		if branch == "treasure": await capture("prologue-choice")
		game.select_story_choice(branch)
		game.confirm_story_choice()
		var delivered := false
		var count := 0
		while not game.dialogue_lines.is_empty() and count < 300:
			if not delivered and game.exploration.area_name == "changsha":
				delivered = true
				await capture("prologue-" + branch + "-delivery")
			if game.dialogue_text.text.begins_with("장사 항구인가"):
				await capture("prologue-" + branch + "-port-dialogue")
			game.advance_dialogue()
			count += 1
		assert(game.prologue.completed)
		await capture("prologue-" + branch + "-free-roam")
	await create_timer(1).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("PROLOGUE_CAPTURE: PASS")
	quit()
func capture(filename: String) -> void:
	await create_timer(0.15).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var picture = root.get_texture().get_image()
	assert(not picture.is_empty())
	assert(picture.save_png("res://screenshots/" + filename + ".png") == OK)
