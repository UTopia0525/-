extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:failed=true;push_error("TITLE: "+message)
func stamp(slot: int, time: String) -> void:
	var data=game.save_system.read_slot(slot);data.saved_at=time
	var file=FileAccess.open(game.save_system.path(slot),FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
func key(code: int) -> void:
	var event=InputEventKey.new();event.keycode=code;event.pressed=true
	Input.parse_input_event(event);await process_frame
	event=InputEventKey.new();event.keycode=code;event.pressed=false;Input.parse_input_event(event);await process_frame
func click(button: Button) -> void:
	var point=button.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion);await process_frame
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	var title=game.title_screen
	check(game.state=="title" and title.visible,"live title displayed")
	check(title.resume_button.disabled and title.load_button.disabled,"no-save state")
	check(root.gui_get_focus_owner()==title.menu_buttons[1],"new journey focused without save")
	await key(KEY_DOWN)
	check(root.gui_get_focus_owner()==title.menu_buttons[3],"keyboard skips disabled load")
	await key(KEY_ENTER)
	check(game.adventure_ui.window.visible and game.adventure_ui.mode=="options","native keyboard opens options")
	game.adventure_ui.close_menu();check(not game.settings_menu.window.visible and not paused,"options returns directly to title")
	game.start_city();check(game.save_system.write_slot(1),"save Changsha")
	stamp(1,"2026-10-27 10:01:01")
	game.exploration.load_area("nanjing");game.money=1234;check(game.save_system.write_slot(2),"save Nanjing")
	stamp(2,"2026-10-27 11:02:03")
	var broken=FileAccess.open(game.save_system.path(3),FileAccess.WRITE);broken.store_string("{broken");broken.close()
	game.reset();check(title.entries.size()==2 and title.entries[0].slot==2,"latest valid save first, corruption excluded")
	check(title.recent_label.text=="2026-10-27 11:02:03\n남경","only date/time/place on title")
	title.open_load();check(title.row_buttons.size()==2,"all valid slots available")
	check(title.row_buttons[0].text.contains("남경") and not title.row_buttons[0].text.contains("1234"),"load rows contain no money or story")
	title.select_entry(title.entries[1]);title.load_chosen()
	check(game.state=="explore" and game.exploration.area_name=="changsha","chosen older slot loaded")
	game.reset();title.resume_latest()
	check(game.exploration.area_name=="nanjing" and game.money==1234 and not title.visible,"continue restores newest actual slot")
	game.reset();await click(title.load_button)
	check(title.load_overlay.visible,"mouse opens load list")
	await click(title.row_buttons[1]);await click(title.load_action)
	check(game.exploration.area_name=="changsha" and not title.visible,"mouse selects and loads older save")
	game.reset();title.open_load();await key(KEY_ESCAPE);check(not title.load_overlay.visible and not game.settings_menu.window.visible,"ESC closes one layer")
	await key(KEY_F10);check(title.developer_overlay.visible,"debug tools moved to separate menu")
	await key(KEY_ESCAPE);check(not title.developer_overlay.visible,"debug close")
	# Old automatic checkpoint: no timestamp field remains compatible via file mtime.
	var checkpoint=FileAccess.open(game.prologue.SAVE_PATH,FileAccess.WRITE);checkpoint.store_string(JSON.stringify({"version":1,"chapter_00_complete":true,"branch":"rescue","payment_received":false,"money":0}));checkpoint.close()
	var entries=game.save_system.title_entries();var auto={}
	for entry in entries:
		if entry.kind=="auto":auto=entry
	check(not auto.is_empty() and auto.time.length()==19 and auto.place=="장사","legacy auto timestamp fallback")
	check(game.save_system.load_title_entry(auto),"legacy automatic checkpoint can load")
	check(game.exploration.area_name=="changsha" and game.prologue.branch=="rescue","automatic progress unchanged")
	game.reset();game.settings_menu.open_menu();game.settings_menu.select_slot(2)
	check(game.settings_menu.details.text.contains("남경") and not game.settings_menu.details.text.contains("1234") and not game.settings_menu.details.text.contains("분기"),"in-game slot summary also limited to time/place")
	game.settings_menu.close_menu()
	title.refresh();title.menu_buttons[1].pressed.emit()
	check(game.prologue.active and not title.visible and not game.dialogue_lines.is_empty(),"new journey enters existing prologue")
	game.queue_free();await process_frame
	if not failed:print("TITLE_SCREEN PASS")
	quit(1 if failed else 0)
