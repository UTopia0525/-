extends SceneTree

const Rules = preload("res://scripts/rules.gd")
var game
var failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("TEST FAILURE: " + message)

func _run() -> void:
	check(Rules.damage(50, 5) == 42, "player damage")
	check(Rules.damage(40, 10) == 27, "enemy damage")
	check(Rules.damage(100, 100) == 0, "weak attacks can be blocked completely")
	for boundary in [[99, "명칭 미정"], [100, "절정"], [200, "초절정"], [300, "화경"], [400, "현경"], [500, "자연경"]]:
		check(Rules.realm(boundary[0]) == boundary[1], "realm boundary")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.state == "title", "title state")
	check(game.music.current_track == "title", "title music")
	check(game.music.TRACKS.size() == 5, "five original BGM tracks")
	for stream in game.music.TRACKS.values():
		check(absf(stream.get_length() - 60.0) < 0.01, "60-second BGM length")
	check(game.music.players[game.music.current_index].stream.loop, "native music looping")
	game.music.set_enabled(false)
	check(game.music.players[game.music.current_index].stream_paused, "music mute")
	game.music.set_enabled(true)
	game.start_story()
	while not game.dialogue_lines.is_empty(): game.advance_dialogue()
	check(game.exploration.active, "movement enabled after dialogue")
	check(game.music.current_track == "dock", "dock music")
	var player = game.exploration.player
	check(player.sprite is AnimatedSprite2D, "native frame animation")
	for direction in ["down", "left", "right", "up"]:
		check(player.sprite.sprite_frames.get_frame_count("walk_" + direction) == 4, "four registered poses per direction")
		player.position = Vector2(420, 460)
		player.stop()
		Input.action_press("move_" + direction)
		await create_timer(0.18).timeout
		check(player.sprite.animation == "walk_" + direction, "walk animation follows direction")
		var frame_before = player.sprite.frame
		await create_timer(0.18).timeout
		check(player.sprite.frame != frame_before, "walking advances frames")
		Input.action_release("move_" + direction)
		await create_timer(0.04).timeout
		check(player.sprite.animation == "idle_" + direction, "release returns to directional idle")
	player.position = Vector2(370, 510)
	check(not game.top_hud.get_children().is_empty(), "exploration HUD")
	var origin = Vector2i(game.exploration.player.position / 20.0)
	check(not game.exploration.astar.get_point_path(origin, Vector2i(40, 20)).is_empty(), "dock to boarding is reachable")
	var before_click = game.exploration.player.position
	var click = InputEventMouseButton.new()
	click.position = game.exploration.get_global_transform_with_canvas() * Vector2(490, 510)
	click.global_position = click.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	await create_timer(0.25).timeout
	check(game.exploration.player.position.distance_to(before_click) > 10.0, "click movement passes through HUD")
	game.exploration.player.stop()
	game.exploration.player.position = Vector2(110, 400)
	Input.action_press("move_left")
	await create_timer(0.5).timeout
	Input.action_release("move_left")
	check(game.exploration.player.position.x >= 90, "native collision prevents walking into water")
	game.exploration.player.position = Vector2(640, 395)
	game.interact()
	while not game.dialogue_lines.is_empty():
		game.advance_dialogue()
	check(game.talked_captain, "captain dialogue")
	check(String(player.sprite.animation).begins_with("idle_"), "dialogue stops walking animation")
	game.exploration.player.position = Vector2(810, 410)
	game.interact()
	while not game.dialogue_lines.is_empty(): game.advance_dialogue()
	check(game.exploration.area_name == "deck", "boarding changes map")
	check(game.music.current_track == "voyage", "voyage music")
	check(game.exploration.active, "deck movement")
	check(not game.exploration.astar.get_point_path(Vector2i(game.exploration.player.position / 20.0), Vector2i(35, 18)).is_empty(), "deck captain is reachable")
	game.exploration.player.position = Vector2(715, 365)
	game.interact()
	var heard_warning := false
	while not game.dialogue_lines.is_empty():
		if game.music.current_track == "ambush": heard_warning = true
		game.advance_dialogue()
	check(heard_warning, "tension music on pirate warning")
	check(game.music.current_track == "battle", "battle music")
	check(game.state == "battle", "ambush transitions into battle")
	check(game.battle.player_hp == 300 and game.battle.enemy_hp == 150, "fresh battle HP")
	game.battle.select_samjae()
	check(game.battle.enemy_hp == 150, "preview does not attack")
	game.battle.use_selected()
	game.battle.use_selected()
	game.battle.use_selected()
	await _wait_for_turn()
	check(game.battle.enemy_hp == 108 and game.battle.player_hp == 286, "single action despite repeated input")
	for index in range(4):
		game.battle.use_selected()
		await _wait_for_turn()
	check(game.state == "story", "victory continues the full prologue")
	check(game.battle.player_hp == 244 and game.battle.enemy_hp == 0, "enemy defense lengthens battle; sword guard reduces counters")
	game.start_battle()
	check(game.battle.player_hp == 300 and game.battle.enemy_hp == 150, "retry restores condition")
	game.battle.select_samjae()
	game.battle.use_selected()
	game.reset()
	await create_timer(1.4).timeout
	check(game.state == "title", "reset cancels pending attack")
	check(game.music.current_track == "title", "reset restores title music")
	var active_voices = 0
	for voice in game.music.players:
		if voice.playing:
			active_voices += 1
	check(active_voices == 1, "crossfade stops previous track")
	# Allow the audio mixing thread to release its last loop before test exit.
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_SMOKE: " + ("FAIL" if failed else "PASS — animation, BGM contexts/loops/mute, story, navigation, physics, combat, reset, realms"))
	quit(1 if failed else 0)

func _wait_for_turn() -> void:
	var deadline = Time.get_ticks_msec() + 7000
	while game.battle.busy and Time.get_ticks_msec() < deadline:
		await create_timer(0.04).timeout
	check(not game.battle.busy, "battle turn completes")
