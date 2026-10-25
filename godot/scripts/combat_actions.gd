extends RefCounted
## Shared player/enemy actions: identical qi, basic damage, weapon rules and guard formula.
const Rules = preload("res://scripts/rules.gd")
const Arts = preload("res://scripts/martial_arts.gd")
const Weapons = preload("res://scripts/weapons.gd")
const BASIC_GUARD := 20
const SWORD_GUARD := 20
var arts = Arts.new()
var weapons = Weapons.new()
func _init() -> void:
	arts.definitions.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/enemy_martial_arts.json")))
func action(id: String, stats: Dictionary, weapon: String) -> Dictionary:
	if id == "basic_attack": return {"id":id,"name":"기본공격","raw":Rules.basic_attack_damage(stats),"cost":0,"guard":0}
	if id == "basic_defense": return {"id":id,"name":"기본방어","raw":0.0,"cost":0,"guard":BASIC_GUARD}
	if not arts.can_use_with_weapon(id, weapons.weapon_type(weapon)): return {}
	var skill := arts.get_skill(id)
	return {"id":id,"name":skill.name,"raw":weapons.attack_damage(arts.raw_damage(id,stats),weapon,skill),"cost":weapons.qi_cost(skill.qi_cost,weapon,skill),"guard":int(skill.get("guard_percent",SWORD_GUARD if skill.weapon_style == "sword" else 0)),"qi_restore":arts.qi_recovery(id,stats),"cooldown_turns":int(skill.get("cooldown_turns",0))}
func cooldown_remaining(id: String, current_turn: int, ready_turns: Dictionary) -> int:
	return maxi(0,int(ready_turns.get(id,0))-current_turn)
func commit_support(action_data: Dictionary, resource, ready_turns: Dictionary, current_turn: int) -> int:
	# Called once for an executed action, shared by both actors. Preview never calls this.
	var duration: int=int(action_data.get("cooldown_turns",0))
	if duration>0:ready_turns[action_data.id]=current_turn+duration+1
	var amount: int=int(action_data.get("qi_restore",0))
	return resource.recover(amount) if amount>0 else 0
func damage(raw: float, constitution: float, weapon: String, guard: int = 0) -> int:
	var passive := float(weapons.get_weapon(weapon).get("damage_reduction_percent",0))
	return floori(Rules.damage_before_rounding(raw,constitution) * (1.0-passive/100.0) * (1.0-clampi(guard,0,100)/100.0) + 0.00000001)
func enemy_plan(stats: Dictionary, weapon: String, skills: Array, amount: int, current_turn: int, ready_turns: Dictionary = {}) -> String:
	# Locked before player input. Never reads the player's selected move or rerolls.
	if current_turn % 3 == 0: return "basic_defense"
	var best := "basic_attack"
	var strongest := action(best,stats,weapon)
	for id in skills:
		var option := action(str(id),stats,weapon)
		if not option.is_empty() and cooldown_remaining(str(id),current_turn,ready_turns)==0 and option.cost <= amount and option.raw > strongest.raw:
			best = str(id)
			strongest = option
	return best
