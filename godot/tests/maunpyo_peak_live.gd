extends "res://tests/namgung_campaign.gd"
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"])
 for amount in [20,40]:
  game.reset();game.start_wuchang();prerequisites()
  game.progress.stats={"strength":amount,"agility":amount,"constitution":amount,"inner":amount,"insight":amount+1}
  game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""]
  var q=game.namgung_campaign;q.phase="battle";game.start_battle(q.data.encounter)
  var b=game.battle;b.animation_time=.01
  check(b.enemy_max_hp==875 and b.enemy_stats.constitution==80,"real battle loads peak stats and health")
  check(b.grid.support.intercept_percent==65 and b.grid.support.attack_raw==240,"existing support unchanged")
  check(not game.save_system.write_slot(1),"battle save remains forbidden")
  var deadline=Time.get_ticks_msec()+20000
  while game.state=="battle" and Time.get_ticks_msec()<deadline:
   if b.awaiting_player and not b.busy:
    var plan=preload("res://scripts/grid_tactical_ai.gd").choose(b.grid,0);b.facing=plan.facing;b.commit(plan.id,plan.get("destination",Vector2i(-1,-1)))
   await create_timer(.01).timeout
  if amount==20:
   check(game.state=="game_over" and game.death_screen.visible,"early build still uses lethal outcome")
   check(game.progress.inventory[PILL]==0,"loss grants no reward")
  else:
   await settle()
   check(q.phase=="report" and game.state=="explore","grown build victory continues campaign")
   check(game.progress.inventory[PILL]==0,"victory still requires report before reward")
 game.reset();game.queue_free();await process_frame
 print("MAUNPYO_PEAK_LIVE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
