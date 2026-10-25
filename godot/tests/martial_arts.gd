extends SceneTree
const CATALOGUE = preload("res://scripts/martial_arts.gd")
const RULES = preload("res://scripts/rules.gd")
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("MARTIAL_ARTS: " + message)
func _initialize() -> void:
	var arts = CATALOGUE.new()
	check(arts.definitions.size() == 17, "eleven introductory, five alliance, one support art")
	check(arts.qi_cost("samjae") == 10 and arts.raw_damage("samjae", RULES.STARTING_STATS) == 50, "confirmed Samjae cost and formula")
	check(arts.can_learn("samjae", RULES.STARTING_STATS), "baseline known skill remains valid")
	var names: Array = []
	for id in arts.definitions:
		var skill: Dictionary = arts.get_skill(id)
		check(not names.has(skill.name), "unique skill names")
		names.append(skill.name)
		check(skill.acquisition == ("wuchang_training_duel" if id=="josik_suwon" else null if id == "samjae" else "alliance_instructor" if skill.get("grade","")=="intermediate" else "city_instructor"), "starting technique or instructor acquisition")
		var required = skill.required_weapon_type
		if required != null:
			check(arts.can_use_with_weapon(id, required), "matching weapon accepted: " + id)
			for wrong in ["none", "sword", "saber", "spear"]:
				if wrong != required: check(not arts.can_use_with_weapon(id, wrong), "wrong or unequipped weapon blocked: " + id)
		else:
			check(arts.can_use_with_weapon(id, "none") and arts.can_use_with_weapon(id, "sword"), "unrestricted hand arts do not invent equipment bans")
		if skill.weapon_style=="support":
			check(arts.can_learn(id,RULES.STARTING_STATS) and arts.raw_damage(id,RULES.STARTING_STATS)==0 and skill.qi_restore==40 and skill.guard_percent==20 and skill.cooldown_turns==3,"universal reward support has fixed approved effects")
			continue
		if id == "samjae" or skill.get("grade","")=="intermediate": continue
		check(not arts.can_learn(id, RULES.STARTING_STATS), "starting stats do not qualify: " + id)
		check(arts.raw_damage(id, RULES.STARTING_STATS) > 50, "higher baseline formula than Samjae: " + id)
		check(skill.qi_cost > 10 and skill.qi_cost <= 500, "upgraded qi costs")
		var eligible = {}
		var total := 0
		for stat in RULES.STARTING_STATS:
			eligible[stat] = int(skill.requirements.stats.get(stat, 0))
			total += eligible[stat]
		for stat in RULES.STARTING_STATS:
			if not skill.requirements.stats.has(stat):
				eligible[stat] += maxi(0, int(skill.requirements.minimum_total) - total)
				break
		check(arts.can_learn(id, eligible), "exact learning boundary qualifies: " + id)
		for stat in skill.requirements.stats:
			var below = eligible.duplicate()
			below[stat] = int(skill.requirements.stats[stat]) - 1
			check(not arts.can_learn(id, below), "individual prerequisite enforced: " + id + "/" + stat)
		var below_total = eligible.duplicate()
		for stat in RULES.STARTING_STATS:
			if not skill.requirements.stats.has(stat) and below_total[stat] > 0:
				below_total[stat] -= 1
				break
		check(not arts.can_learn(id, below_total), "total prerequisite enforced: " + id)
		var copy = arts.get_skill(id)
		copy.qi_cost = 999
		check(arts.qi_cost(id) != 999, "callers cannot mutate catalogue through copies")
	check(not arts.can_learn("missing", RULES.STARTING_STATS) and arts.raw_damage("missing", {}) == 0, "unknown skill rejected")
	print("GODOT_MARTIAL_ARTS: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
