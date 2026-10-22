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
	game.start_story()
	game.advance_dialogue()
	check(game.exploration.active, "movement enabled after dialogue")
	check(not game.top_hud.get_children().is_empty(), "exploration HUD")
	var origin = Vector2i(game.exploration.player.position / 20.0)
	check(not game.exploration.astar.get_point_path(origin, Vector2i(40, 20)).is_empty(), "dock to boarding is reachable")
	var before_click = game.exploration.player.position
	var click = InputEventMouseButton.new()
	click.position = Vector2(490, 510)
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
	for index in range(3):
		game.advance_dialogue()
	check(game.talked_captain, "captain dialogue")
	game.exploration.player.position = Vector2(810, 410)
	game.interact()
	game.advance_dialogue()
	check(game.exploration.area_name == "deck", "boarding changes map")
	check(game.exploration.active, "deck movement")
	check(not game.exploration.astar.get_point_path(Vector2i(game.exploration.player.position / 20.0), Vector2i(35, 18)).is_empty(), "deck captain is reachable")
	game.exploration.player.position = Vector2(715, 365)
	game.interact()
	for index in range(4):
		game.advance_dialogue()
	check(game.state == "battle", "ambush transitions into battle")
	check(game.battle.player_hp == 300 and game.battle.enemy_hp == 150, "fresh battle HP")
	game.battle.select_samjae()
	check(game.battle.enemy_hp == 150, "preview does not attack")
	game.battle.use_selected()
	game.battle.use_selected()
	game.battle.use_selected()
	await _wait_for_turn()
	check(game.battle.enemy_hp == 108 and game.battle.player_hp == 273, "single action despite repeated input")
	for index in range(3):
		game.battle.use_selected()
		await _wait_for_turn()
	check(game.state == "end", "victory")
	check(game.battle.player_hp == 219 and game.battle.enemy_hp == 0, "four hits and three counters")
	game.start_battle()
	check(game.battle.player_hp == 300 and game.battle.enemy_hp == 150, "retry restores condition")
	game.battle.select_samjae()
	game.battle.use_selected()
	game.reset()
	await create_timer(1.4).timeout
	check(game.state == "title", "reset cancels pending attack")
	game.queue_free()
	await process_frame
	print("GODOT_SMOKE: " + ("FAIL" if failed else "PASS — story, navigation, physics, preview, combat, retry, reset, realms"))
	quit(1 if failed else 0)

func _wait_for_turn() -> void:
	var deadline = Time.get_ticks_msec() + 7000
	while game.battle.busy and Time.get_ticks_msec() < deadline:
		await create_timer(0.04).timeout
	check(not game.battle.busy, "battle turn completes")
