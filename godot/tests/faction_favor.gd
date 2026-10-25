extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("FACTION_FAVOR: "+message)
func drain() -> void:
	for i in range(80):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func press(code: int) -> void:
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
		Input.parse_input_event(e);await process_frame
func label_text() -> String:return game.adventure_ui.rows.get_child(0).get_child(0).text
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"])
	await press(KEY_R);check(not game.adventure_ui.window.visible,"R blocked on title")
	game.start_wuchang();await press(KEY_R)
	check(game.adventure_ui.window.visible and game.adventure_ui.mode=="favor" and paused,"R opens dedicated paused menu")
	check(game.adventure_ui.rows.get_child_count()==0 and not game.adventure_ui.body.text.contains("무림맹"),"initial empty menu leaks no faction names")
	var before=game.exploration.player.position
	Input.action_press("move_up");await physics_frame;await physics_frame;Input.action_release("move_up")
	check(game.exploration.player.position==before,"map movement paused")
	await press(KEY_R);check(not game.adventure_ui.window.visible and not paused,"R closes and resumes")
	game.progress.add_favor("murim_alliance",5);await press(KEY_R)
	check(label_text()=="무림맹  5 / 100","earned faction appears with maximum")
	var bar=game.adventure_ui.rows.get_child(0).get_child(1)
	check(bar is ProgressBar and bar.max_value==100 and bar.value==5,"bar uses fixed maximum100")
	await press(KEY_ESCAPE);check(not paused,"ESC closes")
	check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"earned favor saves and restores")
	await press(KEY_R);check(label_text().contains("5 / 100"),"revealed faction survives load");await press(KEY_R)
	game.progress.add_favor("murim_alliance",150);check(game.progress.favor_for("murim_alliance")==100,"gain caps at100")
	game.progress.add_favor("murim_alliance",-200);check(game.progress.favor_for("murim_alliance")==0,"loss floors at0")
	await press(KEY_R);check(label_text().contains("0 / 100"),"previously revealed faction remains atzero");await press(KEY_R)
	check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"revealed zero persists")
	check(game.progress.known_factions==["murim_alliance"],"no duplicate discoveries")
	game.player_menu.open_menu("inventory");check(not game.player_menu.summary.text.contains("호의도"),"favor removed from I")
	await press(KEY_R);check(game.adventure_ui.window.visible and not game.player_menu.visible,"R switches safely from I");await press(KEY_R)
	game.say([["hero","잠깐 생각을 정리하자."]]);await press(KEY_R);check(not game.adventure_ui.window.visible,"R blocked in dialogue");drain()
	game.pending_service_id="city_merchant";game._service_done();await press(KEY_R);check(not game.adventure_ui.window.visible,"R blocked in trade");game.city_service.close_counter()
	game.start_battle(game.bandit_story.data.encounters[0]);await press(KEY_R);check(not game.adventure_ui.window.visible,"R blocked in battle")
	game.reset();game.start_wuchang();check(game.progress.known_factions.is_empty(),"new game clears revealed factions")
	check(not game.progress.add_favor("unknown",5),"unregistered faction refused")
	game.progress.add_favor("murim_alliance",0);game.progress.add_favor("murim_alliance",-5)
	check(game.progress.known_factions.is_empty(),"zero or negative initial change does not reveal")
	var old=game.progress.snapshot();old.erase("known_factions");old.faction_favor={"murim_alliance":150}
	check(game.progress.valid(old),"old unbounded favor accepted for migration");game.progress.restore(old)
	check(game.progress.favor_for("murim_alliance")==100 and game.progress.known_factions==["murim_alliance"],"old positive favor discovers faction and normalizes")
	old.erase("faction_favor");game.progress.restore(old);check(game.progress.known_factions.is_empty() and game.progress.favor_for("murim_alliance")==0,"old missing fields stay empty")
	var bad=game.progress.snapshot();bad.known_factions=["unknown"];check(not game.progress.valid(bad),"unknown discovery rejected")
	bad=game.progress.snapshot();bad.known_factions=["murim_alliance","murim_alliance"];check(not game.progress.valid(bad),"duplicate discovery rejected")
	bad=game.progress.snapshot();bad.faction_favor.murim_alliance=101;bad.known_factions=["murim_alliance"];check(not game.progress.valid(bad),"new-format out of range rejected")
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_FACTION_FAVOR: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
