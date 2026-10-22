extends Control

const UI = preload("res://scripts/ui.gd")
const EXPLORATION = preload("res://scenes/exploration.tscn")
const BATTLE = preload("res://scenes/battle.tscn")
var exploration
var battle
var state: String = "title"
var talked_captain: bool = false
var objective: Label
var location: Label
var top_hud: Control
var bottom_hint: Label
var title_screen: Control
var dialogue_panel: Panel
var dialogue_name: Label
var dialogue_text: Label
var dialogue_portrait: TextureRect
var dialogue_lines: Array = []
var dialogue_index: int = 0
var dialogue_done: Callable
var ending: Control
var ending_hp: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_input()
	var system_font = SystemFont.new()
	system_font.font_names = PackedStringArray(["Malgun Gothic", "Noto Sans CJK KR", "Apple SD Gothic Neo", "sans-serif"])
	theme = Theme.new()
	theme.default_font = system_font
	theme.default_font_size = 18
	exploration = EXPLORATION.instantiate()
	add_child(exploration)
	battle = BATTLE.instantiate()
	add_child(battle)
	battle.hide()
	battle.victory.connect(_on_victory)
	_build_hud()
	_build_dialogue()
	_build_title()
	_build_ending()
	reset()

func _setup_input() -> void:
	var definitions = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "interact": [KEY_E]}
	for action in definitions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in definitions[action]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func _build_hud() -> void:
	top_hud = Control.new()
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_hud)
	var place_panel = UI.panel(top_hud, Rect2(24, 24, 360, 66), Color("13231edb"))
	UI.label(place_panel, "序章 · 가라앉은 약속", Rect2(16, 7, 325, 22), 13, UI.GOLD)
	location = UI.label(place_panel, "동정호 남쪽 · 청류진 나루", Rect2(16, 31, 325, 25), 18)
	var mission_panel = UI.panel(top_hud, Rect2(822, 24, 432, 66), Color("13231edb"))
	UI.label(mission_panel, "지금 할 일", Rect2(16, 7, 400, 20), 12, UI.GOLD)
	objective = UI.label(mission_panel, "", Rect2(16, 30, 400, 27), 16)
	bottom_hint = UI.label(self, "WASD / 방향키  이동     ·     바닥 클릭  이동     ·     E  대화     ·     F1  처음부터", Rect2(24, 680, 1230, 27), 14, Color("f1dfb4"))
	bottom_hint.add_theme_color_override("font_shadow_color", Color("11211a"))
	bottom_hint.add_theme_constant_override("shadow_offset_x", 2)
	bottom_hint.add_theme_constant_override("shadow_offset_y", 2)

func _build_dialogue() -> void:
	dialogue_panel = UI.panel(self, Rect2(24, 535, 1232, 160))
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_portrait = TextureRect.new()
	dialogue_portrait.position = Vector2(5, 4)
	dialogue_portrait.size = Vector2(120, 150)
	dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dialogue_panel.add_child(dialogue_portrait)
	dialogue_name = UI.label(dialogue_panel, "", Rect2(138, 14, 1045, 30), 22, UI.GOLD)
	dialogue_text = UI.label(dialogue_panel, "", Rect2(138, 55, 980, 83), 20)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next = UI.button(dialogue_panel, "다음 ▾", Rect2(1125, 106, 90, 38))
	next.pressed.connect(advance_dialogue)
	dialogue_panel.hide()

func _full_overlay(color: Color) -> Control:
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = color
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	add_child(overlay)
	return overlay

func _build_title() -> void:
	title_screen = _full_overlay(Color(0.035, 0.07, 0.055, 0.65))
	UI.label(title_screen, "序章 · 첫 표행", Rect2(110, 120, 700, 35), 20, UI.GOLD)
	UI.label(title_screen, "가라앉은\n약속", Rect2(105, 172, 850, 220), 78, Color("f3e5c8"))
	UI.label(title_screen, "출항을 기다리는 작은 나루.\n당신의 첫 표행이 시작됩니다.", Rect2(113, 420, 750, 75), 22)
	var start = UI.button(title_screen, "표행 시작  →", Rect2(112, 538, 230, 58), true)
	start.pressed.connect(start_story)
	var quick = UI.button(title_screen, "전투만 체험", Rect2(365, 538, 200, 58))
	quick.pressed.connect(start_battle)
	UI.label(title_screen, "GODOT 4 · 탐험 미술 개선판 / 0장 첫 전투까지", Rect2(113, 628, 950, 30), 14, UI.MUTED)

func _build_ending() -> void:
	ending = _full_overlay(Color(0.035, 0.07, 0.055, 0.94))
	UI.label(ending, "첫 번째 교전 · 완료", Rect2(360, 140, 700, 35), 20, UI.GOLD)
	UI.label(ending, "통로를 확보했다", Rect2(360, 210, 850, 70), 46)
	UI.label(ending, "수적을 물리쳤습니다.\n갑판 너머에서는 아직 소란이 이어집니다.", Rect2(360, 305, 850, 80), 23)
	ending_hp = UI.label(ending, "", Rect2(360, 405, 850, 36), 24, UI.GOLD)
	UI.label(ending, "이번 데모는 첫 전투에서 끝납니다.\n침몰과 귀물·구조 선택은 아직 구현하지 않았습니다.", Rect2(360, 470, 850, 66), 18, UI.MUTED)
	var retry = UI.button(ending, "전투 다시 하기", Rect2(360, 570, 230, 56), true)
	retry.pressed.connect(start_battle)
	var restart = UI.button(ending, "나루터부터 다시", Rect2(610, 570, 230, 56))
	restart.pressed.connect(reset)
	ending.hide()

