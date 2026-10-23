extends SceneTree
const UI = preload("res://scripts/ui.gd")
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed=true
		push_error("INK_UI: "+message)
func hover(button: Button) -> void:
	var event := InputEventMouseMotion.new()
	event.position = button.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event,true)
	await process_frame
	await process_frame
func assert_hover(button: Button, name: String) -> void:
	var was_money: int = game.money
	var was_selected: String = game.battle.selected_action
	await hover(button)
	if not button.get_meta("item_highlight").visible: print("HOVER_DEBUG ",name," rect=",button.get_global_rect()," pointer=",root.get_mouse_position()," under=",root.gui_get_hovered_control())
	check(button.has_meta("item_highlight") and button.get_meta("item_highlight").visible,name+" has an actual pointer hover rim")
	check(game.money==was_money and game.battle.selected_action==was_selected,"hover cannot buy or commit a battle selection")
func inspect_lines(lines: Array, label: Label) -> void:
	for line in lines:
		label.text = str(line[1])
		await process_frame
		check(label.get_line_count()*label.get_line_height()<=label.size.y+2,"dialogue fits visible lines: "+str(line[1]).left(25))
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	check(game.theme.default_font==UI.BODY_FONT,"bundled serif body theme")
	check(game.dialogue_name.get_theme_font("font")==UI.BRUSH_FONT,"speaker uses brush lettering")
	for text in ["강호의 초식과 표행", "근력 기민 근골 내공 오성", "長沙 序章"]:
		for ch in text:
			if ch != " ": check(UI.BODY_FONT.has_char(ch.unicode_at(0)),"body glyph: "+ch)
	game.start_battle()
	var b=game.battle
	for id in ["basic_attack","bandit_chop","bandit_heavy_chop"]:
		b.enemy_intent=id;b._update_intent()
		check(b.intent_label.text=="적이 공격을 하려고 한다","all enemy attacks share one category-only message")
		check(not b.intent_icon.visible and b.intent_icon.texture==null and b.intent_label.tooltip_text.is_empty(),"no skill icon or tooltip leaks enemy move")
	b.enemy_intent="basic_defense";b._update_intent()
	check(b.intent_label.text=="상대가 수세를 취하고 있다" and not b.intent_label.text.contains("70"),"defense has no technical preview")
	b._prepare_enemy()
	await assert_hover(b.skill_buttons[2],"battle technique")
	# Moving off restores ordinary state; disabled slots remain noninteractive.
	var event := InputEventMouseMotion.new();event.position=Vector2(640,300);event.global_position=event.position;Input.parse_input_event(event)
	await process_frame;await process_frame
	check(not b.skill_buttons[2].get_meta("item_highlight").visible,"hover rim clears when cursor leaves")
	game.reset();game.start_city()
	game.player_menu.open_menu("inventory")
	await process_frame
	var menu=game.player_menu
	var row: Button = menu.rows.get_child(1)
	await assert_hover(row,"inventory weapon")
	menu.switch_mode("martial");await process_frame
	await assert_hover(menu.rows.get_child(2),"learned martial art")
	menu.close_menu()
	for service in game.exploration.city_data.services:
		if service.id=="city_artisan":game.state="service";game.city_service.open_counter(service)
	await process_frame
	await assert_hover(game.city_service.rows.get_child(0),"shop weapon")
	game.city_service.dismiss()
	# Review every live dialogue with the real font and dialogue label dimensions.
	game.dialogue_panel.show()
	for name in ["prologue_dialogues","chapter_one_intro","trade_intro","changsha_bandit_story"]:
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name+".json"))
		if name=="prologue_dialogues":
			for scene in data.values():await inspect_lines(scene.lines,game.dialogue_text)
		elif name=="chapter_one_intro":await inspect_lines(data,game.dialogue_text)
		elif name=="trade_intro":
			for quest in data.quests:await inspect_lines(quest.lines,game.dialogue_text)
		else:
			for lines in data.scenes.values():await inspect_lines(lines,game.dialogue_text)
	game.reset();await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_INK_UI: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
