extends SceneTree
var b
var failed=false
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
 if not value:failed=true;push_error("OPPONENT_FACING: "+message)
func wait_player() -> void:
 for frame in range(300):
  if b.awaiting_player:return
  await process_frame
 check(false,"player regains control")
func signs(value: float,message: String) -> void:
 check(signf(b.player_actor.scale.x)==value and signf(b.enemy_actor.scale.x)==value,message)
func run() -> void:
 b=load("res://scenes/battle.tscn").instantiate();root.add_child(b);await process_frame;b.animation_time=.12
 b.player_stats={"strength":20,"agility":50,"constitution":20,"inner":20,"insight":20}
 b.set_encounter({"max_hp":999,"constitution":20,"stats":{"strength":10,"agility":10,"constitution":20,"inner":10,"insight":10},"weapon":"thickback_saber","skills":["soemok"],"field":{"player_spawn":[2,2],"enemy_spawn":[3,1]}})
 b.begin();await wait_player();signs(1,"normal left/right face one another")
 var size=b.player_actor.scale.abs();var enemy_size=b.enemy_actor.scale.abs()
 b.facing=Vector2i.LEFT;b.grid.units[1].facing=Vector2i.RIGHT;b.refresh_grid();signs(1,"changing skill directions does not turn either actor away")
 b.grid.units[0].gauge=200;b.facing=Vector2i.RIGHT;b.commit("move",Vector2i(3,2));await wait_player();signs(1,"same column retains previous relationship")
 b.commit("move",Vector2i(4,2));await wait_player();signs(-1,"player crossing to the right mirrors both actors")
 check(b.player_actor.scale.abs().is_equal_approx(size) and b.enemy_actor.scale.abs().is_equal_approx(enemy_size),"mirroring keeps displayed size")
 # Execute two enemy moves without running its scheduler to isolate crossing behavior.
 b.grid.units[1].gauge=200;b.busy=true
 var event=b.grid.perform(1,"move",Vector2i.RIGHT,Vector2i(4,1));check(event.ok,"enemy step legal");await b._present(event,b.generation);signs(-1,"enemy same column retains facing")
 event=b.grid.perform(1,"move",Vector2i.RIGHT,Vector2i(5,1));check(event.ok,"enemy crossing step legal");await b._present(event,b.generation);b.busy=false;b.refresh_grid();signs(1,"enemy crossing also mirrors both actors")
 for weapon in ["sword","saber","spear","none"]:
  b.player_actor.set_weapon(weapon);b.enemy_actor.set_weapon(weapon)
  for pose in ["ready","windup","strike","hit"]:
   b.player_actor.set_pose(pose);b.enemy_actor.set_pose(pose);b.refresh_grid();signs(1,"weapon/pose retains relative facing: "+weapon+"/"+pose)
 b.cancel();b.begin();await wait_player();signs(1,"new battle resets horizontal relationship")
 b.cancel();b.queue_free();await process_frame;print("OPPONENT_FACING: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
