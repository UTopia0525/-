extends "res://tests/combat_updates.gd"
func run() -> void:
	var encounters=JSON.parse_string(FileAccess.get_file_as_string("res://data/qingya_quest.json")).encounters
	var skills=JSON.parse_string(FileAccess.get_file_as_string("res://data/alliance_martial_arts.json"))
	var output=[]
	for enemy in encounters:
		for id in enemy.skills:
			check(combat.arts.can_learn(id,enemy.stats),"Qingya enemy meets learning constraints")
			check(not combat.action(id,enemy.stats,enemy.weapon).is_empty(),"Qingya enemy has matching weapon")
	for id in skills:
		var weapon=preload("res://scripts/weapons.gd").DEFAULT_BY_TYPE[skills[id].required_weapon_type]
		for amount in [18,20,25]:
			var stats={"strength":amount,"agility":amount,"constitution":amount,"inner":amount,"insight":100-4*amount if amount<25 else 25}
			for enemy in encounters:
				var result=simulate(stats,weapon,id,enemy,false)
				output.append(result.merged({"art":id,"enemy":enemy.id,"stats":stats}))
				check(result.win,"intermediate first-clear build wins: "+id+" / "+enemy.id+" / "+str(amount))
	var file=FileAccess.open("user://qingya_balance.json",FileAccess.WRITE);file.store_string(JSON.stringify(output,"  "));file.close()
	print("GODOT_QINGYA_BALANCE: "+("FAIL" if failed else "PASS")+" / "+str(output.size())+" simulations");quit(1 if failed else 0)
