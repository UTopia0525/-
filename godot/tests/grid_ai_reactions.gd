extends SceneTree
var failed=false
func check(ok: bool,label: String) -> void:
 if not ok:failed=true;push_error("AI_REACTIONS: "+label)
func _initialize() -> void:
 var g=preload("res://scripts/grid_combat.gd").new()
 var stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
 g.setup({"player_spawn":[2,2],"enemy_spawn":[3,2]}, {"stats":stats.duplicate(),"weapon":"thickback_saber","hp":999,"max_hp":999,"skills":["paak"]}, {"stats":stats.duplicate(),"weapon":"thickback_saber","hp":300,"max_hp":300,"skills":["danseok"],"ai":{"style":"adaptive"}})
 g.units[1].gauge=120;g.units[1].qi=100
 var before=g.units.duplicate(true);var plan=g.enemy_choice()
 check(g.units==before,"thinking preserves resources, cooldowns, position and guard")
 g.units[0].skills=["swaerang"]
 check(g.enemy_choice()==plan,"unseen player skill selection/loadout does not alter decision")
 g.units[0].hp=1;plan=g.enemy_choice();check(plan.id=="basic_attack","use cheap finishing blow")
 g.units[0].hp=999;g.units[0].guard=20;plan=g.enemy_choice();check(plan.id=="basic_attack","avoid wasting heavy qi against active guard")
 g.units[0].guard=0;g.units[1].hp=10;g.units[1].observed_skills=["paak"];plan=g.enemy_choice()
 check(plan.id in ["move","basic_defense"],"respond to witnessed lethal attack with evasion/guard")
 check(g.problem(1,plan.id,plan.facing,plan.get("destination",Vector2i(-1,-1))).is_empty(),"chosen defensive response is legal")
 g.units[1].observed_skills=[]
 check(g.units[0].observed_skills.is_empty(),"observations belong to the observer")
 g.units[0].skills=["paak"];g.units[0].gauge=120;g.units[0].qi=100;check(g.perform(0,"paak",Vector2i.RIGHT).ok,"player commits an observable technique")
 check("paak" in g.units[1].observed_skills and "paak" not in g.units[0].observed_skills,"only executed techniques become known to opponent")
 print("AI_REACTIONS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
