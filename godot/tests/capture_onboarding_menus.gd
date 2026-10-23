extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func drain() -> void:
 while not game.dialogue_lines.is_empty(): game.advance_dialogue()
func approach(id: String) -> void:
 for actor in game.exploration.ambient_nodes:
  if actor.get_meta("npc_id") != id: continue
  game.exploration.player.position = actor.position + Vector2(36, 12)
  game.exploration.camera.snap_to_player()
  return
func shot(name: String) -> void:
 await create_timer(0.2).timeout
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/" + name + ".png") == OK)
func run() -> void:
 root.size = Vector2i(1280, 720)
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_city()
 # UI capture fixture mirrors the treasure arrival; no change to new-game possessions.
 game.money = 3000
 game.chapter_number = 1
 game.chapter_one.intro_started = true
 game.chapter_one.intro_complete = true
 game.chapter_one.banner_shown = true
 game.chapter_one.accepted_quests.changsha_cloth = {"status":"active", "stage":"deliver"}
 game.quest_navigation.track("changsha_cloth", "deliver")
 await physics_frame
 for id in ["city_merchant", "city_artisan", "city_instructor"]:
  approach(id)
  game.interact()
  if id == "city_merchant":
   for i in range(3): game.advance_dialogue()
   await shot("trade-intro-merchant")
  drain()
  if id == "city_merchant":
   for pill in ["light_step_pill", "qi_nourishing_pill"]:
    game.city_service.select_item(pill); game.city_service.transact()
  elif id == "city_artisan":
   game.city_service.select_item("refined_sword"); game.city_service.transact()
  else:
   game.city_service.select_item("cheongpung"); game.city_service.transact()
   await shot("trade-intro-instructor")
  game.city_service.close_counter()
  if id == "city_merchant":
   game.player_menu.open_menu("inventory")
   game.player_menu.select_category("elixir")
   game.player_menu.select_item("light_step_pill")
   await shot("inventory-elixirs")
   game.player_menu.apply_selection()
   game.player_menu.select_item("qi_nourishing_pill"); game.player_menu.apply_selection()
   game.player_menu.close_menu()
  elif id == "city_artisan":
   game.player_menu.open_menu("inventory")
   game.player_menu.select_item("refined_sword"); game.player_menu.apply_selection()
   await shot("inventory-weapons")
   game.player_menu.close_menu()
 game.player_menu.open_menu("martial")
 game.player_menu.select_item("cheongpung"); game.player_menu.select_slot(1); game.player_menu.apply_selection()
 await shot("martial-loadout")
 game.reset()
 await create_timer(1.0).timeout
 for voice in game.music.players: voice.stop(); voice.stream = null
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 print("ONBOARDING_MENUS_CAPTURE: PASS")
 quit()
