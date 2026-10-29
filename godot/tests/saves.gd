extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SAVES: " + message)
func drain() -> void:
	var limit := 0
	while not game.dialogue_lines.is_empty() and limit < 350:
		game.advance_dialogue()
		limit += 1
	check(limit < 350, "dialogue continuation terminates")
func settle() -> void:
	drain()
	if game.state == "chapter_transition": await create_timer(2.6).timeout
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var saves = game.save_system
	game.start_story()
	drain()
	game.exploration.player.position = Vector2(640, 395)
	game.interact()
	game.advance_dialogue()
	var text: String = game.dialogue_text.text
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1), "save captain dialogue: " + saves.error)
	game.reset()
	check(saves.load_slot(1), "load dialogue")
	check(game.dialogue_text.text == text and not game.talked_captain, "restore exact line and pre-dialogue flags")
	drain()
	check(game.talked_captain, "restored dialogue runs its named completion")
	game.exploration.load_area("deck")
	game.prologue.after_victory()
	drain()
	check(game.state == "choice", "decision reached")
	game.select_story_choice("treasure")
	check(saves.write_slot(2), "save selected but unconfirmed branch: " + saves.error)
	game.confirm_story_choice()
	var count := 0
	while game.money == 0 and count < 200:
		game.advance_dialogue()
		count += 1
	check(game.money == 500, "treasure paid")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 3), "save after payment during dialogue: " + saves.error)
	await settle()
	check(game.chapter_one.accepted_quests.has("changsha_cloth"), "accepted quest reached")
	game.exploration.player.position = game.exploration.city_point([540, 480])
	game.exploration.camera.snap_to_player()
	check(saves.write_slot(4), "save city and quest")
	check(saves.load_slot(3), "restore mid-sequence after payment")
	await settle()
	check(game.money == 500 and game.state == "explore", "restored continuation never pays twice")
	check(saves.load_slot(2), "rewind to choice")
	check(game.money == 0 and game.prologue.branch == "" and game.pending_choice == "treasure" and game.choice_screen.visible, "unconfirmed choice restored without committing branch")
	game.select_story_choice("rescue")
	game.confirm_story_choice()
	await settle()
	check(game.prologue.branch == "rescue" and game.money == 0, "same decision save can lead to other ending")
	check(saves.write_slot(5), "save rescue in separate slot")
	check(saves.load_slot(4), "load independent treasure city slot")
	check(game.money == 500 and game.prologue.branch == "treasure" and game.chapter_one.accepted_quests.has("changsha_cloth"), "money, branch and quest independent")
	check(game.exploration.player.position.distance_to(game.exploration.city_point([540, 480])) < 0.1, "exact city position restored")
	check(game.quest_navigation.quest_id == "changsha_cloth" and game.chapter_number == 1, "chapter and tracked objective restored")
	# Broken files and unsupported versions never touch current play.
	var file = FileAccess.open(saves.path(6), FileAccess.WRITE)
	file.store_string("{\"schema\":999}")
	file.close()
	check(not saves.load_slot(6) and game.money == 500 and game.state == "explore", "invalid data leaves running game intact")
	# Settings pauses actors and timed chapter cards; closing restores tree processing.
	game.settings_menu.open_menu()
	check(paused and game.settings_menu.window.visible, "settings pauses game")
	game.settings_menu.select_slot(4)
	game.settings_menu.request_action()
	check(game.settings_menu.confirmation.visible, "occupied slot asks before overwrite")
	game.settings_menu.confirmation.hide()
	game.settings_menu.close_menu()
	check(not paused, "settings closes without changing state")
	check(saves.write_slot(4) and FileAccess.file_exists(saves.path(4) + ".bak"), "overwrite uses backup")
	# Combat resumes only at a stable player turn. Busy actions are unsaveable and pause.
	game.start_battle()
	for i in range(4):await process_frame
	game.battle.grid.units[0].position=Vector2i(2,2);game.battle.grid.units[1].position=Vector2i(3,2)
	game.battle.select_samjae()
	var expected_battle_enemy_hp: int=game.battle.enemy_hp
	var expected_battle_player_hp: int=game.battle.player_hp
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 7), "battle between turns saved")
	game.battle.use_selected()
	check(not saves.write_slot(8), "busy battle save disabled")
	game.settings_menu.open_menu()
	var hp: int = game.battle.enemy_hp
	await create_timer(0.8).timeout
	check(game.battle.enemy_hp == hp, "attack timer cannot advance while settings is open")
	game.settings_menu.close_menu()
	check(saves.load_slot(7), "restore player turn and cancel old attack")
	await create_timer(0.8).timeout
	check(game.battle.enemy_hp == expected_battle_enemy_hp and game.battle.player_hp == expected_battle_player_hp and game.battle.selected and game.state == "battle", "old timer cannot damage loaded battle with current derived health")
	# Named boarding and service continuations remain valid after a process-independent load.
	game.start_story()
	drain()
	game.exploration.player.position = Vector2(640, 395)
	game.interact()
	drain()
	game.exploration.player.position = Vector2(810, 410)
	game.interact()
	game.advance_dialogue()
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 9), "save boarding dialogue")
	game.reset()
	check(saves.load_slot(9), "restore boarding dialogue")
	drain()
	check(game.exploration.area_name == "deck", "boarding continuation changes map after load")
	game.start_city()
	for actor in game.exploration.ambient_nodes:
		if actor.get_meta("npc_id") == "city_merchant":
			game.exploration.player.position = actor.position + Vector2(36, 12)
	game.interact()
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 8), "save service greeting")
	game.reset()
	check(saves.load_slot(8), "restore service greeting")
	drain()
	check(game.state == "service" and game.city_service.visible, "service greeting continuation restored")
	game.city_service.select_tab(1)
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 8) and saves.load_slot(8), "save and load inside service")
	check(game.city_service.selected_tab == 1, "service tab restored")
	game.reset()
	check(not saves.write_slot(10), "title cannot overwrite saves")
	check(saves.read_slot(2).state == "choice" and saves.read_slot(5).prologue.branch == "rescue", "separate historical moments survive later writes")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.save_system.load_slot(2) and game.state == "choice" and game.prologue.branch == "", "fresh game instance reconstructs saved decision")
	game.select_story_choice("rescue")
	game.confirm_story_choice()
	await settle()
	check(game.prologue.branch == "rescue" and game.money == 0 and game.chapter_one.intro_complete, "fresh instance continuations finish alternative branch")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_SAVES: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
