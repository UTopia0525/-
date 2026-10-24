extends SceneTree
const Combat=preload("res://scripts/combat_actions.gd")
const Qi=preload("res://scripts/inner_qi.gd")
const IDS=["hoeryu","paak","gwanak","banseok","jungun"]
const EQUIPMENT={1:{"sword":"refined_sword","saber":"thickback_saber","spear":"balanced_spear","none":"none"},2:{"sword":"blue_steel_sword","saber":"forged_saber","spear":"willow_spear","none":"none"},3:{"sword":"hundredfold_sword","saber":"heavy_steel_saber","spear":"flowing_cloud_spear","none":"none"}}
var combat=Combat.new()
func simulate(stats: Dictionary,weapon: String,skill: String,enemy: Dictionary,policy: String) -> Dictionary:
	var pq=Qi.new();pq.start(int(stats.inner));var eq=Qi.new();eq.start(int(enemy.stats.inner))
	var hp=300;var ehp=int(enemy.hp);var enemy_guard=0;var turns=[];var cost=0;var attacks=0;var basics=0;var guards=0
	for turn in range(1,101):
		var intent=combat.enemy_plan(enemy.stats,enemy.weapon,enemy.skills,eq.amount,turn)
		var opponent=combat.action(intent,enemy.stats,enemy.weapon)
		var chosen=skill
		var technique=combat.action(skill,stats,weapon)
		# Only broad attack/defense intent is available to the player policy.
		if policy=="respond" and intent=="basic_defense":chosen="basic_attack"
		elif technique.cost>pq.amount:chosen="basic_defense" if policy=="respond" else "basic_attack"
		var action=combat.action(chosen,stats,weapon)
		assert(pq.spend(int(action.cost)))
		cost+=int(action.cost)
		if chosen==skill:attacks+=1
		elif chosen=="basic_attack":basics+=1
		else:guards+=1
		var guard=combat.BASIC_GUARD if intent=="basic_defense" else enemy_guard
		var damage=combat.damage(action.raw,enemy.stats.constitution,enemy.weapon,guard)
		enemy_guard=0;ehp=maxi(0,ehp-damage)
		var received=0
		if ehp>0:
			assert(eq.spend(int(opponent.cost)))
			if opponent.raw>0:enemy_guard=int(opponent.guard)
			received=combat.damage(opponent.raw,stats.constitution,weapon,action.guard)
			hp=maxi(0,hp-received)
		turns.append({"turn":turn,"player":chosen,"enemy":intent,"damage":damage,"received":received,"hp":hp,"enemy_hp":ehp,"qi_after_spend":pq.amount})
		if hp==0 or ehp==0:break
		pq.recover_turn();eq.recover_turn()
	return {"win":ehp==0,"turns":turns.size(),"hp":hp,"enemy_hp":ehp,"qi_spent":cost,"art_uses":attacks,"basics":basics,"guards":guards,"trace":turns}
func _initialize() -> void:
	var profiles={"balanced_100":{"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20},"quest_heavy_120":{"strength":16,"agility":16,"constitution":16,"inner":17,"insight":55},"balanced_125":{"strength":25,"agility":25,"constitution":25,"inner":25,"insight":25},"balanced_150":{"strength":30,"agility":30,"constitution":30,"inner":30,"insight":30}}
	var enemies=[{"id":"veteran","name":"가상 숙련 무사","hp":600,"stats":{"strength":22,"agility":18,"constitution":25,"inner":18,"insight":17},"weapon":"thickback_saber","skills":["bandit_chop","bandit_heavy_chop"]},{"id":"heavy","name":"가상 중장 무사","hp":900,"stats":{"strength":24,"agility":18,"constitution":35,"inner":20,"insight":18},"weapon":"forged_saber","skills":["bandit_heavy_chop"]},{"id":"raider","name":"가상 강습 무사","hp":500,"stats":{"strength":30,"agility":24,"constitution":20,"inner":24,"insight":20},"weapon":"forged_saber","skills":["bandit_heavy_chop"]}]
	var results=[]
	var variants={"current":{"base":240,"cost":28},"trial_360_18":{"base":360,"cost":18},"trial_380_18":{"base":380,"cost":18}}
	for variant in variants:
		combat.arts.definitions.gwanak.base_damage=variants[variant].base
		combat.arts.definitions.gwanak.qi_cost=variants[variant].cost
		for profile in profiles:
			for tier in [1,2,3]:
				for enemy in enemies:
					for policy in ["attack","respond"]:
						for skill in IDS:
							var weapon: String=EQUIPMENT[tier][combat.arts.get_skill(skill).required_weapon_type]
							var result=simulate(profiles[profile],weapon,skill,enemy,policy)
							result.merge({"variant":variant,"profile":profile,"tier":tier,"enemy":enemy.id,"policy":policy,"skill":skill,"weapon":weapon,"raw":combat.action(skill,profiles[profile],weapon).raw,"effective_cost":combat.action(skill,profiles[profile],weapon).cost})
							if not (profile=="balanced_100" and tier==1 and enemy.id=="veteran" and policy=="respond"):result.erase("trace")
							results.append(result)
	var data={"profiles":profiles,"enemies":enemies,"variants":variants,"results":results}
	var f=FileAccess.open("res://../docs/reviews/alliance-matchups.json",FileAccess.WRITE);assert(f!=null);f.store_string(JSON.stringify(data,"  "));f.close()
	for profile in profiles:
		print(profile," / tier1 veteran respond")
		for r in results:
			if r.profile==profile and r.tier==1 and r.enemy=="veteran" and r.policy=="respond" and (r.variant=="current" or r.skill=="gwanak"):print(r.variant," ",r.skill," ",r.win," turns=",r.turns," hp=",r.hp," qi=",r.qi_spent," art=",r.art_uses," raw=",r.raw," cost=",r.effective_cost)
	print("SIMULATED ",results.size()," deterministic cases; no runtime data changed")
	quit()
