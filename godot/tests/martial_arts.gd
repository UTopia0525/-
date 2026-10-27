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
	check(arts.definitions.size() == 16, "entry art, eight low arts, six intermediate attacks and one intermediate support")
	check(arts.qi_cost("samjae") == 10 and arts.raw_damage("samjae", RULES.STARTING_STATS) == 50, "confirmed Samjae cost and formula")
	check(arts.can_learn("samjae", RULES.STARTING_STATS), "baseline known skill remains valid")
	var names: Array = []
	for id in arts.definitions:
		var skill: Dictionary = arts.get_skill(id)
		check(not names.has(skill.name), "unique skill names")
		names.append(skill.name)
		check(skill.acquisition == ("wuchang_training_duel" if id=="josik_suwon" else null if id == "samjae" else "quest_manual" if id=="swaerang" else "alliance_instructor" if skill.get("acquisition")=="alliance_instructor" else "city_instructor"), "starting technique or instructor acquisition")
		var required = skill.required_weapon_type
		if required != null:
			check(arts.can_use_with_weapon(id, required), "matching weapon accepted: " + id)
			for wrong in ["none", "sword", "saber", "spear"]:
				if wrong != required: check(not arts.can_use_with_weapon(id, wrong), "wrong or unequipped weapon blocked: " + id)
		else:
			check(arts.can_use_with_weapon(id, "none") and arts.can_use_with_weapon(id, "sword"), "unrestricted hand arts do not invent equipment bans")
		if skill.weapon_style=="support":
			check(arts.can_learn(id,RULES.STARTING_STATS) and arts.raw_damage(id,RULES.STARTING_STATS)==0 and skill.qi_restore_inner_percent==200 and arts.qi_recovery(id,RULES.STARTING_STATS)==20 and skill.guard_percent==20 and skill.cooldown_turns==3,"universal reward support has fixed approved effects")
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
	check_redesign(arts)
	print("GODOT_MARTIAL_ARTS: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func check_redesign(arts) -> void:
	var tactics=preload("res://scripts/martial_tactics.gd").new()
	var counts={"sword":0,"saber":0,"spear":0,"none":0}
	var patterns={}
	for id in arts.definitions:
		var skill=arts.get_skill(id)
		var t=tactics.get_tactics(id)
		check(skill.action_cost==t.action_cost and int(t.action_cost)>0,"single displayed/designed action cost: "+id)
		if skill.grade=="low":counts[skill.required_weapon_type]+=1
		var model=tactics.preview(id)
		for point in model.attacks+model.moves:
			var offset: Vector2i=point-model.origin
			check(absi(offset.x)+absi(offset.y)<=3,"all attacks and displacements within three steps: "+id)
			check(point.x>=0 and point.x<7 and point.y>=0 and point.y<5,"full diagram fits battlefield: "+id)
		if skill.weapon_style=="support":continue
		check(skill.damage_coefficients.keys().all(func(k):return k in ["strength","inner"]),"agility, constitution and insight do not add martial damage: "+id)
		if skill.required_weapon_type=="none":
			check(skill.damage_coefficients.inner>skill.damage_coefficients.strength,"unarmed scales mostly with inner power: "+id)
		else:
			check(skill.damage_coefficients.strength>skill.damage_coefficients.inner,"weapons scale mostly with strength: "+id)
		var key=str(skill.required_weapon_type)
		var signature=str(model.attacks)
		if not patterns.has(key):patterns[key]=[]
		check(signature not in patterns[key],"different attack coverage within weapon family: "+id)
		patterns[key].append(signature)
	check(counts=={"sword":2,"saber":2,"spear":2,"none":2},"exactly two low arts per weapon including unarmed")
	check(arts.get_skill("cheolsan").weapon_style=="fist" and arts.get_skill("ungi").weapon_style=="palm","one low fist and one low palm")
	check(arts.get_skill("josik_suwon").grade=="intermediate","support promoted to intermediate without changing reward")
	var combat=preload("res://scripts/combat_actions.gd").new()
	for ids in [["gwanpung","danseok","cheolsan"],["gwanak","paak","banseok"]]:
		var early={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
		var late={"strength":100,"agility":100,"constitution":100,"inner":100,"insight":100}
		for other in [ids[1],ids[2]]:
			var weapon=combat.weapons.DEFAULT_BY_TYPE[arts.get_skill(other).required_weapon_type]
			check(combat.action(ids[0],early,"balanced_spear").raw>combat.action(other,early,weapon).raw,"spear has early fixed-force advantage over "+other)
			check(combat.action(ids[0],late,"balanced_spear").raw<combat.action(other,late,weapon).raw,"higher growth overtakes spear later: "+other)
	check(combat.action("gwanak",{"strength":20,"inner":20},"balanced_spear").cost==40,"spear equipment still discounts high inner qi cost")
	var progress=preload("res://scripts/player_progress.gd").new()
	var old=progress.snapshot();old.learned.append_array(["cheongpung","swaeam","cheolsan","jingak"])
	old.loadout=["swaeam","cheongpung","jingak","cheolsan"]
	check(progress.valid(old),"retired arts in old saves validate after migration")
	var invalid=old.duplicate(true);invalid.learned.erase("swaeam")
	check(not progress.valid(invalid),"retired art must actually have been learned in the source save")
	progress.restore(old)
	check(progress.learned==["samjae","cheongpung","cheolsan"] and progress.loadout==["cheongpung","","cheolsan",""],"migration preserves learning and four slots without duplicates")
	check(not progress.arts.definitions.has("swaeam") and not progress.arts.definitions.has("jingak"),"retired arts are not available for new acquisition")
