extends Control

const UI = preload("res://scripts/ui.gd")
const EXPLORATION = preload("res://scenes/exploration.tscn")
const BATTLE = preload("res://scenes/battle.tscn")
const QUEST_NAVIGATION = preload("res://scripts/quest_navigation.gd")
const MINIMAP = preload("res://scripts/minimap.gd")
const CITY_OVERVIEW = preload("res://scripts/city_overview.gd")
const PORTRAITS = preload("res://scripts/dialogue_portraits.gd")
const MUSIC = preload("res://scripts/music.gd")
var exploration
var battle
var music
var ui_layer: CanvasLayer
var ui_root: Control
var dialogue_music_cues: Dictionary = {}
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
var dialogue_cast
var city_overview
var minimap
var city_service
var quest_navigation
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
	music = MUSIC.new()
	music.name = "SituationMusic"
	add_child(music)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "ScreenUI"
	ui_layer.layer = 10
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.name = "FixedInterface"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = theme
	ui_layer.add_child(ui_root)
	exploration = EXPLORATION.instantiate()
	add_child(exploration)
	battle = BATTLE.instantiate()
	ui_root.add_child(battle)
	battle.hide()
	battle.victory.connect(_on_victory)
	quest_navigation = QUEST_NAVIGATION.new()
	quest_navigation.name = "QuestNavigation"
	add_child(quest_navigation)
	_build_hud()
	_build_dialogue()
	_build_title()
	_build_ending()
	city_overview = CITY_OVERVIEW.new()
	ui_root.add_child(city_overview)
	city_service = preload("res://scripts/city_service.gd").new()
	ui_root.add_child(city_service)
	city_service.closed.connect(func():
		state = "explore"
		exploration.set_active(true))
	reset()

func _setup_input() -> void:
	var definitions = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "interact": [KEY_F]}
	for action in definitions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for code in definitions[action]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func _build_hud() -> void:
	top_hud = Control.new()
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(top_hud)
	minimap = MINIMAP.new()
	top_hud.add_child(minimap)
	minimap.bind_world(exploration)
	minimap.quest_navigation = quest_navigation
	location = minimap.place_label
	var mission_panel = UI.panel(top_hud, Rect2(822, 24, 432, 66), Color("13231edb"))
	UI.label(mission_panel, "지금 할 일", Rect2(16, 7, 400, 20), 12, UI.GOLD)
	objective = UI.label(mission_panel, "", Rect2(16, 30, 400, 27), 16)
	objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bottom_hint = UI.label(ui_root, "WASD / 방향키  이동     ·     바닥 클릭  이동     ·     F  대화     ·     M  음악     ·     F1  처음부터", Rect2(24, 680, 1230, 27), 14, Color("f1dfb4"))
	bottom_hint.add_theme_color_override("font_shadow_color", Color("11211a"))
	bottom_hint.add_theme_constant_override("shadow_offset_x", 2)
	bottom_hint.add_theme_constant_override("shadow_offset_y", 2)

func _build_dialogue() -> void:
	dialogue_cast = PORTRAITS.new()
	ui_root.add_child(dialogue_cast)
	dialogue_panel = UI.panel(ui_root, Rect2(24, 535, 1232, 160))
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_name = UI.label(dialogue_panel, "", Rect2(24, 14, 1045, 30), 22, UI.GOLD)
	dialogue_text = UI.label(dialogue_panel, "", Rect2(24, 55, 1065, 83), 20)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next = UI.button(dialogue_panel, "다음 ▾", Rect2(1125, 106, 90, 38))
	next.pressed.connect(advance_dialogue)
	dialogue_panel.hide()
	dialogue_cast.clear()

