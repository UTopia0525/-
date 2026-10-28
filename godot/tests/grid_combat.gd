extends SceneTree
var failed=false
const Grid=preload("res://scripts/grid_combat.gd")
func check(value: bool,message: String) -> void:
 if not value:failed=true;push_error("GRID_COMBAT: "+message)
func fixture(config: Dictionary={}) -> RefCounted:
 var stats={"strength":20,"agility":50,"constitution":20,"inner":20,"insight":20}
 var g=Grid.new();g.setup(config,{"stats":stats.duplicate(),"weapon":"plain_iron_sword","hp":300,"max_hp":300,"skills":["samjae","josik_suwon","cheongpung"]},{"stats":stats.duplicate(),"weapon":"thickback_saber","hp":500,"max_hp":500,"skills":["soemok"]});return g
func _initialize() -> void:
 var damages=[]
 for agility in [0,100]:
  var basic=fixture({"player_spawn":[2,2],"enemy_spawn":[3,2]})
  for index in range(2):
   basic.units[index].stats.agility=agility;basic.units[index].gauge=100
   check(basic.combat.action("basic_attack",basic.units[index].stats,basic.units[index].weapon).raw==40,"both actors use strength+inner without agility")
  damages.append([basic.perform(0,"basic_attack",Vector2i.RIGHT).damage,basic.perform(1,"basic_attack",Vector2i.LEFT).damage])
 check(damages[0]==damages[1],"agility changes action timing, not actual basic attack damage on either side")
 var g=fixture();g.units[1].stats.agility=40
 check(g.field.width==7 and g.field.height==5,"default field7x5")
 check(g.next_actor()==0 and g.tick==2 and g.units[0].gauge==120 and g.units[1].gauge==100,"50/40 agility recharges60/50 each beat")
 var move=g.perform(0,"move",Vector2i.RIGHT,Vector2i(2,2));check(move.ok and g.units[0].gauge==100,"120 move20 leaves100 ready")
 check(g.next_actor()==0,"the ready actor can continue at100 before yielding")
 check(g.perform(0,"move",Vector2i.RIGHT,Vector2i(3,2)).ok and g.units[0].gauge==80,"100 can move once then cannot act at80")
 check(not g.perform(0,"basic_defense",Vector2i.RIGHT).ok,"every new action checks100")
 g=fixture({"player_spawn":[2,2],"enemy_spawn":[3,2]});g.units[0].gauge=200;g.units[1].gauge=300
 check(g.perform(0,"samjae",Vector2i.RIGHT).ok and g.units[0].guard==20,"sword grants guard")
 var hp=g.units[0].hp
 var a=g.perform(1,"basic_attack",Vector2i.LEFT);var b=g.perform(1,"basic_attack",Vector2i.LEFT)
 check(a.ok and b.ok and a.guard_used==20 and b.guard_used==20 and g.units[0].guard==20 and g.units[0].hp<hp,"guard mitigates every enemy attack until next own action")
 check(g.perform(0,"wait",Vector2i.RIGHT).ok and g.units[0].guard==0,"next own movement/wait expires old guard")
 g=fixture({"width":9,"height":6,"blocked":[[3,2]],"player_spawn":[2,2],"enemy_spawn":[4,2]});g.units[0].gauge=100
 check(g.field.width==9 and g.field.height==6 and not g.perform(0,"move",Vector2i.RIGHT,Vector2i(3,2)).ok,"custom sizes and blocked movement")
 check(not g.perform(0,"cheongpung",Vector2i.RIGHT).ok and g.units[0].gauge==100 and g.units[0].qi==20,"blocked composite action spends nothing")
 check(not g.field.sight(Vector2i(2,2),Vector2i(4,2)),"walls block attacks")
 check(not g.field.sight(Vector2i(2,2),Vector2i(3,3)),"diagonal attacks cannot cut through a blocked corner")
 g.units[1].gauge=100;var path_plan=g.enemy_choice();check(path_plan.id=="move" and path_plan.destination!=Vector2i(3,2),"AI paths around blocked cells")
 g=fixture({"player_spawn":[2,2],"enemy_spawn":[3,2]});g.units[0].gauge=100
 check(g.perform(0,"josik_suwon",Vector2i.RIGHT).ok and g.units[0].qi==80,"support restores2inner plus normal action recovery")
 check(not g.perform(0,"josik_suwon",Vector2i.RIGHT).ok,"cooldown begins on commit")
 for step in range(3):g.units[0].gauge=100;check(g.perform(0,"wait",Vector2i.RIGHT).ok,"cooldown progresses by actual own actions")
 g.units[0].gauge=100;check(g.perform(0,"josik_suwon",Vector2i.RIGHT).ok,"support reusable after three other actions")
 g=fixture({"player_spawn":[2,2],"enemy_spawn":[2,3]});g.units[0].gauge=100
 check(g.perform(0,"samjae",Vector2i.DOWN).ok,"rotated attack footprint can hit to the south")
 g=fixture({"width":2,"height":2,"blocked":[[0,0],[1,0],[0,1],[1,1]]})
 check(g.units[0].position!=g.units[1].position and g.field.walkable(g.units[0].position) and g.field.walkable(g.units[1].position),"tiny malformed field still provides distinct valid spawns")
 var wins=0
 for weapon in ["plain_iron_sword","thickback_saber","balanced_spear","none"]:
  var skill={"plain_iron_sword":"hoeryu","thickback_saber":"paak","balanced_spear":"gwanak","none":"banseok"}[weapon]
  g=fixture();g.units[0].weapon=weapon;g.units[0].skills=[skill];g.units[1].stats.agility=20
  for step in range(300):
   var actor=g.next_actor()
   if actor<0:break
   if actor==1:
    var plan=g.enemy_choice();check(g.perform(1,plan.id,plan.facing,plan.get("destination",Vector2i(-1,-1))).ok,"AI commits a legal transaction")
   else:
    var committed=false
    for facing in g.DIRECTIONS:
     for id in [skill,"basic_attack"]:
      if g.problem(0,id,facing).is_empty():g.perform(0,id,facing);committed=true;break
     if committed:break
    if not committed:
     var dir=Vector2i(signi(g.units[1].position.x-g.units[0].position.x),0)
     if dir==Vector2i.ZERO:dir=Vector2i(0,signi(g.units[1].position.y-g.units[0].position.y))
     if g.problem(0,"move",dir,g.units[0].position+dir).is_empty():g.perform(0,"move",dir,g.units[0].position+dir)
     else:g.perform(0,"wait",Vector2i.RIGHT)
   if g.winner>=0:break
  if g.winner==0:wins+=1
 check(wins==4,"four weapon routes finish actual grid battles")
 print("GRID_COMBAT: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
