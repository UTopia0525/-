extends SceneTree
## Compare actual shared combat rules with the pre-patch catalogue, not a duplicate formula.
const Combat = preload("res://scripts/combat_actions.gd")
const Weapons = preload("res://scripts/weapons.gd")
var failed := false
var baseline = Combat.new()
var revised = Combat.new()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SPEAR_BALANCE: " + message)
func turns(model, stats: Dictionary, weapon: String, skills: Array, hp: int, g: int, limit: int = 80) -> Dictionary:
	var amount: int = stats.inner
	var used: Array = []
	var output := 0
	for turn in range(1,limit+1):
		var chosen: Dictionary = model.action("basic_attack",stats,weapon)
		for id in skills:
			if not model.arts.can_learn(id,stats): continue
			var candidate: Dictionary = model.action(id,stats,weapon)
			if not candidate.is_empty() and candidate.cost <= amount and candidate.raw > chosen.raw: chosen = candidate
		var damage: int = model.damage(chosen.raw,g,"none",70 if turn%3==0 else 0)
		amount -= int(chosen.cost)
		used.append(chosen.id)
		output += damage
		hp -= damage
		if hp <= 0: return {"turns":turn,"actions":used,"damage":output}
		amount = mini(500,amount+int(stats.inner))
	return {"turns":limit+1,"actions":used,"damage":output}
func _initialize() -> void:
	# Historical baseline is intentional; this makes the before/after report reproducible.
	baseline.arts.definitions.gwanpung.damage_coefficients={"strength":3,"agility":5,"insight":2}
	baseline.arts.definitions.gwanpung.erase("base_damage")
	baseline.arts.definitions.gwanpung.qi_cost=20
	baseline.arts.definitions.yeonhwan.damage_coefficients={"strength":3,"agility":5,"inner":3}
	baseline.arts.definitions.yeonhwan.erase("base_damage")
	baseline.arts.definitions.yeonhwan.qi_cost=34
	check(revised.arts.get_skill("gwanpung").get("base_damage")==200 and revised.arts.qi_cost("gwanpung")==30,"live Gwanpung catalogue uses the applied patch")
	check(revised.arts.get_skill("yeonhwan").get("base_damage")==240 and revised.arts.qi_cost("yeonhwan")==40,"live Yeonhwan catalogue uses the applied patch")
	var early := {"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
	var late := {"strength":80,"agility":80,"constitution":80,"inner":80,"insight":80}
	for id in ["gwanpung","yeonhwan"]:
		check(revised.action(id,early,"balanced_spear").raw > baseline.action(id,early,"balanced_spear").raw,"early spear burst improves: "+id)
		check(revised.action(id,late,"flowing_cloud_spear").raw < revised.action("yusu",late,"hundredfold_sword").raw,"ordinary spear falls behind late sword scaling: "+id)
		check(revised.action(id,late,"flowing_cloud_spear").raw < revised.action("hoepung",late,"heavy_steel_saber").raw,"ordinary spear falls behind late saber scaling: "+id)
		check(revised.action(id,late,"flowing_cloud_spear").raw < revised.action("cheolsan",late,"none").raw,"ordinary spear falls behind late fist scaling: "+id)
	check(revised.action("yeonhwan",early,"balanced_spear").cost==36,"high qi cost is reduced by spear equipment")
	var report := {"scope":"균등 능력치 비교는 성장 가정. 후반 적·상위 무공은 미구현이므로 실제 후반 전투 보장이 아님.","duels":[],"scaling":[]}
	for value in [15,20,30,60,80,100]:
		var stats := {"strength":value,"agility":value,"constitution":value,"inner":value,"insight":value}
		var scaling := {"stat_each":value,"arts":{}}
		for id in ["cheongpung","yusu","danseok","hoepung","gwanpung","yeonhwan","cheolsan","ungi"]:
			var style: String = revised.arts.get_skill(id).required_weapon_type
			var weapon: String = {"sword":"hundredfold_sword","saber":"heavy_steel_saber","spear":"flowing_cloud_spear","none":"none"}[style]
			scaling.arts[id] = {"eligible":revised.arts.can_learn(id,stats),"before":baseline.action(id,stats,weapon).raw,"after":revised.action(id,stats,weapon).raw}
		report.scaling.append(scaling)
	for value in [15,20,30]:
		var stats := {"strength":value,"agility":value,"constitution":value,"inner":value,"insight":value}
		for hp in [240,480,720]:
			for entry in [{"weapon":"refined_sword","skills":["cheongpung","yusu"]},{"weapon":"thickback_saber","skills":["danseok","hoepung"]},{"weapon":"balanced_spear","skills":["gwanpung"]},{"weapon":"balanced_spear","skills":["yeonhwan"]},{"weapon":"none","skills":["cheolsan","ungi"]}]:
				var available: Array = []
				for id in entry.skills:
					if revised.arts.can_learn(id,stats): available.append(id)
				if available.is_empty(): continue
				var before := turns(baseline,stats,entry.weapon,entry.skills,hp,15)
				var after := turns(revised,stats,entry.weapon,entry.skills,hp,15)
				report.duels.append({"stat_each":value,"target_hp":hp,"target_g":15,"weapon":entry.weapon,"skills":available,"before":before,"after":after})
	var file := FileAccess.open("user://spear_balance_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	print("GODOT_SPEAR_BALANCE: "+("FAIL" if failed else "PASS")+" / scenarios="+str(report.duels.size()))
	quit(1 if failed else 0)