func reset() -> void:
	state = "title"
	talked_captain = false
	dialogue_lines.clear()
	dialogue_panel.hide()
	ending.hide()
	battle.cancel()
	exploration.show()
	exploration.load_area("dock")
	exploration.set_active(false)
	top_hud.show()
	bottom_hint.hide()
	location.text = "동정호 남쪽 · 청류진 나루"
	objective.text = "첫 표행을 시작하세요."
	title_screen.show()

func start_story() -> void:
	title_screen.hide()
	state = "explore"
	bottom_hint.show()
	objective.text = "나루 끝의 표두 서문길과 대화하기"
	say([["주인공", "오늘은 나의 첫 정식 표행이다. 출항 전에 표두님을 찾아뵙자.", 0]])

func say(lines: Array, done: Callable = Callable()) -> void:
	exploration.set_active(false)
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_done = done
	dialogue_panel.show()
	_show_line()

func _show_line() -> void:
	var line = dialogue_lines[dialogue_index]
	dialogue_name.text = line[0]
	dialogue_text.text = line[1]
	dialogue_portrait.texture = UI.character_texture(line[2])

func advance_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_show_line()
	else:
		dialogue_lines = []
		dialogue_panel.hide()
		var done = dialogue_done
		dialogue_done = Callable()
		if done.is_valid():
			done.call()
		if state == "explore" and dialogue_lines.is_empty():
			exploration.set_active(true)

func interact() -> void:
	if not dialogue_lines.is_empty():
		advance_dialogue()
		return
	if state != "explore":
		return
	var npc: Dictionary = exploration.nearest()
	if npc.is_empty():
		return
	match npc.id:
		"captain":
			say([["서문길", "오늘부터 너도 정식 표행에 나서는 거다. 긴장했느냐?", 4], ["서문길", "저 배에는 우리 식구들이 함께 탄다. 화물을 살피되 동료가 어디 있는지도 잊지 마라.", 4], ["서문길", "준비가 되면 오른쪽 널빤지를 건너 배에 올라라. 갑판에서 다시 보자.", 4]], func():
				talked_captain = true
				objective.text = "오른쪽 널빤지를 건너 호송선에 오르기")
		"apothecary":
			say([["진소옥", "그 상자는 약재예요. 쌀가마처럼 던졌다가는 제가 먼저 화낼 거예요.", 5], ["진소옥", "이번에는 늦지 않게 도착했으면 좋겠네요. 기다리는 사람들이 있거든요.", 5]])
		"sailor":
			say([["허만복", "첫 표행이라고? 어깨 힘 좀 빼게. 그렇게 굳어 있으면 배가 흔들릴 때 바로 넘어진다네.", 6], ["허만복", "배에서는 발밑도 살피고, 사람 말도 잘 들어야 해. 자, 이 매듭부터 한번 봐.", 6]])
		"clerk":
			say([["육승", "수량 확인은 끝났습니다. 따로 봉한 귀물도 빠짐없이 실었고요.", 7], ["육승", "귀물을 전달하면 약정된 보수를 받습니다. 인도할 때까지 조심해 주세요.", 7]])
		"boarding":
			if not talked_captain:
				say([["주인공", "먼저 표두님께 인사하자.", 0]])
			else:
				say([["주인공", "배에 오르자. 첫 표행을 시작할 시간이다.", 0]], func():
					exploration.load_area("deck")
					location.text = "호송선 · 동정호 수로"
					objective.text = "갑판의 표두에게 출항 보고하기")
		"deck-sailor":
			say([["허만복", "물살은 괜찮군. 저 좁은 수로만 지나면 한동안 편할 거야.", 6]])
		"deck-captain":
			say([["주인공", "표두님, 갑판에 올라왔습니다.", 0], ["서문길", "좋다. 처음에는 내가 보이는 곳에 있어라. 무슨 일이 나면—", 4], ["허만복", "작은 배가 붙습니다! 저 표식은…… 흑린채입니다!", 6], ["서문길", "모두 화물에서 떨어져라! 너는 이쪽 통로를 지켜. 무리해서 쫓지는 마라!", 4]], start_battle)

func start_battle() -> void:
	state = "battle"
	dialogue_lines = []
	dialogue_panel.hide()
	title_screen.hide()
	ending.hide()
	top_hud.hide()
	bottom_hint.hide()
	exploration.set_active(false)
	exploration.hide()
	battle.begin()

func _on_victory(hp: int) -> void:
	state = "end"
	ending_hp.text = "남은 체력   %d / 300" % hp
	ending.show()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			reset()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if state == "explore":
				interact()
				get_viewport().set_input_as_handled()
			elif state == "battle":
				if battle.selected:
					battle.use_selected()
				else:
					battle.select_samjae()
				get_viewport().set_input_as_handled()
