extends Control
## Live title: generated background plate, real text/buttons, validated save entries.
const UI = preload("res://scripts/ui.gd")
const PAPER = preload("res://scripts/paper_menu_base.gd")
const CREAM = Color("efe6d1")
const GOLD = Color("e6bc76")
var game
var resume_button: Button
var load_button: Button
var menu_buttons: Array[Button] = []
var recent_label: Label
var load_overlay: Control
var load_rows: VBoxContainer
var load_action: Button
var load_summary: Label
var load_status: Label
var entries: Array[Dictionary] = []
var chosen: Dictionary = {}
var row_buttons: Array[Button] = []
var developer_overlay: Control
var quit_confirmation: ConfirmationDialog
var load_back: Button
var developer_buttons: Array[Button] = []
var last_menu: Button
var marker: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background = TextureRect.new()
	background.texture = preload("res://assets/ui/title-river-sunset.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Gentle, static ink shading preserves the art and makes real menu text legible.
	var veil = ColorRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ float left=1.0-smoothstep(.08,.42,UV.x); float bottom=smoothstep(.72,1.0,UV.y); COLOR=vec4(.025,.043,.037,left*.20+bottom*.16); }"
	var material = ShaderMaterial.new();material.shader = shader;veil.material = material
	add_child(veil);veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title = label("가라앉은 약속", Rect2(60, 34, 710, 140), 108, Color("172925"), true)
	title.add_theme_constant_override("outline_size", 0)
	label("한 걸음의 선택이, 강호에 남는다", Rect2(80, 177, 540, 27), 17, Color("e8ddc4"))
	resume_button = menu("이어하기", Rect2(79, 265, 272, 49), resume_latest)
	recent_label = label("", Rect2(89, 318, 342, 54), 15, Color("d6cfbb"))
	menu("새로운 여정", Rect2(79, 388, 272, 45), game.start_story)
	load_button = menu("불러오기", Rect2(79, 445, 272, 45), open_load)
	menu("환경 설정", Rect2(79, 502, 272, 45), open_options)
	menu("게임 종료", Rect2(79, 559, 272, 45), request_quit)
	marker = ColorRect.new();marker.color=GOLD;marker.size=Vector2(3,30);marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(marker)
	for button in menu_buttons:
		button.focus_entered.connect(_mark.bind(button));button.mouse_entered.connect(_mark.bind(button))
	label("↑ ↓  이동     Enter  선택     ESC  환경 설정", Rect2(79, 671, 490, 24), 14, Color("d0ccba"))
	_build_load()
	_build_developer()
	quit_confirmation = ConfirmationDialog.new();quit_confirmation.title="게임 종료";quit_confirmation.dialog_text="강호의 여정을 마치고 게임을 종료할까요?";quit_confirmation.ok_button_text="종료";quit_confirmation.cancel_button_text="돌아가기";quit_confirmation.confirmed.connect(func():get_tree().quit());add_child(quit_confirmation)
	visibility_changed.connect(func():
		if visible and is_instance_valid(game.save_system):refresh()
		elif not visible:load_overlay.hide();developer_overlay.hide();quit_confirmation.hide())

func label(value: String, rect: Rect2, size: int, color: Color, brush: bool = false) -> Label:
	var node = UI.label(self, value, rect, size, color)
	node.add_theme_font_override("font", UI.BRUSH_FONT if brush else UI.BODY_FONT)
	return node

func menu(value: String, rect: Rect2, callback: Callable, main_menu: bool = true) -> Button:
	var button = Button.new();button.text = value;button.position = rect.position;button.size = rect.size
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", UI.BODY_FONT);button.add_theme_font_size_override("font_size", 25)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style = StyleBoxFlat.new();style.bg_color=Color.TRANSPARENT;style.content_margin_left=12
		if state in ["hover", "focus", "pressed"]:
			style.bg_color=Color("152b2628");style.border_width_bottom=1;style.border_color=Color("d9b87999")
		button.add_theme_stylebox_override(state,style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state, GOLD if state != "font_color" and state != "font_disabled_color" else Color("8c9184") if state == "font_disabled_color" else CREAM)
	button.pressed.connect(callback);button.pressed.connect(func():game.options.play("confirm"))
	add_child(button)
	if main_menu:menu_buttons.append(button)
	return button

