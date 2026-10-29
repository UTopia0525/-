extends "res://tests/encounter_balance.gd"
func _initialize() -> void:
 var e=JSON.parse_string(FileAccess.get_file_as_string("res://data/namgung_campaign.json")).encounter
 var rules=preload("res://scripts/rules.gd")
 var total=0
 for value in e.stats.values():total+=int(value)
 check(rules.realm(total)=="절정" and total==310,"outer-strength focused peak realm")
 check(e.max_hp==rules.max_health(e.stats) and e.constitution==e.stats.constitution,"shared derived health and defense")
 var old=e.duplicate(true);old.stats={"strength":32,"agility":24,"constitution":30,"inner":26,"insight":25};old.constitution=30;old.max_hp=466
 var builds={"quest101":{"strength":18,"agility":18,"constitution":18,"inner":18,"insight":29},"balanced101":{"strength":20,"agility":20,"constitution":20,"inner":20,"insight":21},"balanced201":{"strength":40,"agility":40,"constitution":40,"inner":40,"insight":41},"balanced301":{"strength":60,"agility":60,"constitution":60,"inner":60,"insight":61}}
 for profile in builds:
  for support in [true,false]:
   var opponent=e.duplicate(true);var previous=old.duplicate(true)
   if not support:opponent.erase("support");previous.erase("support")
   for skill in ["hoeryu","paak","gwanak","banseok","jungun"]:
    check(preload("res://scripts/martial_arts.gd").new().can_learn(skill,builds[profile]),"player can learn selected art")
    for policy in ["direct","adaptive"]:
     var result=run_battle(opponent,builds[profile],skill,policy)
     result.before=run_battle(previous,builds[profile],skill,policy)
     result.stats=builds[profile];result.profile=profile;result.support=support;report.append(result)
     check(result.winner>=0 and result.before.winner>=0,"both fights terminate")
 var f=FileAccess.open("user://maunpyo_peak_balance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("MAUNPYO_PEAK_BALANCE: "+("FAIL" if failed else "PASS")+" / "+str(report.size())+" paired cases; losses preserved")
 quit(1 if failed else 0)
