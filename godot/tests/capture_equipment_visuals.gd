extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide();game.adventure_ui.notification_waiting=false
 await create_timer(.25).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"])
 for kind in ["sword","saber","spear","none"]:
  game.start_city();var id: String=game.progress.weapons.DEFAULT_BY_TYPE[kind]
  if id!="none" and id not in game.progress.owned_weapons:game.progress.owned_weapons.append(id)
  game.battle.equip_weapon_item(id);game.exploration.player.facing="down";game.exploration.player.stop();game.exploration.camera.snap_to_player()
  await shot("equipment-field-"+kind)
  game.start_battle();await shot("equipment-battle-"+kind)
 game.queue_free();await process_frame;quit()
