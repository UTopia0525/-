extends SceneTree
var game
var failed=false
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("WUCHANG_LETHAL: "+message)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"])
 game.start_wuchang();check(game.save_system.write_slot(1),"pre-battle save allowed")
 var path=game.save_system.path(1);var saved=FileAccess.get_file_as_string(path)
 for name in ["herbalist_quest","inn_quest","impostor_quest"]:
  game.reset();game.start_wuchang();game.money=321
  var quest=game.get(name);var e=quest.data.encounter
  if name=="herbalist_quest":quest.phase="rescue";quest.battle_active=true
  else:quest.phase="battle"
  check(preload("res://scripts/combat_outcome.gd").defeat_policy(e)=="death","lethal data: "+e.id)
  game.start_battle(e);var b=game.battle;b.animation_time=.01
  var ready_deadline=Time.get_ticks_msec()+4000
  while not b.awaiting_player and game.state=="battle" and Time.get_ticks_msec()<ready_deadline:await create_timer(.02).timeout
  check(b.awaiting_player,"ready for player action")
  b.grid.units[0].position=Vector2i(2,2);b.grid.units[1].position=Vector2i(3,2)
  b.grid.units[0].hp=1;b.player_hp=1;b.grid.units[0].gauge=100;b.grid.units[1].gauge=100
  b.commit("wait")
  var deadline=Time.get_ticks_msec()+5000
  while game.state=="battle" and Time.get_ticks_msec()<deadline:await create_timer(.02).timeout
  check(game.state=="game_over" and b.player_hp==0 and not b.running,"real grid loss reaches game-over: "+e.id)
  check(game.money==321 and not game.exploration.visible and game.dialogue_lines.is_empty(),"no retreat dialogue, exploration or reward")
  check(not game.save_system.write_slot(2),"no saving while dead")
  while not game.death_screen.ready_to_return and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
  check(game.death_screen.ready_to_return,"death animation completes")
  game.death_screen.return_button.pressed.emit();await process_frame
  check(game.state=="title" and game.title_screen.visible,"confirm returns to title: "+e.id)
  check(FileAccess.get_file_as_string(path)==saved,"existing save preserved")
 check(game.save_system.load_slot(1),"pre-battle save still loads")
 for e in game.encounters():
  if e.id in ["bandit_sentry","bandit_ringleader"]:check(e.defeat_outcome=="retry","Changsha retry remains")
  if e.id=="training_student":check(e.defeat_outcome=="nonlethal","training duel remains nonlethal")
 game.reset();await create_timer(.8).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame
 print("WUCHANG_LETHAL: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
