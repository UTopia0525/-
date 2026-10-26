extends Control
const UI = preload("res://scripts/ui.gd")
var game
var gear: Button
var window: Control
var slots: Array[Button] = []
var selected := 1
var mode := "save"
var details: Label
var status: Label
var action: Button
var confirmation: ConfirmationDialog
var save_tab: Button
var load_tab: Button
var music_toggle: CheckButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear = UI.button(self, "설정 · ESC", Rect2(1135, 145, 120, 35))
	gear.pressed.connect(open_menu)
	window = Control.new()
	window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(window)
	var shade = ColorRect.new()
	shade.color = Color("081411ed")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.add_child(shade)
	var panel = UI.panel(window, Rect2(135, 55, 1010, 615))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.label(panel, "설정 · 저장과 불러오기", Rect2(28, 16, 900, 42), 28, UI.GOLD)
	save_tab = UI.button(panel, "저장", Rect2(28, 76, 180, 43))
	save_tab.pressed.connect(set_mode.bind("save"))
	load_tab = UI.button(panel, "불러오기", Rect2(220, 76, 180, 43))
	load_tab.pressed.connect(set_mode.bind("load"))
	var environment=UI.button(panel,"환경 설정 · 도움말",Rect2(425,76,285,43))
	environment.pressed.connect(func():game.adventure_ui.open_options())
	music_toggle = CheckButton.new()
	music_toggle.text = "배경음악"
	music_toggle.position = Vector2(750, 76)
	music_toggle.toggled.connect(func(enabled: bool): game.music.set_enabled(enabled))
	panel.add_child(music_toggle)
	for index in range(10):
		var button = UI.button(panel, "", Rect2(28, 136 + index * 39, 495, 35))
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(select_slot.bind(index + 1))
		slots.append(button)
	details = UI.label(panel, "", Rect2(550, 140, 425, 255), 17)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status = UI.label(panel, "", Rect2(550, 400, 425, 80), 16, UI.MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action = UI.button(panel, "", Rect2(550, 492, 425, 45), true)
	action.pressed.connect(request_action)
	var close = UI.button(panel, "게임으로 돌아가기 · ESC", Rect2(550, 550, 425, 42))
	close.pressed.connect(close_menu)
	UI.label(panel, "수동 저장 10칸 · 자동 체크포인트는 별도 보관", Rect2(28, 555, 500, 30), 14, UI.MUTED)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "저장 확인"
	confirmation.ok_button_text = "확인"
	confirmation.cancel_button_text = "취소"
	confirmation.confirmed.connect(perform_action)
	add_child(confirmation)
	window.hide()

func open_menu() -> void:
	if game.state=="game_over":return
	if window.visible: return
	game.player_menu.close_menu()
	game.exploration.player.stop()
	game.get_tree().paused = true
	window.show()
	music_toggle.set_pressed_no_signal(game.music.enabled)
	set_mode("load" if game.state == "title" else "save")

func close_menu() -> void:
	confirmation.hide()
	window.hide()
	game.get_tree().paused = false

func set_mode(value: String) -> void:
	mode = value
	refresh()

func select_slot(value: int) -> void:
	selected = value
	refresh()

func refresh() -> void:
	save_tab.disabled = mode == "save"
	load_tab.disabled = mode == "load"
	for index in range(slots.size()):
		var data: Dictionary = game.save_system.read_slot(index + 1)
		var exists = FileAccess.file_exists(game.save_system.path(index + 1))
		var summary = "빈 저장 칸" if not exists else "읽을 수 없는 저장"
		if not data.is_empty(): summary = "%d장 · %s · %s" % [int(data.chapter), area_name(data.world.area), data.saved_at]
		slots[index].text = "%02d   %s" % [index + 1, summary]
		slots[index].modulate = UI.GOLD if index + 1 == selected else Color.WHITE
	var data: Dictionary = game.save_system.read_slot(selected)
	details.text = "저장 칸 %02d\n" % selected
	if data.is_empty():
		details.text += "비어 있거나 불러올 수 없는 저장 칸입니다."
	else:
		var branch_name: String = {"":"선택 전", "treasure":"귀물 보전", "rescue":"인명 구조"}[data.prologue.branch]
		var situation: String = {"explore":"탐험", "story":"대화 진행", "choice":"분기 선택 직전", "battle":"전투 · 내 차례", "service":"시설 이용", "end":"전투 체험 완료"}[data.state]
		details.text += "%d장 · %s\n%s\n%s\n소지금 %d문\n%s" % [int(data.chapter), area_name(data.world.area), situation, branch_name, int(data.money), data.saved_at]
		details.text += "\n" + (data.ui.caption if not data.ui.caption.is_empty() else data.ui.objective)
	action.text = "이 칸에 저장" if mode == "save" else "이 저장 불러오기"
	var reason: String = game.save_system.blocked_reason() if mode == "save" else ""
	action.disabled = not reason.is_empty() if mode == "save" else data.is_empty()
	status.text = reason if not reason.is_empty() else ("탐험 중이나 분기 선택 전에 다른 칸에 저장할 수 있습니다." if mode == "save" else "선택한 저장 시점으로 돌아갑니다.")

func area_name(id: String) -> String:
	return {"dock":"청류진 나루", "deck":"호송선", "changsha":"장사", "mountain_road":"장사–무창 산길", "wuchang":"무창", "alliance_office":"총무당", "qingya_hamlet":"삼거리 산촌", "qingya_camp":"청애채"}.get(id, id)

func request_action() -> void:
	if action.disabled: return
	if mode == "save" and not FileAccess.file_exists(game.save_system.path(selected)):
		perform_action()
		return
	confirmation.title = "저장 덮어쓰기" if mode == "save" else "저장 불러오기"
	confirmation.dialog_text = ("%02d번 칸의 기존 저장을 덮어쓸까요?" if mode == "save" else "%02d번 저장으로 돌아갈까요?\n현재 저장하지 않은 진행은 사라집니다.") % selected
	confirmation.popup_centered(Vector2i(560, 180))

func perform_action() -> void:
	if mode == "save":
		var ok: bool = game.save_system.write_slot(selected)
		refresh()
		status.text = "%02d번 칸에 저장했습니다." % selected if ok else game.save_system.error
	else:
		# Validate before dismissing the paused screen; malformed data never resets play.
		if game.save_system.read_slot(selected).is_empty():
			status.text = "불러올 수 없는 저장입니다. 현재 진행은 유지됩니다."
			return
		close_menu()
		if not game.save_system.load_slot(selected):
			open_menu()
			status.text = game.save_system.error

func _input(event: InputEvent) -> void:
	if window.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if confirmation.visible: confirmation.hide()
			else: close_menu()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	var compact_world=game.exploration.area_name in ["changsha","mountain_road","wuchang","alliance_office","qingya_hamlet","qingya_camp","nanjing"]
	gear.visible=game.state!="game_over" and (game.state not in ["explore","story"] or not compact_world)
	gear.position=Vector2(1135,198) if game.state in ["explore","story"] else Vector2(1135,145)
