extends SceneTree
var failed=false
func _initialize() -> void:
 var encounters=[JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial_enemy.json"))]
 encounters.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://data/changsha_bandit_story.json")).encounters)
 var output=[]
 for source in encounters:
  var starter=source.id=="tutorial_pirate"
  var level=10 if starter else 20
  for route in (["samjae"] if starter else ["cheongpung","danseok","gwanpung","cheolsan"]):
   var g=preload("res://scripts/grid_combat.gd").new()
   var style=g.combat.arts.get_skill(route).required_weapon_type
   var weapon=g.combat.weapons.DEFAULT_BY_TYPE[style]
   var stats={"strength":level,"agility":level,"constitution":level,"inner":level,"insight":level}
   var enemy_stats=source.get("stats",{"strength":12,"agility":12,"constitution":5,"inner":6,"insight":5})
   g.setup({}, {"stats":stats,"weapon":weapon,"hp":300,"max_hp":300,"skills":[route]}, {"stats":enemy_stats.duplicate(),"weapon":source.get("weapon","thickback_saber"),"hp":source.get("max_hp",150),"max_hp":source.get("max_hp",150),"skills":source.get("skills",["bandit_chop","soemok"])})
   for step in range(800):
    var actor=g.next_actor()
    if actor<0:break
    if actor==0:g.units.reverse()
    var plan=g.enemy_choice()
    if actor==0:g.units.reverse()
    var result=g.perform(actor,plan.id,plan.facing,plan.get("destination",Vector2i(-1,-1)))
    if not result.ok:failed=true;push_error("CAMPAIGN illegal: "+result.reason);break
    if g.winner>=0:break
   output.append({"enemy":source.get("id","tutorial"),"route":route,"winner":g.winner,"hp":g.units[0].hp,"actions":g.units[0].actions})
   if g.winner!=0:failed=true;push_error("GRID_CAMPAIGN failed: "+str(output[-1]))
 print(JSON.stringify(output));print("GRID_CAMPAIGN: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
