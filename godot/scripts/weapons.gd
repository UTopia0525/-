extends RefCounted
const RULES = preload("res://scripts/rules.gd")
const STARTING_WEAPON := "plain_iron_sword"
const DEFAULT_BY_TYPE = {"none":"none", "sword":STARTING_WEAPON, "saber":"thickback_saber", "spear":"balanced_spear"}
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))

func exists(id: String) -> bool:
	return id == "none" or definitions.has(id)

func get_weapon(id: String) -> Dictionary:
	return definitions.get(id, {}).duplicate(true)

func weapon_type(id: String) -> String:
	return str(definitions[id].weapon_type) if definitions.has(id) else "none"

func applies_to_skill(id: String, skill: Dictionary) -> bool:
	return definitions.has(id) and skill.get("required_weapon_type") == weapon_type(id)

func attack_damage(raw: float, id: String, skill: Dictionary) -> float:
	if not applies_to_skill(id, skill): return raw
	return raw * (1.0 + float(definitions[id].attack_bonus_percent) / 100.0)

func qi_cost(base_cost: int, id: String, skill: Dictionary) -> int:
	if base_cost <= 0: return base_cost
	if not applies_to_skill(id, skill): return base_cost
	return maxi(1, ceili(base_cost * (100.0 - float(definitions[id].qi_reduction_percent)) / 100.0))

func received_damage(raw: float, constitution: float, id: String) -> int:
	var reduction: float = float(definitions.get(id, {}).get("damage_reduction_percent", 0))
	return floori(RULES.damage_before_rounding(raw, constitution) * (1.0 - reduction / 100.0))
