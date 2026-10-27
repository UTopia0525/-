extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("UI_STATES: "+msg)
func cell(rows: Node,id: String) -> Button:
 for child in rows.get_children():
  if child is Button and child.get_meta("item_id","")==id:return child
 return null
func counter(id: String) -> void:
 for service in game.exploration.city_data.services:
  if service.id==id:game.state="service";game.city_service.open_counter(service);return
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
 var menu=game.player_menu;var p=game.progress
 p.owned_weapons.append("refined_sword");p.inventory.bear_strength_pill=1
 menu.open_menu("inventory");menu.select_category("weapon");menu.select_item("refined_sword")
 var chosen=cell(menu.rows,"refined_sword");var equipped=cell(menu.rows,"plain_iron_sword")
 check(chosen!=null and chosen.get_meta("selected") and not chosen.disabled,"selected inventory row stays enabled")
 check(chosen.get_node("SelectionMark").visible,"selection has non-color marker")
 var selected_color=chosen.get_theme_stylebox("normal").border_color
 check(chosen.get_theme_stylebox("focus").bg_color.a==0 and chosen.get_theme_stylebox("focus").border_color!=selected_color,"focus gold outline independent from teal selection")
 menu.select_item(game.battle.equipped_weapon_id);check(menu.action.disabled and menu.action.text=="장착 중","equipped state separate from selected row")
 menu.select_category("elixir");p.consumed.bear_strength_pill=10;menu.select_item("bear_strength_pill")
 check(not cell(menu.rows,"bear_strength_pill").disabled and menu.action.disabled and menu.detail.get_parsed_text().contains("10/10"),"capped elixir inspectable, execution blocked with visible reason")
 p.consumed.bear_strength_pill=0
 menu.switch_mode("martial");menu.select_item("samjae");menu.select_slot(3)
 check(not menu.slots[3].disabled and menu.slots[3].get_meta("selected"),"target loadout slot selectable")
 game.battle.equip_weapon_item("none");menu.select_item("samjae")
 check(not cell(menu.rows,"samjae").disabled and menu.detail.get_parsed_text().contains("I에서"),"wrong-weapon learned art still inspectable and assignable")
 menu.close_menu();counter("city_artisan");var shop=game.city_service
 check(not shop.tabs[0].disabled and shop.tabs[0].get_meta("selected"),"shop tab selection not disabled")
 game.money=220;shop.select_item("refined_sword")
 check(not cell(shop.rows,"refined_sword").disabled and cell(shop.rows,"refined_sword").get_meta("selected"),"unaffordable/owned stock remains inspectable")
 check(shop.action.disabled and shop.balance_preview.text.contains("80문 부족"),"purchase deficit shown without spending")
 var money=game.money;shop.select_tab(1);shop.select_item("none");check(shop.action.disabled,"already equipped action disabled, not list")
 check(game.money==money,"previews never spend money")
 shop.close_counter();game.start_battle();var b=game.battle
 b.equip_weapon_item("plain_iron_sword");b.select_samjae();b.qi.restore(10,0);await process_frame;await process_frame
 check(not b.select_button.disabled,"unusable combat slot can still be inspected")
 check(b.use_button.disabled and b.note.text.contains("내기 10 부족"),"qi shortage disables only execution")
 var turn=b.turn;var hp=b.enemy_hp;b.select_skill("basic_defense")
 check(b.turn==turn and b.enemy_hp==hp and not b.use_button.disabled,"selection does not execute or spend turn")
 b.equip_weapon_item("none");b.select_samjae();check(b.use_button.disabled and b.note.text.contains("현재 맨손"),"combat weapon mismatch visible")
 b.equip_weapon_item("plain_iron_sword");b.set_loadout(["basic_attack","basic_defense","samjae","josik_suwon"])
 # Find the support ID from catalogue to avoid coupling to a translated display name.
 var support=""
 for id in p.arts.definitions:
  if p.arts.get_skill(id).weapon_style=="support":support=id;break
 if not support.is_empty():
  b.set_loadout(["basic_attack","basic_defense","samjae",support]);b.ready_turns[support]=b.turn+2;b.select_skill(support)
  check(b.use_button.disabled and b.note.text.contains("2턴 뒤"),"cooldown reason remains visible")
 game.reset();game.start_city();game.adventure_ui.open_journal();var journal=game.adventure_ui
 journal.set_filter("available");check(not journal.filter_buttons[1].disabled and journal.filter_buttons[1].get_meta("selected"),"journal current filter enabled and marked")
 var id=journal.entries.keys()[0];journal.select_quest(id)
 var selected_rows=journal.rows.get_children().filter(func(n):return n.get_meta("selected",false))
 check(selected_rows.size()==1 and not selected_rows[0].disabled,"journal inspected quest has independent selection")
 journal.close_menu();game.settings_menu.open_menu();game.settings_menu.set_mode("save")
 check(not game.settings_menu.save_tab.disabled and game.settings_menu.save_tab.get_meta("selected"),"save current tab remains an active tab")
 game.settings_menu.close_menu();game.queue_free();await process_frame
 print("UI_STATES: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
