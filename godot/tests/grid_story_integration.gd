extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
 if not value:failed=true;push_error("GRID_STORY: "+message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"])
 game.start_battle();var b=game.battle;b.animation_time=.01
 for frame in range(300):
  if b.awaiting_player:break
  await process_frame
 check(game.state=="battle" and b.grid!=null and b.grid.field.width==7,"real main starts grid battle")
 check(not game.save_system.write_slot(1),"battle manual save remains blocked")
 b.utility(3);var actions=b.grid.units[0].actions
 var enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;game._input(enter)
 for frame in range(100):
  if b.grid.units[0].actions>actions:break
  await process_frame
 check(b.grid.units[0].actions==actions+1,"main Enter executes selected utility rather than changing it")
 game.settings_menu.open_menu();var tick=b.grid.tick;var hp=b.player_hp
 await create_timer(.2).timeout
 check(b.grid.tick==tick and b.player_hp==hp,"settings pause also pauses grid clock and presentation")
 game.settings_menu.close_menu()
 for frame in range(300):
  if b.awaiting_player:break
  await process_frame
 var hp_before=b.player_hp
 check(preload("res://tests/legacy_save_fixture.gd").write(game,2) and game.save_system.load_slot(2),"old mid-combat save loads into default grid")
 await process_frame
 check(b.grid!=null and b.grid.units[0].hp==hp_before,"legacy save preserves remaining HP")
 b.cancel()
 game.start_battle({"id":"grid_lethal_fixture","name":"검증 상대","max_hp":900,"constitution":20,"stats":{"strength":100,"agility":100,"constitution":20,"inner":100,"insight":10},"weapon":"thickback_saber","skills":["soemok"]})
 b.animation_time=.01;b.grid.units[0].hp=1;b.grid.units[0].position=Vector2i(2,2);b.grid.units[1].position=Vector2i(3,2);b.player_hp=1
 for frame in range(500):
  if game.state=="game_over":break
  await process_frame
 check(game.state=="game_over" and not b.running,"lethal grid defeat reaches original game-over screen")
 game.get_tree().paused=false
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame
 print("GRID_STORY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
