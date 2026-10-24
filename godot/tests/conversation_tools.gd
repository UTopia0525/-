extends SceneTree
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:failed=true;push_error("CONVERSATION_TOOLS: "+message)
func key(value: int) -> void:
	var event:=InputEventKey.new();event.keycode=value;event.pressed=true;root.push_input(event,true)
func inspect(lines: Array) -> void:
	game.say(lines)
	var paths: Array=game.dialogue_cast.portrait_choices.values()
	var unique: Dictionary={}
	for path in paths:unique[path]=true
	check(unique.size()==paths.size() and not unique.has(""),"every participant has a different portrait")
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	for path in ["male_common_a","male_common_b","female_common_a","female_common_b"]:
		check(ResourceLoader.exists("res://assets/portraits/extras/"+path+".png"),"new common portrait: "+path)
	for name in ["prologue_dialogues","chapter_one_intro","trade_intro","changsha_bandit_story"]:
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name+".json"))
		if name=="prologue_dialogues":
			for scene in data.values():inspect(scene.lines)
		elif name=="chapter_one_intro":inspect(data)
		elif name=="trade_intro":
			for quest in data.quests:inspect(quest.lines)
		else:
			for lines in data.scenes.values():inspect(lines)
	game.start_story()
	game.say([["captain","이미 읽은 이야기 [강호]"],["sailor","서로 다른 얼굴을 가진 두 사람"],["hero","FUTURE_SECRET"]],game._captain_done)
	# Plain literal text is supported; use Hangul in the real visible fixture.
	game.dialogue_lines[0][1]="이미 읽은 이야기 [강호]"
	game.dialogue_lines[1][1]="서로 다른 얼굴을 가진 두 사람"
	game._show_line();game.advance_dialogue()
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1),"legacy mid-dialogue fixture")
	game.advance_dialogue()
	check(game.save_system.load_slot(1) and game.dialogue_index==1,"legacy dialogue restores read boundary")
	var index: int=game.dialogue_index
	key(KEY_H);await process_frame
	var history=game.dialogue_history
	check(history.visible and paused and history.shown_lines==2,"H opens paused current transcript")
	check(history.transcript.get_parsed_text().contains("이미 읽은 이야기 [강호]") and not history.transcript.get_parsed_text().contains("FUTURE_SECRET"),"history shows literal read lines without spoilers")
	key(KEY_F);game.advance_dialogue();await process_frame
	check(game.dialogue_index==index and not game.talked_captain,"history cannot advance conversation or callbacks")
	key(KEY_ESCAPE);await process_frame
	check(not history.visible and not paused and game.dialogue_index==index,"Esc returns to the same line")
	game.advance_dialogue();history.open_history()
	check(history.shown_lines==3,"newly read line appended on reopen")
	history.close_history();game.advance_dialogue()
	check(game.talked_captain and not game.dialogue_panel.visible,"normal completion callback runs once")
	game.say([["hero","새 대화"]]);history.open_history()
	check(not history.transcript.get_parsed_text().contains("이미 읽은") and history.shown_lines==1,"new conversation starts a fresh transcript")
	game.reset();check(not history.visible and not paused,"reset closes and unpauses history")
	await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_CONVERSATION_TOOLS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