func _full_overlay(color: Color) -> Control:
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = color
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	ui_root.add_child(overlay)
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
	var city = UI.button(title_screen, "장사 자유 탐방", Rect2(588, 538, 230, 58))
	city.pressed.connect(start_city)
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
	city_service.dismiss()
	quest_navigation.clear()
	city_overview.hide()
	bottom_hint.text = "WASD / 방향키  이동     ·     바닥 클릭  이동     ·     F  대화     ·     M  음악     ·     F1  처음부터"
	state = "title"
	music.play_track("title")
	talked_captain = false
	dialogue_lines.clear()
	dialogue_panel.hide()
	dialogue_cast.clear()
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
	music.play_track("dock")
	title_screen.hide()
	state = "explore"
	bottom_hint.show()
	objective.text = "나루 끝의 표두 서문길과 대화하기"
	say([["hero", "오늘은 나의 첫 정식 표행이다. 출항 전에 표두님을 찾아뵙자."]])

func start_city() -> void:
	city_service.dismiss()
	quest_navigation.clear()
	dialogue_lines.clear()
	dialogue_done = Callable()
	dialogue_panel.hide()
	dialogue_cast.clear()
	city_overview.hide()
	title_screen.hide()
	ending.hide()
	battle.cancel()
	state = "explore"
	music.play_track("dock")
	exploration.show()
	exploration.load_area("changsha")
	exploration.set_active(true)
	top_hud.show()
	location.text = "장사 · " + exploration.district_at_player()
	objective.text = "시장·골목·나루·성밖 농촌 둘러보기"
	bottom_hint.text = "WASD / 방향키  이동     ·     바닥 클릭  이동     ·     F  거래     ·     TAB  전체 지도     ·     M  음악     ·     F1  타이틀"
	bottom_hint.show()

func _process(_delta: float) -> void:
	if state == "explore" and exploration.area_name == "changsha":
		location.text = "장사 · " + exploration.district_at_player()
		var goal: Dictionary = quest_navigation.get_goal(exploration)
		objective.text = goal.quest_title + " · " + goal.label if not goal.is_empty() else "시장·골목·나루·성밖 농촌 둘러보기"

func toggle_city_map() -> void:
	if city_overview.visible:
		city_overview.hide()
		exploration.set_active(true)
	else:
		exploration.set_active(false)
		city_overview.open_for(exploration, quest_navigation.get_goal(exploration))

func say(lines: Array, done: Callable = Callable(), listeners: Array = ["hero"]) -> void:
	if lines.is_empty():
		return
	exploration.set_active(false)
	dialogue_lines = lines
	dialogue_music_cues = {}
	dialogue_index = 0
	dialogue_done = done
	# Include listeners as well as every speaker, in a stable order.
	var ids: Array = listeners.duplicate()
	for line in lines:
		if not ids.has(line[0]):
			ids.append(line[0])
	var participants: Array = []
	for id in ids:
		var actor: Dictionary = PORTRAITS.ACTORS[id].duplicate()
		actor["id"] = id
		participants.append(actor)
	dialogue_cast.set_participants(participants)
	dialogue_panel.show()
	_show_line()

func _show_line() -> void:
	if dialogue_music_cues.has(dialogue_index):
		music.play_track(dialogue_music_cues[dialogue_index])
	var line = dialogue_lines[dialogue_index]
	dialogue_name.text = PORTRAITS.ACTORS[line[0]].name
	dialogue_text.text = line[1]
	dialogue_cast.set_speaker(line[0])

