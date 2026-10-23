extends SceneTree
const QI = preload("res://scripts/inner_qi.gd")
var failed := false
var game
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("QI: " + message)
func wait_turn() -> void:
	var deadline = Time.get_ticks_msec() + 7000
	while game.battle.busy and Time.get_ticks_msec() < deadline:
		await create_timer(0.04).timeout
	check(not game.battle.busy, "action completes")
func run() -> void:
	var resource = QI.new()
	resource.start(100)
	check(resource.amount == 100, "start with inner power, not full capacity")
	for i in range(10): resource.recover_turn()
	check(resource.amount == 500, "maximum 500")
	check(resource.spend(500) and resource.amount == 0, "exact cost can exhaust resource")
	check(not resource.spend(1) and not resource.spend(-1) and resource.amount == 0, "insufficient or negative costs cannot change resource")
	resource.start(0)
	resource.recover_turn()
	check(resource.amount == 0 and resource.spend(0), "zero inner power and free action")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_battle()
	var battle = game.battle
	check(battle.qi.amount == 10 and battle.qi.inner_power == 10, "first turn has one starting allocation")
	battle.select_samjae()
	battle.select_samjae()
	check(battle.qi.amount == 10, "preview does not spend or regenerate")
	# Temporary test cost only, not a new canon cost for Samjae.
	battle.skill_qi_costs.samjae = 11
	battle.use_selected()
	check(not battle.busy and battle.turn == 1 and battle.qi.amount == 10 and battle.enemy_hp == 150, "insufficient qi does not consume a turn or attack")
	battle.skill_qi_costs.samjae = 7
	battle.use_selected()
	battle.use_selected()
	check(battle.qi.amount == 3 and not battle.try_spend_qi(1), "cost is paid exactly once and busy actions cannot pay again")
	await wait_turn()
	check(battle.turn == 2 and battle.qi.amount == 13, "regenerate once at next player turn")
	check(game.save_system.write_slot(1), "save qi mid-battle")
	battle.skill_qi_costs.clear()
	check(game.save_system.load_slot(1), "load qi mid-battle")
	check(battle.qi.amount == 13 and battle.turn == 2 and battle.qi.inner_power == 10, "load preserves spent qi without bonus regeneration")
	battle.enemy_hp = 1
	battle.select_samjae()
	battle.use_selected()
	await wait_turn()
	check(battle.qi.amount == 13, "victory has no extra turn recovery")
	battle.begin(100)
	battle.qi.restore(100, 490)
	battle.select_samjae()
	battle.use_selected()
	await wait_turn()
	check(battle.qi.amount == 500, "actual turn recovery clamps to cap")
	game.start_battle()
	check(battle.qi.amount == 10, "next battle resets to inner power instead of carrying qi")
	# Old manual slot schema predates qi: no historical costs, so reconstruct elapsed turns.
	var old = game.save_system.capture()
	old.schema = 1
	old.battle.erase("qi")
	old.battle.erase("inner_power")
	old.battle.turn = 4
	var file = FileAccess.open(game.save_system.path(2), FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	check(game.save_system.load_slot(2) and battle.qi.amount == 40, "legacy combat save remains usable")
	game.reset()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_INNER_QI: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
