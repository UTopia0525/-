extends "res://tests/encounter_balance.gd"
func _initialize() -> void:
 var yuan=JSON.parse_string(FileAccess.get_file_as_string("res://data/murong_quest.json")).encounter
 var tak=JSON.parse_string(FileAccess.get_file_as_string("res://data/cuiyue_incident.json")).encounter
 var narrow=yuan.duplicate(true);narrow.name+=" · 좁은 길 재대련";narrow.field={"width":7,"height":3,"player_spawn":[1,1],"enemy_spawn":[5,1],"blocked":[[0,0],[0,2],[6,0],[6,2]]}
 var rules=preload("res://scripts/rules.gd")
 var builds={"quest101":{"strength":18,"agility":18,"constitution":18,"inner":18,"insight":29},"balanced101":{"strength":20,"agility":20,"constitution":20,"inner":20,"insight":21},"balanced201":{"strength":40,"agility":40,"constitution":40,"inner":40,"insight":41},"balanced251":{"strength":50,"agility":50,"constitution":50,"inner":50,"insight":51},"balanced301":{"strength":60,"agility":60,"constitution":60,"inner":60,"insight":61}}
 for e in [yuan,narrow,tak]:
  var total=0
  for value in e.stats.values():total+=int(value)
  check(rules.realm(total)=="일류" and total==(250 if e.id=="mr_exchange" else 300),"requested realm/total")
  check(e.max_hp==rules.max_health(e.stats) and e.constitution==e.stats.constitution,"shared health/defense")
  check(e.defeat_outcome=="nonlethal","story exception unchanged")
  var old=e.duplicate(true)
  old.stats={"strength":12,"agility":12,"constitution":12,"inner":14,"insight":24} if e.id=="mr_exchange" else {"strength":14,"agility":16,"constitution":12,"inner":12,"insight":16}
  old.constitution=12;old.max_hp=rules.max_health(old.stats)
  for profile in builds:
   for skill in ["hoeryu","paak","gwanak","banseok","jungun"]:
    check(preload("res://scripts/martial_arts.gd").new().can_learn(skill,builds[profile]),"legal player learning")
    for policy in ["direct","adaptive"]:
     var result=run_battle(e,builds[profile],skill,policy);result.before=run_battle(old,builds[profile],skill,policy)
     result.profile=profile;result.stats=builds[profile];result.name=e.name;report.append(result)
     check(result.winner>=0 and result.before.winner>=0,"legal fight terminates")
 var f=FileAccess.open("user://yuan_tak_balance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("YUAN_TAK_BALANCE: "+("FAIL" if failed else "PASS")+" / "+str(report.size())+" paired cases; losses preserved")
 quit(1 if failed else 0)