func advance_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_show_line()
	else:
		dialogue_lines = []
		dialogue_panel.hide()
		dialogue_cast.clear()
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
	if npc.has("service_id"):
		var service: Dictionary = {}
		for definition in exploration.city_data.services:
			if definition.id == npc.service_id:
				service = definition
		if not service.is_empty():
			var greeting: String = {"market": "필요한 물건을 찾으십니까? 진열대를 한번 둘러보시지요.", "workshop": "물건을 맡기러 오셨습니까? 어떤 일인지 살펴보지요.", "training": "무관에 오신 걸 환영하오. 수련에 관해 알아보러 오셨소?"}[service.kind]
			say([[service.id, greeting]], func():
				state = "service"
				exploration.set_active(false)
				city_service.open_counter(service))
		return
	match npc.id:
		"captain":
			say([["captain", "오늘부터 너도 정식 표행에 나서는 거다. 긴장했느냐?"], ["captain", "저 배에는 우리 식구들이 함께 탄다. 화물을 살피되 동료가 어디 있는지도 잊지 마라."], ["captain", "준비가 되면 오른쪽 널빤지를 건너 배에 올라라. 갑판에서 다시 보자."]], func():
				talked_captain = true
				objective.text = "오른쪽 널빤지를 건너 호송선에 오르기")
		"apothecary":
			say([["apothecary", "그 상자는 약재예요. 쌀가마처럼 던졌다가는 제가 먼저 화낼 거예요."], ["apothecary", "이번에는 늦지 않게 도착했으면 좋겠네요. 기다리는 사람들이 있거든요."]])
		"sailor":
			say([["sailor", "첫 표행이라고? 어깨 힘 좀 빼게. 그렇게 굳어 있으면 배가 흔들릴 때 바로 넘어진다네."], ["sailor", "배에서는 발밑도 살피고, 사람 말도 잘 들어야 해. 자, 이 매듭부터 한번 봐."]])
		"clerk":
			say([["clerk", "수량 확인은 끝났습니다. 따로 봉한 귀물도 빠짐없이 실었고요."], ["clerk", "귀물을 전달하면 약정된 보수를 받습니다. 인도할 때까지 조심해 주세요."]])
		"boarding":
			if not talked_captain:
				say([["hero", "먼저 표두님께 인사하자."]])
			else:
				say([["hero", "배에 오르자. 첫 표행을 시작할 시간이다."]], func():
					exploration.load_area("deck")
					music.play_track("voyage")
					location.text = "호송선 · 동정호 수로"
					objective.text = "갑판의 표두에게 출항 보고하기")
		"deck-sailor":
			say([["sailor", "물살은 괜찮군. 저 좁은 수로만 지나면 한동안 편할 거야."]])
		"deck-captain":
			say([["hero", "표두님, 갑판에 올라왔습니다."], ["captain", "좋다. 처음에는 내가 보이는 곳에 있어라. 무슨 일이 나면—"], ["sailor", "작은 배가 붙습니다! 저 표식은…… 흑린채입니다!"], ["captain", "모두 화물에서 떨어져라! 너는 이쪽 통로를 지켜. 무리해서 쫓지는 마라!"]], start_battle)
			dialogue_music_cues = {2: "ambush"}

func start_battle() -> void:
	city_overview.hide()
	music.play_track("battle")
	state = "battle"
	dialogue_lines = []
	dialogue_panel.hide()
	dialogue_cast.clear()
	title_screen.hide()
	ending.hide()
	top_hud.hide()
	bottom_hint.hide()
	exploration.set_active(false)
	exploration.hide()
	exploration.camera.enabled = false
	battle.begin()

func _on_victory(hp: int) -> void:
	music.play_track("title")
	state = "end"
	ending_hp.text = "남은 체력   %d / 300" % hp
	ending.show()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state == "service":
			if event.keycode == KEY_ESCAPE:
				city_service.close_counter()
			elif event.keycode == KEY_F1:
				reset()
			get_viewport().set_input_as_handled()
			return
		if city_overview.visible:
			if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
				toggle_city_map()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_TAB and state == "explore" and exploration.area_name == "changsha":
			toggle_city_map()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			music.toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F1:
			reset()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") or (state == "battle" and event.keycode in [KEY_ENTER, KEY_KP_ENTER]):
			if state == "explore":
				interact()
				get_viewport().set_input_as_handled()
			elif state == "battle":
				if battle.selected:
					battle.use_selected()
				else:
					battle.select_samjae()
				get_viewport().set_input_as_handled()
