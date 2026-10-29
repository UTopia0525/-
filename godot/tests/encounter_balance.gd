extends SceneTree
var failed=false
var report=[]
const KEYS=["strength","agility","constitution","inner","insight"]
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("ENCOUNTER_BALANCE: "+message)
func run_battle(e: Dictionary,stats: Dictionary,skill: String,policy: String,legacy_health: bool=false) -> Dictionary:
 var g=preload("res://scripts/grid_combat.gd").new()
 var weapon=g.combat.weapons.DEFAULT_BY_TYPE[g.combat.arts.get_skill(skill).required_weapon_type]
 var hp=300 if legacy_health else preload("res://scripts/rules.gd").max_health(stats)
 var enemy_hp=int(preload("res://scripts/save_system.gd").LEGACY_HEALTH_CAPS.get(e.id,e.max_hp)) if legacy_health else preload("res://scripts/rules.gd").max_health(e.stats)
 var field: Dictionary=e.get("field",{}).duplicate(true);field.support=e.get("support",{}).duplicate(true)
 g.setup(field,{"stats":stats.duplicate(),"weapon":weapon,"hp":hp,"max_hp":hp,"skills":[skill],"ai":{"style":"adaptive"}}, {"stats":e.stats.duplicate(),"weapon":e.weapon,"hp":enemy_hp,"max_hp":enemy_hp,"skills":e.skills.duplicate(),"ai":e.get("ai",{})})
 var used={};var steps=0
 for step in range(500):
  steps=step+1
  var actor=g.next_actor()
  if actor<0:break
  var plan={}
  if actor==1:plan=g.enemy_choice()
  elif policy=="adaptive":plan=preload("res://scripts/grid_tactical_ai.gd").choose(g,0)
  else:
   var attack=preload("res://scripts/grid_tactical_ai.gd").damage_at(g,0,g.units[0].position)
   var spacing={}
   if attack.id!="" and attack.id!=skill and int(g.profile(skill).advance)>0:
    var original=g.units[0].position
    for direction in g.DIRECTIONS:
     var point=original+direction
     if not g.free_cell(point,0):continue
     g.units[0].position=point
     for facing in g.DIRECTIONS:
      if g.problem(0,skill,facing).is_empty():spacing={"id":"move","facing":direction,"destination":point};break
     g.units[0].position=original
     if not spacing.is_empty():break
   if not spacing.is_empty():plan=spacing
   elif attack.id!="":plan={"id":attack.id,"facing":attack.facing}
   else:plan=preload("res://scripts/grid_tactical_ai.gd").choose(g,0)
  var event=g.perform(actor,plan.id,plan.facing,plan.get("destination",Vector2i(-1,-1)))
  check(event.ok,"legal committed action: "+e.id)
  if actor==1:used[plan.id]=int(used.get(plan.id,0))+1
  if g.winner>=0:break
 return {"enemy":e.id,"skill":skill,"policy":policy,"win":g.winner==0,"hp":g.units[0].hp,"max_hp":hp,"enemy_hp":g.units[1].hp,"enemy_max_hp":enemy_hp,"winner":g.winner,"steps":steps,"enemy_used":used}
func _initialize() -> void:
 var enemies=[JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial_enemy.json"))]
 for name in ["changsha_bandit_story","wuchang_herbalist_quest","wuchang_duel_quest","wuchang_inn_quest","wuchang_impostor_quest","qingya_quest","nanjing_waterfront_quest"]:
  var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name+".json"))
  enemies.append_array(data.get("encounters",[data.get("encounter",{})]))
 check(enemies.size()==9,"nine active fights")
 var model=preload("res://scripts/grid_combat.gd").new()
 for index in range(enemies.size()):
  var e=enemies[index]
  check(e.constitution==e.stats.constitution,"constitution fields agree")
  for id in e.skills:
   check(model.combat.arts.can_learn(id,e.stats),"enemy meets learning requirements: "+e.id+"/"+id)
   check(model.combat.arts.can_use_with_weapon(id,model.combat.weapons.weapon_type(e.weapon)),"enemy matching weapon")
  var stats={};for key in KEYS:stats[key]=10 if index==0 else 20
  var skills=["samjae"] if index==0 else ["cheongpung","yusu","danseok","hoepung","gwanpung","yeonhwan","cheolsan","ungi"] if index<3 else ["hoeryu","paak","gwanak","banseok","jungun"]
  for skill in skills:
   for policy in ["direct","adaptive"]:
    var build=stats.duplicate()
    if index<3 and index>0 and skill=="ungi":build={"strength":18,"agility":18,"constitution":20,"inner":26,"insight":18}
    check(model.combat.arts.can_learn(skill,build),"player meets learning requirements: "+skill)
    var result=run_battle(e,build,skill,policy);report.append(result)
    check(result.win,"target tier clears: "+JSON.stringify(result))
 # A realistic early realm build spends more points on quest-earned insight.
 for index in range(1,enemies.size()):
  var skills=["cheongpung","yusu","danseok","hoepung","gwanpung","yeonhwan","cheolsan","ungi"] if index<3 else ["hoeryu","paak","gwanak","banseok","jungun"]
  for skill in skills:
   var stats={"strength":18,"agility":18,"constitution":18,"inner":18,"insight":28}
   if index<3 and skill=="cheolsan":stats={"strength":17,"agility":17,"constitution":18,"inner":20,"insight":28}
   if index<3 and skill=="ungi":stats={"strength":16,"agility":16,"constitution":16,"inner":26,"insight":26}
   var result=run_battle(enemies[index],stats,skill,"adaptive");result.build=stats;report.append(result)
   check(result.win,"early realm build clears: "+JSON.stringify(result))
 var file=FileAccess.open("user://encounter_balance.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print(JSON.stringify(report));print("ENCOUNTER_BALANCE: "+("FAIL" if failed else "PASS")+" / "+str(report.size())+" cases");quit(1 if failed else 0)