func _mark(button: Button) -> void:
	if is_instance_valid(marker) and button in menu_buttons:
		marker.position=button.position+Vector2(-10,9);last_menu=button

func refresh() -> void:
	entries = game.save_system.title_entries()
	resume_button.disabled = entries.is_empty();load_button.disabled=entries.is_empty()
	recent_label.text="불러올 수 있는 저장이 없습니다." if entries.is_empty() else "%s\n%s" % [entries[0].time,entries[0].place]
	load_overlay.hide();developer_overlay.hide();quit_confirmation.hide()
	var initial = menu_buttons[1] if entries.is_empty() else resume_button
	initial.grab_focus();_mark(initial)

func resume_latest() -> void:
	entries=game.save_system.title_entries()
	if entries.is_empty():refresh();return
	if not game.save_system.load_title_entry(entries[0]):
		open_load();load_status.text=game.save_system.error

func restore_focus() -> void:
	if visible and is_instance_valid(last_menu) and not last_menu.disabled:last_menu.grab_focus()

func open_options() -> void:
	game.adventure_ui.open_options();game.adventure_ui.return_settings=false

func _build_load() -> void:
	load_overlay=Control.new();load_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(load_overlay)
	var shade=ColorRect.new();shade.color=Color("081512d9");load_overlay.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var painter=PAPER.new();load_overlay.add_child(painter);painter.content=load_overlay
	painter.box(load_overlay,Rect2(204,62,872,598),Color("152823"),Color("9d8b65"))
	painter.paper(Rect2(213,70,854,582),Color("eee5cf"))
	painter.text(load_overlay,"남겨 둔 여정",Rect2(248,91,620,44),32,PAPER.INK,true)
	painter.text(load_overlay,"저장 시각과 장소를 확인하고 이어갈 여정을 고르세요.",Rect2(250,142,740,30),16,PAPER.MUTED)
	var scroll=ScrollContainer.new();scroll.position=Vector2(247,190);scroll.size=Vector2(785,316);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;load_overlay.add_child(scroll)
	load_rows=VBoxContainer.new();load_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;load_rows.add_theme_constant_override("separation",7);scroll.add_child(load_rows)
	load_summary=painter.text(load_overlay,"",Rect2(250,519,750,30),18,PAPER.INK)
	load_status=painter.text(load_overlay,"",Rect2(250,551,750,23),14,PAPER.MUTED)
	load_action=painter.button("이 여정 이어가기",Rect2(765,588,266,43),true);load_action.pressed.connect(load_chosen)
	load_back=painter.button("돌아가기 · ESC",Rect2(249,588,209,43));load_back.pressed.connect(close_load)
	load_overlay.hide()

func open_load() -> void:
	entries=game.save_system.title_entries();chosen={};row_buttons.clear()
	for child in load_rows.get_children():load_rows.remove_child(child);child.queue_free()
	for entry in entries:
		var button=Button.new();button.text="%s   %s     ·     %s" % ["자동 저장" if entry.kind=="auto" else "저장 %02d" % entry.slot,entry.time,entry.place]
		button.custom_minimum_size=Vector2(760,51);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.add_theme_font_override("font",UI.BODY_FONT);button.add_theme_font_size_override("font_size",17)
		for state in ["normal","hover","pressed","focus"]:
			var style=UI.box(Color("e8dfca") if state=="normal" else Color("d3d5be"),Color("b2aa8b"));style.content_margin_top=8;style.content_margin_bottom=8
			if state=="focus":style.bg_color=Color.TRANSPARENT;style.set_border_width_all(2);style.border_color=PAPER.TEAL
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",PAPER.INK);button.add_theme_color_override("font_hover_color",PAPER.TEAL);button.add_theme_color_override("font_focus_color",PAPER.INK)
		button.pressed.connect(select_entry.bind(entry));button.focus_entered.connect(select_entry.bind(entry));load_rows.add_child(button);row_buttons.append(button)
	load_overlay.show();load_status.text="저장 당시 기기의 날짜와 시각을 표시합니다."
	load_action.disabled=entries.is_empty()
	if not entries.is_empty():select_entry(entries[0]);row_buttons[0].grab_focus()
	else:load_summary.text="불러올 수 있는 저장이 없습니다."

