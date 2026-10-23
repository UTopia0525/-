extends RefCounted
## Catalogue and numeric rules only. Meeting requirements does not grant a skill.
const RULES = preload("res://scripts/rules.gd")
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/basic_martial_arts.json"))

func get_skill(id: String) -> Dictionary:
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
	var amount := 0.0
	for stat in definitions[id].damage_coefficients:
		amount += float(stats.get(stat, 0)) * float(definitions[id].damage_coefficients[stat])
	return amount

func qi_cost(id: String) -> int:
	return int(definitions[id].qi_cost) if definitions.has(id) else -1
