extends SceneTree
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SAVE_RESTRICTIONS: "+message)
func drain() -> void:
	var count := 0
	while not game.dialogue_lines.is_empty() and count < 350:
		game.advance_dialogue();count += 1
	check(count < 350,"dialogue terminates")
func reject(label: String) -> void:
	var saves = game.save_system
	var before := FileAccess.get_file_as_string(saves.path(1))
	var backup := FileAccess.get_file_as_string(saves.path(1)+".bak")
	game.settings_menu.open_menu()
	game.settings_menu.select_slot(1)
	check(game.settings_menu.action.disabled and not game.settings_menu.status.text.is_empty(),label+" explains disabled save")
	game.settings_menu.request_action()
	check(not game.settings_menu.confirmation.visible,label+" cannot open overwrite confirmation")
	check(not saves.write_slot(1) and not saves.error.is_empty(),label+" rejects direct overwrite")
	check(not saves.write_slot(10) and not FileAccess.file_exists(saves.path(10)),label+" cannot create a new slot")
	game.settings_menu.perform_action()
	check(FileAccess.get_file_as_string(saves.path(1))==before and FileAccess.get_file_as_string(saves.path(1)+".bak")==backup,label+" leaves save and backup untouched")
	game.settings_menu.set_mode("load")
	check(not game.settings_menu.action.disabled,label+" still permits loading")
	game.settings_menu.close_menu()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city()
	var saves=game.save_system
	check(saves.write_slot(1) and saves.write_slot(1),"exploration saves and backs up")
	game.start_story();reject("opening dialogue");drain()
	game.say([["hero","강호의 길은 멀구나."]]);reject("conversation during exploration");drain()
	check(saves.write_slot(2),"saving re-enabled after dialogue")
	game.start_city()
	for service in game.exploration.city_data.services:
		if service.id=="city_artisan":
			game.state="service";game.city_service.open_counter(service)
	reject("trading")
	game.city_service.close_counter()
	check(saves.write_slot(3),"saving re-enabled after counter closes")
	game.start_battle();reject("player turn")
	game.battle.select_samjae();game.battle.use_selected();reject("attack animation")
	check(saves.load_slot(1) and game.state=="explore" and not game.battle.busy,"load cancels interrupted battle")
	game.start_story();drain()
	game.exploration.load_area("deck");game.prologue.after_victory();drain()
	check(game.state=="choice" and saves.write_slot(4),"branch decision remains saveable")
	game.select_story_choice("treasure")
	check(saves.load_slot(4) and game.state=="choice" and game.prologue.branch=="","choice save rewinds branch")
	game.reset();await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_SAVE_RESTRICTIONS: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
