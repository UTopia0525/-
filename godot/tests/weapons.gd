extends SceneTree
const WEAPONS = preload("res://scripts/weapons.gd")
const ARTS = preload("res://scripts/martial_arts.gd")
const RULES = preload("res://scripts/rules.gd")
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("WEAPON_STATS: " + message)
func run() -> void:
	var weapons = WEAPONS.new()
	var arts = ARTS.new()
	check(weapons.definitions.size() == 10, "starter plus nine tiered weapons")
	var baseline = weapons.get_weapon(weapons.STARTING_WEAPON)
	check(baseline.name == "무문철검" and baseline.weapon_type == "sword", "named starter sword")
	check(baseline.attack_bonus_percent == 0 and baseline.damage_reduction_percent == 0 and baseline.qi_reduction_percent == 0, "starter has no bonus")
	for id in weapons.definitions:
		var item = weapons.get_weapon(id)
		if item.tier == 0: continue
		check(item.acquisition == null, "no invented acquisition")
		var tier: int = int(item.tier)
		match item.weapon_type:
			"sword": check(item.attack_bonus_percent == tier * 5 and item.damage_reduction_percent == tier * 3 and item.qi_reduction_percent == 0, "balanced sword tiers")
			"saber": check(item.attack_bonus_percent == tier * 10 and item.damage_reduction_percent == 0 and item.qi_reduction_percent == 0, "damage-only saber tiers")
			"spear": check(item.qi_reduction_percent == tier * 10 and item.attack_bonus_percent == 0 and item.damage_reduction_percent == 0, "efficiency-only spear tiers")
	check(weapons.attack_damage(50, weapons.STARTING_WEAPON, arts.get_skill("samjae")) == 50, "starter preserves damage")
	check(weapons.received_damage(40, 10, weapons.STARTING_WEAPON) == RULES.damage(40, 10), "starter preserves incoming damage")
	check(is_equal_approx(weapons.attack_damage(100, "hundredfold_sword", arts.get_skill("samjae")), 115), "sword attack bonus")
	check(weapons.received_damage(100, 10, "hundredfold_sword") == 74, "sword reduction after constitution, round only once")
	check(weapons.received_damage(100, 100, "hundredfold_sword") == 0, "weapon reduction cannot introduce minimum damage")
	check(weapons.attack_damage(100, "heavy_steel_saber", arts.get_skill("danseok")) == 130, "saber attack bonus")
	check(weapons.attack_damage(100, "heavy_steel_saber", arts.get_skill("cheolsan")) == 100, "held weapon does not buff hand arts")
	check(weapons.qi_cost(24, "flowing_cloud_spear", arts.get_skill("yeonhwan")) == 17, "spear efficiency uses ceiling")
	check(weapons.qi_cost(1, "flowing_cloud_spear", arts.get_skill("yeonhwan")) == 1 and weapons.qi_cost(0, "flowing_cloud_spear", arts.get_skill("yeonhwan")) == 0, "positive costs never become free")
	check(weapons.qi_cost(28, "flowing_cloud_spear", arts.get_skill("ungi")) == 28, "spear reduction does not leak to palm arts")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_battle()
	check(game.battle.equipped_weapon_id == "plain_iron_sword", "actual new game equips starter sword")
	game.battle.equip_weapon_item("hundredfold_sword")
	check(game.save_system.write_slot(1), "weapon ID saved")
	game.reset()
	check(game.save_system.load_slot(1) and game.battle.equipped_weapon_id == "hundredfold_sword", "exact weapon tier restored")
	check(game.battle.equipped_weapon_type == "sword", "category follows restored item")
	game.reset()
	check(game.battle.equipped_weapon_id == "plain_iron_sword", "new playthrough resets starter")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_WEAPONS: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
