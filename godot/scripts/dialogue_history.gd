extends Control
## Only the current conversation's already displayed lines, never future dialogue.
const UI = preload("res://scripts/ui.gd")
var game
var transcript: RichTextLabel
var prior_pause := false
var shown_lines := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	var shade := ColorRect.new()
	shade.color = Color("07100bef")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel=preload("res://scripts/paper_dialogue_panel.gd").new();panel.position=Vector2(130,50);panel.size=Vector2(1020,620);add_child(panel)
	var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=panel
	painter.text(panel,"이번 대화 · 지난 이야기",Rect2(28,16,950,42),30,painter.INK,true)
	painter.text(panel,"지금까지 나눈 말만 기록됩니다. 휠로 위아래를 살펴보세요.",Rect2(28,64,950,30),17,painter.MUTED)
	transcript = RichTextLabel.new()
	transcript.position = Vector2(30, 110)
	transcript.size = Vector2(960, 430)
	transcript.bbcode_enabled = false
	transcript.selection_enabled = true
	transcript.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	transcript.scroll_active = true
	transcript.add_theme_font_override("normal_font", UI.BODY_FONT)
	transcript.add_theme_font_size_override("normal_font_size", 21)
	transcript.add_theme_color_override("default_color", Color("293c38"))
	panel.add_child(transcript)
	var close = painter.button("대화로 돌아가기 · H / ESC", Rect2(610, 556, 380, 42), true)
	painter.free()
	close.pressed.connect(close_history)
	hide()

func open_history() -> void:
	if visible or game.dialogue_lines.is_empty() or not game.dialogue_panel.visible or game.settings_menu.window.visible: return
	transcript.clear()
	shown_lines = mini(game.dialogue_index + 1, game.dialogue_lines.size())
	for index in range(shown_lines):
		var line: Array = game.dialogue_lines[index]
		var speaker: String = game.PORTRAITS.ACTORS[line[0]].name
		if line.size() > 2 and line[2] is String: speaker += " · " + str(line[2])
		transcript.push_color(Color("244f4b"))
		transcript.add_text(speaker + "\n")
		transcript.pop()
		transcript.add_text(str(line[1]) + "\n\n")
	prior_pause = get_tree().paused
	get_tree().paused = true
	show()
	transcript.grab_focus()
	_scroll_to_latest.call_deferred()

func _scroll_to_latest() -> void:
	if visible: transcript.scroll_to_line(maxi(0, transcript.get_line_count() - 1))

func close_history() -> void:
	if not visible: return
	hide()
	get_tree().paused = prior_pause

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_H]: close_history()
		get_viewport().set_input_as_handled()
