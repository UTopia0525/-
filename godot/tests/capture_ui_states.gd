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
 var p=game.progress;p.owned_weapons.append_array(["refined_sword","thickback_saber","balanced_spear"]);p.inventory.bear_strength_pill=1;p.learned.append("josik_suwon");p.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
 game.player_menu.open_menu("inventory");game.player_menu.select_item("refined_sword");await shot("ui-states-inventory")
 game.player_menu.close_menu();p.consumed.bear_strength_pill=10;p.inventory.bear_strength_pill=0
 for service in game.exploration.city_data.services:
  if service.id=="city_merchant":game.state="service";game.city_service.open_counter(service)
 game.city_service.select_item("bear_strength_pill");await shot("ui-states-limit");game.city_service.close_counter();p.consumed.bear_strength_pill=0;p.inventory.bear_strength_pill=1
 game.player_menu.open_menu("martial");game.player_menu.select_item("samjae");game.player_menu.select_slot(3);await shot("ui-states-martial");game.player_menu.close_menu()
 game.money=220;p.owned_weapons.erase("thickback_saber")
 for service in game.exploration.city_data.services:
  if service.id=="city_artisan":game.state="service";game.city_service.open_counter(service)
 game.city_service.select_item("thickback_saber");await shot("ui-states-trade");game.city_service.close_counter()
 game.start_battle();game.battle.select_samjae();game.battle.qi.restore(10,2);await shot("ui-states-battle")
 game.reset();game.start_city();game.adventure_ui.open_journal();game.adventure_ui.set_filter("available");game.adventure_ui.select_quest(game.adventure_ui.entries.keys()[0]);await shot("ui-states-journal")
 game.queue_free();await process_frame;quit()
