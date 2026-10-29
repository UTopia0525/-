extends "res://tests/encounter_balance.gd"
func _initialize() -> void:
 var e=JSON.parse_string(FileAccess.get_file_as_string("res://data/blackguild_story.json")).encounter
 var model=preload("res://scripts/grid_combat.gd").new()
 for id in e.skills:
  check(model.combat.arts.can_learn(id,e.stats),"enemy can learn "+id)
  check(model.combat.arts.can_use_with_weapon(id,"saber"),"enemy matching weapon")
 for build in [18,40,50,60]:
  var stats={"strength":build,"agility":build,"constitution":build,"inner":build,"insight":29 if build==18 else build+1}
  for skill in ["hoeryu","paak","gwanak","banseok","jungun"]:
   var result=run_battle(e,stats,skill,"adaptive");result.total=build*4+stats.insight;report.append(result)
   check(result.winner>=0,"fight terminates")
 var f=FileAccess.open("res://tests/blackguild-balance-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("BLACKGUILD_BALANCE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
