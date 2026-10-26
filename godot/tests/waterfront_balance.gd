extends "res://tests/combat_updates.gd"
func run() -> void:
	var enemy=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_waterfront_quest.json")).encounter
	for id in enemy.skills:check(combat.arts.can_learn(id,enemy.stats) and not combat.action(id,enemy.stats,enemy.weapon).is_empty(),"enemy learns and equips its own skill")
	var output=[]
	var catalogue=preload("res://scripts/martial_arts.gd").new()
	for id in catalogue.definitions:
		var skill: Dictionary=catalogue.get_skill(id)
		if skill.get("acquisition") not in ["alliance_instructor","city_instructor","quest_manual"]:continue
		var weapon: String=preload("res://scripts/weapons.gd").DEFAULT_BY_TYPE[skill.required_weapon_type]
		var stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
		for reactive in [false,true]:
			var result=simulate(stats,weapon,id,enemy,reactive);output.append(result.merged({"skill":id,"stats":stats,"weapon":weapon,"reactive":reactive}))
			if not reactive or skill.get("acquisition")!="city_instructor":check(result.win,"ordinary peak build wins "+id)
		if skill.get("acquisition")=="city_instructor":
			var minimum=preload("res://scripts/rules.gd").STARTING_STATS.duplicate()
			for key in skill.requirements.stats:minimum[key]=maxi(int(minimum[key]),int(skill.requirements.stats[key]))
			var total=0
			for value in minimum.values():total+=int(value)
			minimum.insight+=maxi(0,int(skill.requirements.minimum_total)-total)
			output.append(simulate(minimum,weapon,id,enemy,false).merged({"skill":id,"stats":minimum,"minimum_learning_probe":true}))
	var file=FileAccess.open("user://waterfront_balance.json",FileAccess.WRITE);file.store_string(JSON.stringify(output,"  "));file.close()
	print("WATERFRONT_BALANCE: "+("FAIL" if failed else "PASS")+" / "+str(output.size())+" simulations");quit(1 if failed else 0)
