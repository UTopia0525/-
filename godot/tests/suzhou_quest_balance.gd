extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/suzhou_quests.json"))
 var arts=preload("res://scripts/martial_arts.gd").new()
 var weapons=preload("res://scripts/weapons.gd").new()
 var report=[]
 for spec in data:
  if not spec.has("encounter"):continue
  var e: Dictionary=spec.encounter
  for skill in ["hoeryu","paak","gwanak","banseok","jungun"]:
   var stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20};var weapon=weapons.DEFAULT_BY_TYPE[arts.get_skill(skill).required_weapon_type]
   var g=preload("res://scripts/grid_combat.gd").new()
   g.setup({}, {"stats":stats,"weapon":weapon,"hp":300,"max_hp":300,"skills":["basic_attack","basic_defense",skill]}, {"stats":e.stats.duplicate(),"weapon":e.weapon,"hp":e.max_hp,"max_hp":e.max_hp,"skills":e.skills.duplicate(),"ai":e.ai})
   for i in range(800):
    var actor=g.next_actor()
    if actor<0:break
    var plan=preload("res://scripts/grid_tactical_ai.gd").choose(g,actor)
    var event=g.perform(actor,plan.id,plan.facing,plan.get("destination",Vector2i(-1,-1)))
    if not event.ok:failed=true;push_error("illegal simulated action");break
    if g.winner>=0:break
   report.append({"encounter":e.id,"skill":skill,"win":g.winner==0,"hp":g.units[0].hp})
   if g.winner!=0:failed=true;push_error("SUZHOU_BALANCE: "+e.id+"/"+skill)
 print("SUZHOU_BALANCE "+JSON.stringify(report));quit(1 if failed else 0)
