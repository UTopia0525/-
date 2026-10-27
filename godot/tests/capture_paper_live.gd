extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
 game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20};game.money=1250
 game.progress.owned_weapons.append_array(["refined_sword","thickback_saber","balanced_spear"])
 for id in game.progress.inventory:game.progress.inventory[id]=3
 game.progress.grant_manual("swaerang_manual");game.progress.learned.append_array(["paak","swaerang","gwanak"]);game.progress.assign("swaerang",3)
 game.player_menu.open_menu("inventory");game.player_menu.select_item("refined_sword");await shot("paper-live-inventory")
 game.player_menu.switch_mode("martial");game.player_menu.select_item("swaerang");game.player_menu.select_slot(3);game.player_menu.list_scroll.set_deferred("scroll_vertical",130);await shot("paper-live-martial")
 game.reset();game.queue_free();await process_frame;quit()
