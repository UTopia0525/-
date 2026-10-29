extends "res://tests/encounter_balance.gd"
func _initialize() -> void:
 var e=JSON.parse_string(FileAccess.get_file_as_string("res://data/cuiyue_incident.json")).encounter
 var model=preload("res://scripts/grid_combat.gd").new()
 for id in e.skills:
  check(model.combat.arts.can_learn(id,e.stats),"enemy learning requirements "+id)
  check(model.combat.arts.can_use_with_weapon(id,"saber"),"enemy weapon matches "+id)
 var builds=[{"strength":14,"agility":14,"constitution":14,"inner":14,"insight":45},{"strength":18,"agility":18,"constitution":18,"inner":18,"insight":29},{"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}]
 for stats in builds:
  for skill in ["hoeryu","paak","gwanak","banseok","jungun"]:
   for policy in ["direct","adaptive"]:
    var result=run_battle(e,stats,skill,policy);result.build=stats;report.append(result)
    check(result.win,"intermediate build wins "+JSON.stringify(result))
 var f=FileAccess.open("user://cuiyue_balance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print(JSON.stringify(report));print("CUIYUE_BALANCE: "+("FAIL" if failed else "PASS")+" / "+str(report.size())+" cases");quit(1 if failed else 0)