func select_entry(entry: Dictionary) -> void:
	chosen=entry.duplicate();load_summary.text="%s  ·  %s" % [entry.time,entry.place]
	for i in range(row_buttons.size()):
		var style=UI.box(PAPER.TEAL if entries[i]==entry else Color("e8dfca"),Color("b2aa8b"));style.content_margin_top=8;style.content_margin_bottom=8
		row_buttons[i].add_theme_stylebox_override("normal",style)
		row_buttons[i].add_theme_color_override("font_color",CREAM if entries[i]==entry else PAPER.INK)
		row_buttons[i].add_theme_color_override("font_focus_color",CREAM if entries[i]==entry else PAPER.INK)

func load_chosen() -> void:
	if chosen.is_empty():return
	if not game.save_system.load_title_entry(chosen):load_status.text=game.save_system.error

func close_load() -> void:
	load_overlay.hide();load_button.grab_focus()

func _build_developer() -> void:
	developer_overlay=Control.new();add_child(developer_overlay);developer_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade=ColorRect.new();shade.color=Color("081512ed");developer_overlay.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.label(developer_overlay,"개발 도구",Rect2(420,155,500,50),32,UI.GOLD)
	for spec in [["전투만 체험",game.start_battle],["장사 자유 탐방",game.start_city],["무창 자유 탐방",game.start_wuchang],["0장 체크포인트 재개",game.prologue.resume]]:
		var index=developer_overlay.get_child_count()-2
		var button=UI.button(developer_overlay,spec[0],Rect2(420,230+index*60,440,47));button.pressed.connect(spec[1]);developer_buttons.append(button)
	var back=UI.button(developer_overlay,"돌아가기 · ESC",Rect2(420,500,440,47));back.pressed.connect(func():developer_overlay.hide();menu_buttons[0 if not resume_button.disabled else 1].grab_focus());developer_buttons.append(back)
	developer_overlay.hide()

func open_developer() -> void:
	developer_overlay.show()
	developer_overlay.get_child(2).grab_focus()

func request_quit() -> void:quit_confirmation.popup_centered(Vector2i(550,180))

func handle_input(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:return false
	if quit_confirmation.visible:return false
	if event.keycode==KEY_ESCAPE:
		if load_overlay.visible:close_load()
		elif developer_overlay.visible:developer_overlay.hide();menu_buttons[1].grab_focus()
		else:open_options()
		return true
	if event.keycode==KEY_F10 and not load_overlay.visible:open_developer();return true
	var buttons: Array[Button] = []
	if load_overlay.visible:
		buttons.assign(row_buttons);buttons.append(load_action);buttons.append(load_back)
	elif developer_overlay.visible:buttons.assign(developer_buttons)
	else:buttons.assign(menu_buttons)
	var enabled: Array[Button] = []
	for button in buttons:
		if not button.disabled and button.is_visible_in_tree():enabled.append(button)
	if enabled.is_empty():return false
	var focused = get_viewport().gui_get_focus_owner()
	if event.keycode in [KEY_UP,KEY_DOWN,KEY_TAB]:
		var index = enabled.find(focused)
		var step = -1 if event.keycode == KEY_UP or (event.keycode == KEY_TAB and event.shift_pressed) else 1
		enabled[posmod(index + step, enabled.size())].grab_focus()
		return true
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		if focused in row_buttons and load_overlay.visible:load_chosen()
		elif focused in enabled:focused.pressed.emit()
		else:enabled[0].grab_focus()
		return true
	return false
