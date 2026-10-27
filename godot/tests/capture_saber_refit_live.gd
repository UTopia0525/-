extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
 var id: String=game.battle.weapons.DEFAULT_BY_TYPE.saber
 if id not in game.progress.owned_weapons:game.progress.owned_weapons.append(id)
 game.player_menu.open_menu("inventory");game.player_menu.select_category("weapon");game.player_menu.select_item(id);game.player_menu.apply_selection();game.player_menu.close_menu()
 var p=game.exploration.player;var origin=p.position
 for facing in ["down","left","right","up"]:
  p.position=origin
  Input.action_press("move_"+facing)
  for i in range(10):await physics_frame
  Input.action_release("move_"+facing)
  await physics_frame;await physics_frame
  game.exploration.camera.snap_to_player()
  game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
  await create_timer(.15).timeout;await RenderingServer.frame_post_draw
  print("LIVE_SABER ",facing," weapon=",p.equipped_weapon_type," offset=",p.carried_equipment.sprite.offset," strap=",p.carried_equipment.back_strap)
  root.get_texture().get_image().save_png("res://screenshots/saber-refit-live-"+facing+".png")
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;quit()
