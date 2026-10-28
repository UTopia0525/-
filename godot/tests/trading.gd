extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.
var failed := false
var game
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	if not ok:
		failed = true
		push_error("TRADING: " + text)
func counter(id: String) -> void:
	for definition in game.exploration.city_data.services:
		if definition.id == id:
			game.state = "service"
			game.city_service.open_counter(definition)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_city()
	var p = game.progress
	var shop = game.city_service
	game.money = 299
	counter("city_artisan")
	shop.select_item("refined_sword")
	check(shop.action.disabled, "insufficient funds disabled in UI")
	shop.transact()
	check(game.money == 299 and "refined_sword" not in p.owned_weapons, "failed purchase changes nothing")
	game.money = 1150
	shop.transact()
	check(game.money == 850 and "refined_sword" in p.owned_weapons, "buy tier one for 300")
	shop.transact()
	check(game.money == 850 and p.owned_weapons.count("refined_sword") == 1, "duplicate owned weapon cannot charge")
	shop.select_tab(1)
	shop.select_item("refined_sword")
	shop.transact()
	check(game.battle.equipped_weapon_id == "refined_sword", "equip owned weapon")
	shop.select_item("none")
	shop.transact()
	check(game.battle.equipped_weapon_type == "none", "unarmed option")
	counter("city_instructor")
	shop.select_item("cheongpung")
	shop.transact()
	check(game.money == 850 and "cheongpung" not in p.learned, "learning stats enforced before charging")
	counter("city_merchant")
	shop.select_item("light_step_pill")
	shop.transact()
	check(game.money == 750 and p.inventory.light_step_pill == 1 and p.stats.agility == 10, "buy pill but do not auto consume")
	shop.select_tab(1)
	shop.select_item("light_step_pill")
	shop.transact()
	check(p.stats.agility == 13 and p.stats.strength == 11 and p.stats.insight == 10 and p.consumed.light_step_pill == 1 and p.inventory.light_step_pill == 0, "consume raises physical stats only")
	# Use quest-growth fixture to check an immediately learnable combination.
	p.stats.insight = 55
	p.stats.strength = 14
	p.stats.agility = 18
	p.stats.inner = 18
	counter("city_instructor")
	shop.select_item("cheongpung")
	shop.transact()
	check(game.money == 400 and "cheongpung" in p.learned, "learn for 350")
	shop.transact()
	check(game.money == 400 and p.learned.count("cheongpung") == 1, "learning cannot charge twice")
	shop.select_tab(1)
	shop.select_target_slot(1)
	shop.select_item("cheongpung")
	shop.transact()
	check(p.loadout == ["basic_attack", "cheongpung", "samjae", ""], "replace basic defense with a learned art")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1), "save open counter and progression")
	game.reset()
	check(game.save_system.load_slot(1), "load counter and progression")
	check(game.progress.learned == ["samjae", "cheongpung"] and game.progress.consumed.light_step_pill == 1 and game.money == 400, "restore money, learning and lifetime uses")
	p = game.progress
	check(p.loadout[1] == "cheongpung" and p.stats.insight == 55, "restore equipped techniques and stats")
	game.city_service.close_counter()
	game.battle.equip_weapon_item("refined_sword")
	game.start_battle()
	var ready_deadline=Time.get_ticks_msec()+3000
	while not game.battle.awaiting_player and Time.get_ticks_msec()<ready_deadline:await create_timer(.02).timeout
	game.battle.grid.units[1].position=game.battle.grid.units[0].position+Vector2i(2,0);game.battle.facing=Vector2i.RIGHT
	game.battle.select_skill("cheongpung")
	check(game.battle.selected_action == "cheongpung" and not game.battle.use_button.disabled, "learned technique appears in actual battle")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 2) and game.save_system.load_slot(2), "save selected newly learned technique")
	check(game.battle.selected_action == "cheongpung", "restore generic battle selection")
	ready_deadline=Time.get_ticks_msec()+3000
	while not game.battle.awaiting_player and Time.get_ticks_msec()<ready_deadline:await create_timer(.02).timeout
	game.battle.grid.units[1].position=game.battle.grid.units[0].position+Vector2i(2,0);game.battle.facing=Vector2i.RIGHT;game.battle.select_skill("cheongpung")
	var before_hp=game.battle.enemy_hp;var before_qi=game.battle.qi.amount;var qi_cost=game.battle.combat.action("cheongpung",p.stats,game.battle.equipped_weapon_id).cost
	game.battle.use_selected()
	var deadline = Time.get_ticks_msec() + 6000
	while game.battle.busy and Time.get_ticks_msec() < deadline: await create_timer(0.04).timeout
	check(game.battle.enemy_hp < before_hp and game.battle.qi.amount == before_qi-int(qi_cost)+int(p.stats.inner), "new skill actually deals scaled damage and consumes qi then recovers")
	game.reset()
	p = game.progress
	game.money = 100000
	for id in p.elixirs:
		if p.elixirs[id].get("acquisition")!="city_merchant":continue
		for count in range(10):
			check(p.purchase("elixir", id, game) and p.consume(id), "buy and consume each dose")
		var purse: int = game.money
		check(not p.purchase("elixir", id, game) and game.money == purse and not p.consume(id), "11th dose blocked without spending")
	check(p.stats == {"strength":70, "agility":70, "constitution":70, "inner":70, "insight":10}, "all forty pills produce expected growth")
	game.enter_city()
	check(game.save_system.write_slot(3), "save capped consumption")
	game.reset()
	check(game.save_system.load_slot(3) and game.progress.consumed.bear_strength_pill == 10, "load cannot reset lifetime cap")
	var old = game.save_system.capture()
	old.schema = 2
	old.erase("progress")
	var file = FileAccess.open(game.save_system.path(4), FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	check(game.save_system.load_slot(4) and game.progress.stats == game.progress.RULES.STARTING_STATS and game.progress.learned == ["samjae"], "old schema defaults to starter possessions")
	# Corrupt progression cannot replace a valid session.
	var malformed = game.save_system.capture()
	malformed.progress.consumed.bear_strength_pill = 11
	check(not game.save_system.validate(malformed), "reject over-limit saved dose count")
	malformed = game.save_system.capture()
	malformed.progress.loadout[0] = "unknown_art"
	check(not game.save_system.validate(malformed), "reject unknown equipped technique")
	# A full target-stat cap must not waste owned pills.
	p = game.progress
	p.stats = {"strength":200, "agility":200, "constitution":200, "inner":200, "insight":10}
	check(p.purchase("elixir", "bear_strength_pill", game), "buy one remaining legal dose")
	check(not p.consume("bear_strength_pill") and p.inventory.bear_strength_pill == 1 and p.consumed.bear_strength_pill == 0, "all capped stats do not consume a pill")
	game.reset()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_TRADING: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
