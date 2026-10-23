extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("WEAPONS: " + message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_battle()
	var b = game.battle
	b.select_samjae()
	check(b.equipped_weapon_type == "sword" and not b.use_button.disabled, "tutorial begins with sword")
	for weapon in ["none", "saber", "spear"]:
		check(b.equip_weapon(weapon), "known equipment type")
		check(b.use_button.disabled, "mismatched weapon disables use but allows preview")
		b.use_selected()
		check(b.qi.amount == 10 and b.enemy_hp == 150 and b.turn == 1 and not b.busy, "wrong weapon cannot spend qi, damage or consume turn")
	check(not b.equip_weapon("unknown") and b.equipped_weapon_type == "spear", "unknown type rejected")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1), "save equipment category")
	game.reset()
	check(game.save_system.load_slot(1) and b.equipped_weapon_type == "spear" and b.use_button.disabled, "restored mismatch remains blocked")
	var old = game.save_system.capture()
	old.battle.erase("weapon_type")
	old.battle.erase("weapon_id")
	var file = FileAccess.open(game.save_system.path(2), FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	check(game.save_system.load_slot(2) and b.equipped_weapon_type == "sword" and not b.use_button.disabled, "legacy saves retain tutorial sword")
	check(b.note.text.contains("필요 무기: 검"), "weapon requirement shown in preview")
	game.reset()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_WEAPON_REQUIREMENTS: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
