extends "res://tests/encounter_balance.gd"
func _initialize() -> void:
 var enemies=[JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial_enemy.json"))]
 for file in ["changsha_bandit_story","wuchang_herbalist_quest","wuchang_duel_quest","wuchang_inn_quest","wuchang_impostor_quest","qingya_quest","nanjing_waterfront_quest","namgung_campaign","murong_quest","cuiyue_incident"]:
  var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+file+".json"))
  enemies.append_array(data.get("encounters",[data.get("encounter",{})]))
 for q in JSON.parse_string(FileAccess.get_file_as_string("res://data/suzhou_quests.json")):
  if q.has("encounter"):enemies.append(q.encounter)
 var murong=enemies.filter(func(e):return e.id=="mr_exchange")[0].duplicate(true)
 murong.name+=" · 좁은 길 재대련";murong.field={"width":7,"height":3,"player_spawn":[1,1],"enemy_spawn":[5,1],"blocked":[[0,0],[0,2],[6,0],[6,2]]};enemies.append(murong)
 check(enemies.size()==15,"fourteen opponents plus narrow-field rematch")
 for e in enemies:
  var tutorial=e.id=="tutorial_pirate";var early=e.id in ["bandit_sentry","bandit_ringleader"]
  var skills=["samjae"] if tutorial else ["cheongpung","yusu","danseok","hoepung","gwanpung","yeonhwan","cheolsan","ungi"] if early else ["hoeryu","paak","gwanak","banseok","jungun"]
  for profile in ["balanced101","quest101"] if not tutorial else ["starting10"]:
   for skill in skills:
    var stats={"strength":10,"agility":10,"constitution":10,"inner":10,"insight":10} if tutorial else {"strength":20,"agility":20,"constitution":20,"inner":20,"insight":21} if profile=="balanced101" else {"strength":18,"agility":18,"constitution":18,"inner":18,"insight":29}
    if early and skill=="cheolsan" and profile=="quest101":stats={"strength":17,"agility":17,"constitution":18,"inner":20,"insight":29}
    if early and skill=="ungi":stats={"strength":16,"agility":16,"constitution":16,"inner":26,"insight":27}
    var arts=preload("res://scripts/martial_arts.gd").new();check(arts.can_learn(skill,stats),"legal player learning "+skill)
    for policy in ["direct","adaptive"]:
     var result=run_battle(e,stats,skill,policy);var before=run_battle(e,stats,skill,policy,true)
     result.profile=profile;result.stats=stats;result.name=e.name;result.before=before
     report.append(result)
     check(result.winner>=0 and before.winner>=0,"simulation terminates "+e.id+"/"+skill)
 var f=FileAccess.open("user://health_growth_balance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("HEALTH_GROWTH_BALANCE: "+("FAIL" if failed else "PASS")+" / "+str(report.size())+" paired cases; losses are recorded, not tuned away")
 quit(1 if failed else 0)
