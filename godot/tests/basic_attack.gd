extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.
var failed := false
var game
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("BASIC_ATTACK: " + message)
func wait_turn() -> void:
	var deadline = Time.get_ticks_msec() + 7000
	while game.battle.busy and Time.get_ticks_msec() < deadline:
		await create_timer(0.04).timeout
	check(not game.battle.busy, "action completes")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_battle()
	var battle = game.battle
	var slots = battle.basic_button.get_parent()
	var buttons := 0
	var empty := 0
	for child in slots.get_children():
		if child is Button:
			buttons += 1
			if child.text == "—" and child.disabled: empty += 1
	check(buttons == 4 and empty == 1, "basic attack, defense, Samjae and an empty slot")
	check(battle.basic_button.position == Vector2(18, 40), "basic attack occupies first slot")
	for weapon in ["none", "sword", "saber", "spear"]:
		battle.equip_weapon(weapon)
		battle.qi.restore(10, 0)
		battle.select_basic_attack()
		check(not battle.use_button.disabled and battle.basic_attack_damage() == 30 and battle.current_qi_cost("basic_attack") == 0, "free basic attack with " + weapon)
	battle.equip_weapon_item("hundredfold_sword")
	check(battle.basic_attack_damage() == 30, "weapon skill bonus does not alter fixed basic formula")
	battle.equip_weapon("none")
	battle.use_selected()
	battle.use_selected()
	battle.select_samjae()
	check(battle.busy and battle.selected_action == "basic_attack" and battle.qi.amount == 0, "busy blocks duplicate attacks and switching")
	await wait_turn()
	check(battle.enemy_hp == 127 and battle.player_hp == 282 and battle.turn == 2, "raw 30 becomes 23 damage and enemy responds once")
	check(battle.qi.amount == 10 and battle.selected_action == "basic_attack", "normal turn recovery and preserved selection")
	battle.use_selected()
	await wait_turn()
	check(battle.qi.amount == 20 and battle.enemy_hp == 104, "repeated basic attacks bank qi without changing damage")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1), "save selected basic attack")
	battle.select_samjae()
	check(game.save_system.load_slot(1), "load basic attack")
	check(battle.selected_action == "basic_attack" and battle.basic_button.button_pressed and not battle.use_button.disabled and battle.qi.amount == 20, "selection and banked qi restored without extra recovery")
	var legacy = game.save_system.capture()
	legacy.battle.erase("selected_action")
	var file = FileAccess.open(game.save_system.path(2), FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(game.save_system.load_slot(2) and battle.selected_action == "samjae", "old selected flag remains Samjae")
	check(battle.use_button.disabled, "legacy Samjae still requires sword")
	battle.select_basic_attack()
	battle.qi.restore(10, 500)
	battle.use_selected()
	await wait_turn()
	check(battle.qi.amount == 500, "basic recovery respects cap")
	game.reset()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_BASIC_ATTACK: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
