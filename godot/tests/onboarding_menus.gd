extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 if not ok: failed = true; push_error("ONBOARDING_MENUS: " + message)
func key(code: Key) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = true
 game._input(event)
func drain() -> void:
 var guard := 0
 while not game.dialogue_lines.is_empty() and guard < 100:
  game.advance_dialogue()
  guard += 1
 check(guard < 100, "finite dialogue")
func approach(id: String) -> void:
 for actor in game.exploration.ambient_nodes:
  if actor.get_meta("npc_id") != id: continue
  var path: PackedVector2Array = game.exploration.path_to(actor.position, true)
  check(not path.is_empty(), "reachable guide: " + id)
  for point in path: game.exploration.player.move_and_collide(point - game.exploration.player.position)
  check(game.exploration.nearest().get("id", "") == id, "guide available with F: " + id)
  return
 check(false, "missing guide")
func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_city()
 game.chapter_number = 1
 game.chapter_one.intro_started = true
 game.chapter_one.intro_complete = true
 game.chapter_one.banner_shown = true
 game.chapter_one.accepted_quests.changsha_cloth = {"status":"active", "stage":"deliver"}
 game.quest_navigation.track("changsha_cloth", "deliver")
 await physics_frame
 await physics_frame
 var menu = game.player_menu
 key(KEY_I)
 check(menu.visible and menu.mode == "inventory" and not game.exploration.active, "I opens inventory and stops exploration")
 game.toggle_city_map()
 check(not game.city_overview.visible, "map cannot overlap inventory")
 key(KEY_K)
 check(menu.visible and menu.mode == "martial", "K switches to learned arts")
 key(KEY_K)
 check(not menu.visible and game.exploration.active, "same shortcut closes menu")
 var expected_money := [100, 250, 450]
 var expected_insight := [12, 14, 16]
 for i in range(3):
  var id: String = ["city_merchant", "city_artisan", "city_instructor"][i]
  approach(id)
  game.interact()
  check(not game.dialogue_lines.is_empty(), "guide dialogue starts")
  key(KEY_I)
  check(not menu.visible, "inventory cannot interrupt dialogue")
  check(preload("res://tests/legacy_save_fixture.gd").write(game, 1) and game.save_system.load_slot(1), "guide dialogue can save and restore")
  drain()
  check(game.city_service.visible and game.state == "service", "guide opens real shop")
  check(game.money == expected_money[i] and game.progress.stats.insight == expected_insight[i], "unchanged money and insight reward")
  var completed: Array = game.trade_intro.completed.duplicate()
  game.trade_intro._finish_visit()
  check(game.money == expected_money[i] and game.trade_intro.completed == completed, "stale callback cannot award next quest")
  check(preload("res://tests/legacy_save_fixture.gd").write(game, 2) and game.save_system.load_slot(2), "reward and shop survive saving")
  check(game.trade_intro.completed.size() == i + 1 and game.money == expected_money[i], "reward not duplicated on load")
  game.city_service.close_counter()
  check(game.quest_navigation.quest_id == (["changsha_dishes", "changsha_handle", ""][i]), "next guide tracked or cleared")
 check(game.trade_intro.quest_items().is_empty() and game.chapter_one.accepted_quests.size() == 3, "all three deliveries completed")
 for record in game.chapter_one.accepted_quests.values(): check(record == {"status":"completed", "stage":"done"}, "completed quest state")
 # Buy a real weapon, then equip it only via I, without fixture money or possessions.
 approach("city_artisan")
 game.interact(); drain()
 game.city_service.select_item("refined_sword")
 game.city_service.transact()
 game.city_service.close_counter()
 check(game.money == 150 and game.battle.equipped_weapon_id == "plain_iron_sword", "purchase uses money but not autoequip")
 key(KEY_I)
 menu.select_item("refined_sword")
 menu.apply_selection()
 check(game.battle.equipped_weapon_id == "refined_sword", "I equips owned weapon")
 menu.select_item("none"); menu.apply_selection()
 check(game.battle.equipped_weapon_type == "none", "I permits empty hands")
 menu.select_item("refined_sword"); menu.apply_selection()
 key(KEY_ESCAPE)
 check(not menu.visible and not game.settings_menu.window.visible and game.exploration.active, "escape closes inventory before settings")
 approach("city_merchant")
 game.interact(); drain()
 game.city_service.select_item("bear_strength_pill"); game.city_service.transact()
 game.city_service.close_counter()
 key(KEY_I)
 menu.select_category("elixir"); menu.select_item("bear_strength_pill"); menu.apply_selection()
 check(game.progress.stats.strength == 13 and game.progress.stats.insight == 16 and game.progress.consumed.bear_strength_pill == 1, "I consumes a purchased elixir with no insight gain")
 key(KEY_K)
 check(menu.mode == "martial", "shortcut switches without releasing movement")
 menu.select_item("samjae"); menu.select_slot(3); menu.apply_selection()
 check(game.progress.loadout == ["basic_attack", "basic_defense", "", "samjae"], "K moves a learned art without duplicates")
 menu.select_item("clear"); menu.apply_selection()
 check(game.progress.loadout == ["basic_attack", "basic_defense", "", ""], "K clears only configurable slots")
 menu.select_item("samjae"); menu.select_slot(0); menu.apply_selection()
 key(KEY_ESCAPE)
 check(game.save_system.write_slot(3) and game.save_system.load_slot(3), "equipment, consumption, loadout and chain persist")
 check(game.battle.equipped_weapon_id == "refined_sword" and game.progress.loadout[0] == "samjae" and game.money == 50, "restored actual purchases and menu choices")
 var legacy: Dictionary = game.save_system.capture()
 legacy.erase("trade_intro")
 legacy.chapter_one.accepted_quests = {"changsha_cloth":{"status":"active", "stage":"deliver"}}
 check(game.save_system.validate(legacy), "old schema3 without guide state stays valid")
 var old_file = FileAccess.open(game.save_system.path(4), FileAccess.WRITE)
 old_file.store_string(JSON.stringify(legacy))
 old_file.close()
 check(game.save_system.load_slot(4) and game.quest_navigation.get_goal(game.exploration).goal_id == "city_merchant", "old saves resume with the updated shop destination")
 check(not game.trade_intro.valid({"completed":["changsha_dishes"]}), "out-of-order guide completion rejected")
 game.start_battle()
 key(KEY_I); key(KEY_K)
 check(not menu.visible and game.state == "battle", "equipment and loadout cannot change during battle")
 check(game.battle.loadout == ["samjae", "basic_defense", "", ""] and game.battle.skill_buttons[1].text.contains("기본방어"), "battle uses four freely configurable actions")
 game.reset()
 check(game.trade_intro.completed.is_empty() and not menu.visible, "new game clears guide and menu")
 await create_timer(1.0).timeout
 for voice in game.music.players: voice.stop(); voice.stream = null
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 print("GODOT_ONBOARDING_MENUS: " + ("FAIL" if failed else "PASS — zero-fund chain, rewards, I/K, purchases, persistence, modal gates"))
 quit(1 if failed else 0)
