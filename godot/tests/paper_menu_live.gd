extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("PAPER_MENU: "+msg)
func click_at(point: Vector2) -> void:
 var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion);await process_frame
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event);await process_frame
func press(code: int) -> void:
 var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;game._input(event);await process_frame
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
 var p=game.progress;var menu=game.player_menu;p.owned_weapons.append("refined_sword");p.learned.append("swaerang");p.inventory.bear_strength_pill=2;p.grant_manual("swaerang_manual")
 await press(KEY_I);check(menu.visible and not game.exploration.active,"I opens live menu")
 menu.select_category("weapon");await process_frame
 var cell=menu.rows.get_children().filter(func(n):return n is Button and n.get_meta("item_id","")=="refined_sword")[0]
 await click_at(cell.get_global_rect().get_center());check(menu.selected_id=="refined_sword","actual grid click reaches item through icon")
 await click_at(menu.action.get_global_rect().get_center());check(game.battle.equipped_weapon_id=="refined_sword","actual action click equips")
 menu.select_category("elixir");menu.select_item("bear_strength_pill");var before=int(p.stats.strength);await click_at(menu.action.get_global_rect().get_center())
 check(p.inventory.bear_strength_pill==1 and int(p.stats.strength)>before,"consume one using live action")
 await press(KEY_I);await press(KEY_I);check(menu.category=="elixir" and menu.selected_id=="bear_strength_pill","reopen remembers category and item")
 await press(KEY_K);menu.select_item("swaerang");menu.select_slot(3)
 await click_at(menu.action.get_global_rect().get_center());check(p.loadout[3]=="swaerang","actual K action assigns")
 menu.select_filter("saber");check(menu.visible_ids()==["swaerang"],"type filter")
 menu.select_item("clear");menu.action.grab_focus();await press(KEY_ENTER);check(p.loadout[3]=="","keyboard Enter clears selected slot")
 await press(KEY_TAB);check(menu.is_ancestor_of(root.gui_get_focus_owner()),"Tab stays inside menu")
 menu.select_filter("all");menu.select_item("swaerang");menu.select_slot(3);menu.apply_selection();await press(KEY_ESCAPE)
 check(not menu.visible and game.exploration.active,"ESC closes and returns to exploration")
 check(game.save_system.write_slot(8) and game.save_system.load_slot(8),"live possessions and loadout save")
 check(p.loadout[3]=="swaerang" and game.battle.equipped_weapon_id=="refined_sword","equipment and loadout persisted")
 await press(KEY_I);menu.select_category("manual");menu.select_item("swaerang_manual");check(menu.action.disabled and p.manuals.swaerang_manual==1,"known manual cannot be consumed")
 menu.select_category("quest");check(menu.visible_ids().is_empty() and menu.action.disabled,"empty category is safe")
 menu.close_menu();game.queue_free();await process_frame;print("PAPER_MENU_LIVE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
