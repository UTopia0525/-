extends RefCounted
## Learning, damage, costs and equipment conditions. Eligibility does not grant a skill.
const WEAPON_NAMES = {"none":"맨손", "sword":"검", "saber":"도", "spear":"창"}
const RETIRED = {"swaeam":"cheongpung", "jingak":"cheolsan"}
const RULES = preload("res://scripts/rules.gd")
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/basic_martial_arts.json"))

func _init() -> void:
	definitions.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/quest_martial_arts.json")))
	definitions.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/alliance_martial_arts.json")))
	definitions.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/support_martial_arts.json")))

func get_skill(id: String) -> Dictionary:
	if id == "basic_attack": return {"name":"기본공격", "description":"내기를 소모하지 않고 공격합니다.", "damage_coefficients":{"strength":1,"agility":1,"inner":1}, "qi_cost":0, "required_weapon_type":null, "weapon_style":"basic", "requirements":{"stats":{},"minimum_total":0}}
	if id == "basic_defense": return {"name":"기본방어", "description":"다음 자기 행동 시작까지 받는 피해를20% 줄입니다. 내기 소모 없이 행동 종료 시 정상 회복합니다.", "damage_coefficients":{}, "qi_cost":0, "required_weapon_type":null, "weapon_style":"basic", "requirements":{"stats":{},"minimum_total":0}}
	return definitions.get(id, {}).duplicate(true)

func can_learn(id: String, stats: Dictionary) -> bool:
	if not definitions.has(id): return false
	var total := 0
	for stat in RULES.STARTING_STATS:
		if not stats.has(stat) or not (stats[stat] is int or stats[stat] is float): return false
		if not is_finite(stats[stat]) or stats[stat] < 0 or stats[stat] > 100: return false
		total += int(stats[stat])
	var requirements: Dictionary = definitions[id].requirements
	if total < int(requirements.minimum_total): return false
	for stat in requirements.stats:
		if stats.get(stat, 0) < requirements.stats[stat]: return false
	return true

func raw_damage(id: String, stats: Dictionary) -> float:
	if not definitions.has(id): return 0.0
	var amount := float(definitions[id].get("base_damage", 0))
	for stat in definitions[id].damage_coefficients:
		amount += float(stats.get(stat, 0)) * float(definitions[id].damage_coefficients[stat])
	return amount

func qi_recovery(id: String, stats: Dictionary) -> int:
	var skill: Dictionary=get_skill(id)
	return int(skill.get("qi_restore",0))+floori(float(stats.get("inner",0))*float(skill.get("qi_restore_inner_percent",0))/100.0)

func qi_cost(id: String) -> int:
	return int(definitions[id].qi_cost) if definitions.has(id) else -1

func can_use_with_weapon(id: String, equipped_type: String) -> bool:
	if id in ["basic_attack", "basic_defense"]: return true
	if not definitions.has(id) or not WEAPON_NAMES.has(equipped_type): return false
	var required = definitions[id].required_weapon_type
	return required == null or required == equipped_type

func weapon_requirement(id: String) -> String:
	if id in ["basic_attack", "basic_defense"]: return "무기 제한 없음"
	if not definitions.has(id): return "사용할 수 없는 무공입니다."
	var required = definitions[id].required_weapon_type
	if required == "none": return "무기 해제 필요(맨손)"
	return "필요 무기: 없음" if required == null else "필요 무기: " + str(WEAPON_NAMES[required])

static func upgrade_progress(data):
	# Map retired arts once, preserving slot positions and rejecting malformed source arrays.
	if not data is Dictionary or not data.get("learned") is Array or not data.get("loadout") is Array:return data
	for key in ["learned","loadout"]:
		for id in data[key]:
			if not id is String or (id!="" and data[key].count(id)>1):return data
	for id in data.loadout:
		if id in RETIRED and id not in data.learned:return data
	var upgraded: Dictionary=data.duplicate(true)
	upgraded.learned=[]
	for id in data.learned:
		var current=RETIRED.get(id,id)
		if current not in upgraded.learned:upgraded.learned.append(current)
	upgraded.loadout=[]
	for id in data.loadout:
		var current=RETIRED.get(id,id)
		upgraded.loadout.append("" if current!="" and current in upgraded.loadout else current)
	return upgraded
