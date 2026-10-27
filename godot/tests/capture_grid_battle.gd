extends SceneTree
var b
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);b=load("res://scenes/battle.tscn").instantiate();root.add_child(b);await process_frame
 b.player_stats={"strength":20,"agility":50,"constitution":20,"inner":20,"insight":20}
 b.set_loadout(["basic_attack","basic_defense","hoeryu","josik_suwon"])
 b.set_encounter({"name":"청애채 산적","max_hp":500,"constitution":20,"stats":{"strength":20,"agility":40,"constitution":20,"inner":18,"insight":12},"weapon":"thickback_saber","skills":["soemok"],"field":{"player_spawn":[2,2],"enemy_spawn":[4,2]}})
 b.begin();await process_frame;await process_frame;b.select_skill("hoeryu");await shot("grid-battle-720")
 root.size=Vector2i(2560,1440);await shot("grid-battle-1440")
 root.size=Vector2i(1280,720);b.cancel();b.set_encounter({"name":"협로의 무사","max_hp":500,"constitution":20,"stats":{"strength":20,"agility":40,"constitution":20,"inner":18,"insight":12},"weapon":"thickback_saber","skills":["soemok"],"field":{"width":9,"height":6,"blocked":[[4,1],[4,2],[4,4]],"terrain":[{"cell":[2,3],"name":"풀밭","color":"557c5444"}]}});b.begin();await process_frame;await process_frame;await shot("grid-battle-variable")
 b.cancel();b.queue_free();await process_frame;print("GRID_CAPTURE: PASS");quit()
