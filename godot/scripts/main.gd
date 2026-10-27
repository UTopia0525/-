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
var ordinary_quests
var herbalist_quest
var artisan_quest
var wages_quest
var plaque_quest
var grain_quest
var qingya_quest
var cart_quest
var waterfront_quest
var levy_quest
var book_quest
var silk_quest
var nanjing_relief_quest
var death_screen
var duel_quest
var inn_quest
var impostor_quest
var alliance_visit
var alliance_story
var adventure_ui
var options
var dialogue_next: Button
var dialogue_badge: Panel
var dialogue_rule: Panel
var dialogue_history_button: Button
var dialogue_hint: Label
var dialogue_layout_pending:=false
var dialogue_reserved_height:=81.0
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
var dialogue_backdrop: ColorRect
var dialogue_panel: Panel
var dialogue_name: Label
var dialogue_text: Label
var dialogue_cast
var dialogue_history
var city_overview
var minimap
var city_service
var player_menu
var trade_intro
var quest_navigation
var prologue
var chapter_one
var bandit_story
var chapter_number := 0
var save_system
var settings_menu
var pending_service_id := ""
var story_visual
var story_caption: Label
var choice_screen: Control
var choice_buttons: Array[Button] = []
var choice_confirm: Button
var pending_choice := ""
var progress = preload("res://scripts/player_progress.gd").new()
var money := 0
var money_label: Label
var journey_label: Label
var chapter_goal: Label
var quest_heading: Label
var compact_toolbar: Panel
var continue_button: Button
var dialogue_lines: Array = []
var dialogue_index: int = 0
var dialogue_done: Callable
var ending: Control
var ending_hp: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_input()
	theme = Theme.new()
	theme.default_font = UI.BODY_FONT
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
	battle.defeat.connect(_on_defeat)
	quest_navigation = QUEST_NAVIGATION.new()
	quest_navigation.name = "QuestNavigation"
	add_child(quest_navigation)
	prologue = preload("res://scripts/prologue.gd").new()
	prologue.game = self
	add_child(prologue)
	story_visual = preload("res://scripts/story_visual.gd").new()
	ui_root.add_child(story_visual)
	_build_hud()
	_build_dialogue()
	_build_title()
	_build_ending()
	_build_story_choice()
	city_overview = CITY_OVERVIEW.new()
	ui_root.add_child(city_overview)
	city_service = preload("res://scripts/city_service.gd").new()
	city_service.game = self
	ui_root.add_child(city_service)
	city_service.closed.connect(func():
		state = "explore"
		exploration.set_active(true))
	chapter_one = preload("res://scripts/chapter_one.gd").new()
	chapter_one.game = self
	add_child(chapter_one)
	trade_intro = preload("res://scripts/trade_intro.gd").new()
	trade_intro.game = self
	add_child(trade_intro)
	bandit_story = preload("res://scripts/bandit_story.gd").new()
	bandit_story.game = self
	add_child(bandit_story)
	alliance_visit=preload("res://scripts/alliance_visit.gd").new();alliance_visit.game=self;add_child(alliance_visit)
	save_system = preload("res://scripts/save_system.gd").new()
	save_system.game = self
	add_child(save_system)
	settings_menu = preload("res://scripts/settings_menu.gd").new()
	settings_menu.game = self
	ui_root.add_child(settings_menu)
	player_menu = preload("res://scripts/player_menu.gd").new()
	player_menu.game = self
	ui_root.add_child(player_menu)
	dialogue_history = preload("res://scripts/dialogue_history.gd").new()
	dialogue_history.game = self
	ui_root.add_child(dialogue_history)
	options=preload("res://scripts/game_options.gd").new();options.game=self;add_child(options)
	adventure_ui=preload("res://scripts/adventure_ui.gd").new();adventure_ui.game=self;ui_root.add_child(adventure_ui)
	ordinary_quests=preload("res://scripts/ordinary_quests.gd").new();ordinary_quests.game=self;add_child(ordinary_quests)
	herbalist_quest=preload("res://scripts/herbalist_quest.gd").new();herbalist_quest.game=self;add_child(herbalist_quest)
	artisan_quest=preload("res://scripts/artisan_quest.gd").new();artisan_quest.game=self;add_child(artisan_quest)
	duel_quest=preload("res://scripts/duel_quest.gd").new();duel_quest.game=self;add_child(duel_quest)
	inn_quest=preload("res://scripts/inn_quest.gd").new();inn_quest.game=self;add_child(inn_quest)
	impostor_quest=preload("res://scripts/impostor_quest.gd").new();impostor_quest.game=self;add_child(impostor_quest)
	alliance_story=preload("res://scripts/alliance_story.gd").new();alliance_story.game=self;add_child(alliance_story)
	wages_quest=preload("res://scripts/wages_quest.gd").new();wages_quest.game=self;add_child(wages_quest)
	plaque_quest=preload("res://scripts/plaque_quest.gd").new();plaque_quest.game=self;add_child(plaque_quest)
	grain_quest=preload("res://scripts/grain_quest.gd").new();grain_quest.game=self;add_child(grain_quest)
	qingya_quest=preload("res://scripts/qingya_quest.gd").new();qingya_quest.game=self;add_child(qingya_quest)
	nanjing_relief_quest=preload("res://scripts/nanjing_relief_quest.gd").new();nanjing_relief_quest.game=self;add_child(nanjing_relief_quest)
	silk_quest=preload("res://scripts/silk_quest.gd").new();silk_quest.game=self;add_child(silk_quest)
	cart_quest=preload("res://scripts/cart_quest.gd").new();cart_quest.game=self;add_child(cart_quest)
	book_quest=preload("res://scripts/book_quest.gd").new();book_quest.game=self;add_child(book_quest)
	levy_quest=preload("res://scripts/levy_quest.gd").new();levy_quest.game=self;add_child(levy_quest)
	waterfront_quest=preload("res://scripts/waterfront_quest.gd").new();waterfront_quest.game=self;add_child(waterfront_quest)
	progress.progress_changed.connect(_progress_changed)
	battle.sound_requested.connect(options.play)
	var log_button=UI.button(battle,"교전 기록 · L",Rect2(915,145,205,35))
	log_button.pressed.connect(adventure_ui.open_log)
	death_screen=preload("res://scripts/death_screen.gd").new();death_screen.game=self;ui_root.add_child(death_screen)
	reset()

func _setup_input() -> void:
	var definitions = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "interact": [KEY_F], "inventory":[KEY_I], "martial_menu":[KEY_K], "journal":[KEY_Q]}
	for action in definitions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for code in definitions[action]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)
	# Some forwarded keyboard events contain only the logical F code. Keep the
	# physical binding for Korean layouts, and accept that event shape as well.
	var logical_interact = InputEventKey.new()
	logical_interact.keycode = KEY_F
	InputMap.action_add_event("interact", logical_interact)

func _build_hud() -> void:
	top_hud = Control.new()
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(top_hud)
	var purse = UI.panel(top_hud, Rect2(1024,16,240,34),Color("101e20ee"))
	money_label = UI.label(purse,"",Rect2(10,6,220,22),14,UI.TEXT)
	money_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var journey=UI.panel(top_hud,Rect2(218,16,310,34),Color("101e20ee"))
	journey_label=UI.label(journey,"도원 · 강호행",Rect2(12,6,286,22),14,UI.TEXT)
	minimap=MINIMAP.new();top_hud.add_child(minimap);minimap.bind_world(exploration);minimap.quest_navigation=quest_navigation
	location=minimap.place_label
	var mission=UI.panel(top_hud,Rect2(982,68,282,112),Color("101e20ee"))
	var style=UI.box(Color("101e20ee"));style.border_width_left=3;mission.add_theme_stylebox_override("panel",style)
	chapter_goal=UI.label(mission,"주요 목표 · 장사를 탐사하세요",Rect2(12,7,258,21),14,UI.GOLD)
	chapter_goal.hide()
	quest_heading=UI.label(mission,"지금 할 일",Rect2(12,9,258,25),17,UI.GOLD)
	quest_heading.add_theme_font_override("font",UI.BRUSH_FONT);quest_heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	objective=UI.label(mission,"",Rect2(12,40,258,60),14)
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	objective.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	compact_toolbar=UI.panel(top_hud,Rect2(316,666,648,38),Color("101e20ee"))
	var labels=["I  소지품","K  무공","Q  의뢰","R  세력","TAB  지도","ESC  설정","F2  도움말"]
	for i in range(labels.size()):
		var button=UI.button(compact_toolbar,labels[i],Rect2(5+i*91,4,89,30))
		button.add_theme_font_size_override("font_size",13)
		for style_name in ["normal","hover","hover_pressed","pressed","disabled","focus"]:
			var compact=button.get_theme_stylebox(style_name).duplicate()
			compact.set_content_margin(SIDE_LEFT,6);compact.set_content_margin(SIDE_RIGHT,6)
			compact.set_content_margin(SIDE_TOP,3);compact.set_content_margin(SIDE_BOTTOM,3)
			button.add_theme_stylebox_override(style_name,compact)
		button.pressed.connect(_hud_action.bind(i))
	bottom_hint=UI.label(ui_root,UI.EXPLORATION_HINT,Rect2(24,680,1230,27),14,UI.TEXT)
	bottom_hint.add_theme_color_override("font_shadow_color",Color("11211a"));bottom_hint.add_theme_constant_override("shadow_offset_x",2);bottom_hint.add_theme_constant_override("shadow_offset_y",2)

func _hud_action(index: int) -> void:
	match index:
		0:player_menu.open_menu("inventory")
		1:player_menu.open_menu("martial")
		2:adventure_ui.open_journal()
		3:adventure_ui.open_favor()
		4:toggle_city_map()
		5:settings_menu.open_menu()
		6:adventure_ui.open_help()

func _build_dialogue() -> void:
	dialogue_backdrop = ColorRect.new()
	dialogue_backdrop.name = "CityDialogueBackdrop"
	dialogue_backdrop.color = Color(0.025, 0.045, 0.04, 0.64)
	dialogue_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(dialogue_backdrop)
	dialogue_backdrop.hide()
	story_caption = UI.label(ui_root, "", Rect2(36, 32, 1200, 45), 25, UI.GOLD)
	story_caption.add_theme_color_override("font_outline_color", Color("091718"))
	story_caption.add_theme_constant_override("outline_size", 5)
	story_caption.hide()
	dialogue_cast = PORTRAITS.new()
	ui_root.add_child(dialogue_cast)
	dialogue_panel=preload("res://scripts/paper_dialogue_panel.gd").new()
	dialogue_panel.position=Vector2(49,525);dialogue_panel.size=Vector2(1182,173)
	ui_root.add_child(dialogue_panel);dialogue_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	dialogue_panel.visibility_changed.connect(_update_dialogue_backdrop)
	var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=dialogue_panel
	dialogue_badge=painter.box(dialogue_panel,Rect2(37,-14,201,39),painter.TEAL,Color("8d805f"),2)
	dialogue_name=painter.text(dialogue_panel,"",Rect2(51,-11,173,32),25,Color("f3e8d2"),true)
	dialogue_text=painter.text(dialogue_panel,"",Rect2(42,39,1091,81),21,painter.INK)
	dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;dialogue_text.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
	dialogue_text.minimum_size_changed.connect(_schedule_dialogue_layout)
	dialogue_rule=painter.box(dialogue_panel,Rect2(42,117,1090,1),painter.LINE)
	dialogue_hint=painter.text(dialogue_panel,"F  다음 대사",Rect2(43,129,175,25),15,painter.MUTED)
	dialogue_history_button=painter.button("H  지난 대화",Rect2(210,127,166,29))
	dialogue_history_button.pressed.connect(func():dialogue_history.open_history())
	dialogue_next=painter.button("다음  ▸",Rect2(1033,126,100,29),true);dialogue_next.pressed.connect(advance_dialogue)
	painter.free()
	dialogue_panel.hide()
	dialogue_cast.clear()

func _update_dialogue_backdrop() -> void:
	if is_instance_valid(dialogue_history) and not dialogue_panel.visible: dialogue_history.close_history()
	# Keep quest notifications above the dialogue text instead of obscuring it.
	if is_instance_valid(adventure_ui):adventure_ui.toast.position.y=50 if dialogue_panel.visible else 590
	# Shade the city and HUD, keeping portraits, captions and dialogue above it.
	dialogue_backdrop.visible = dialogue_panel.visible and not story_visual.visible

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
	title_screen = preload("res://scripts/title_screen.gd").new()
	title_screen.game = self
	ui_root.add_child(title_screen)
	continue_button = title_screen.resume_button

func start_wuchang() -> void:
	start_city()
	# The explicit title-screen preview is separate from departing Changsha in play.
	exploration.load_area("wuchang")
	exploration.player.position=exploration.safe_player_position(exploration.city_point([1100,1790]))
	exploration.player.stop();exploration.camera.snap_to_player();exploration.set_active(true)

func _build_ending() -> void:
	ending = _full_overlay(Color(0.035, 0.07, 0.055, 0.94))
	UI.label(ending, "첫 번째 교전 · 완료", Rect2(360, 140, 700, 35), 20, UI.GOLD)
	UI.label(ending, "통로를 확보했다", Rect2(360, 210, 850, 70), 46)
	UI.label(ending, "수적을 물리쳤습니다.\n갑판 너머에서는 아직 소란이 이어집니다.", Rect2(360, 305, 850, 80), 23)
	ending_hp = UI.label(ending, "", Rect2(360, 405, 850, 36), 24, UI.GOLD)
	UI.label(ending, "전투만 체험 모드입니다.\n전체 이야기는 타이틀의 표행 시작으로 진행하세요.", Rect2(360, 470, 850, 66), 18, UI.MUTED)
	var retry = UI.button(ending, "전투 다시 하기", Rect2(360, 570, 230, 56), true)
	retry.pressed.connect(start_battle)
	var restart = UI.button(ending, "나루터부터 다시", Rect2(610, 570, 230, 56))
	restart.pressed.connect(reset)
	ending.hide()

func regional_quests() -> Array:return [waterfront_quest,levy_quest,book_quest,cart_quest,silk_quest,nanjing_relief_quest,qingya_quest,alliance_story,herbalist_quest,artisan_quest,wages_quest,plaque_quest,grain_quest,duel_quest,inn_quest,impostor_quest]
func encounters() -> Array:return qingya_quest.data.encounters+qingya_quest.data.get("legacy_encounters",[])+bandit_story.data.encounters+[waterfront_quest.data.encounter,herbalist_quest.data.encounter,duel_quest.data.encounter,inn_quest.data.encounter,impostor_quest.data.encounter]

func reset() -> void:
	if is_instance_valid(death_screen):death_screen.dismiss()
	if is_instance_valid(adventure_ui):adventure_ui.reset()
	if is_instance_valid(waterfront_quest):waterfront_quest.reset()
	if is_instance_valid(levy_quest):levy_quest.reset()
	if is_instance_valid(book_quest):book_quest.reset()
	if is_instance_valid(cart_quest):cart_quest.reset()
	if is_instance_valid(silk_quest):silk_quest.reset()
	if is_instance_valid(nanjing_relief_quest):nanjing_relief_quest.reset()
	if is_instance_valid(qingya_quest):qingya_quest.reset()
	if is_instance_valid(grain_quest):grain_quest.reset()
	if is_instance_valid(plaque_quest):plaque_quest.reset()
	if is_instance_valid(wages_quest):wages_quest.reset()
	if is_instance_valid(alliance_story):alliance_story.reset()
	if is_instance_valid(impostor_quest):impostor_quest.reset()
	if is_instance_valid(inn_quest):inn_quest.reset()
	if is_instance_valid(duel_quest):duel_quest.reset()
	if is_instance_valid(artisan_quest):artisan_quest.reset()
	if is_instance_valid(herbalist_quest):herbalist_quest.reset()
	if is_instance_valid(ordinary_quests):ordinary_quests.reset()
	if is_instance_valid(settings_menu): settings_menu.close_menu()
	progress.reset()
	chapter_number = 0
	chapter_one.reset()
	trade_intro.reset()
	player_menu.dismiss()
	pending_service_id = ""
	bandit_story.reset()
	alliance_visit.reset()
	prologue.cancel()
	money = 0
	choice_screen.hide()
	story_visual.hide()
	story_caption.hide()
	title_screen.refresh()
	dialogue_done = Callable()
	city_service.dismiss()
	quest_navigation.clear()
	city_overview.hide()
	bottom_hint.text = UI.EXPLORATION_HINT
	state = "title"
	music.play_track("title")
	talked_captain = false
	dialogue_lines.clear()
	dialogue_panel.hide()
	dialogue_cast.clear()
	ending.hide()
	battle.cancel()
	battle.set_encounter({})
	battle.enemy_hp = battle.Rules.ENEMY_MAX_HP
	battle.player_hp = battle.Rules.PLAYER_MAX_HP
	battle.qi.start(int(progress.stats.inner))
	battle.selected = false
	battle.selected_action = ""
	battle.turn = 1
	battle.player_stats = progress.stats.duplicate()
	battle.set_loadout(progress.loadout)
	battle.equip_weapon("sword")
	exploration.show()
	exploration.load_area("dock")
	exploration.set_active(false)
	top_hud.show()
	bottom_hint.hide()
	location.text = "동정호 남쪽 · 청류진 나루"
	objective.text = "첫 표행을 시작하세요."
	chapter_goal.hide()
	quest_heading.position.y = 9
	objective.position.y = 40
	objective.size.y = 60
	quest_heading.text = "지금 할 일"
	title_screen.show()

func start_story() -> void:
	reset()
	prologue.begin()
	music.play_track("dock")
	title_screen.hide()
	state = "explore"
	bottom_hint.show()
	objective.text = "나루 끝의 표두 서문길과 대화하기"
	say(prologue.lines("opening"))

func start_city() -> void:
	reset()
	enter_city()

func enter_city(at_port: bool = false) -> void:
	story_visual.hide()
	story_caption.hide()
	choice_screen.hide()
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
	if at_port:
		exploration.player.position = exploration.city_point([280, 500])
		exploration.player.stop()
		exploration.camera.snap_to_player()
	exploration.set_active(true)
	top_hud.show()
	location.text = "장사 · " + exploration.district_at_player()
	objective.text = "시장·골목·나루·성밖 농촌 둘러보기"
	bottom_hint.text = UI.EXPLORATION_HINT
	bottom_hint.show()
	ordinary_quests.refresh_world()
	adventure_ui.tip("city","Q 의뢰 일지 · 노란 ! 대화로 의뢰 수락")

func _process(_delta: float) -> void:
	money_label.text = "%d문 · 명성 %d" % [money, progress.fame]
	var total:=0
	for value in progress.stats.values():total+=int(value)
	journey_label.text=("제%d장 · " % chapter_number if prologue.active or prologue.completed else "")+"도원 · "+("절정까지 %d" % (100-total) if total<100 else progress.RULES.realm(total))
	compact_toolbar.visible=exploration.area_name in ["changsha","mountain_road","wuchang","alliance_office","qingya_hamlet","qingya_camp","nanjing"] and state=="explore" and dialogue_lines.is_empty()
	if state == "explore" and exploration.area_name in ["changsha","mountain_road","wuchang","alliance_office","qingya_hamlet","qingya_camp","nanjing"]:
		location.text = exploration.city_data.name+" · " + exploration.district_at_player()
		var exploring_changsha: bool = chapter_number == 1 and exploration.area_name == "changsha" and bandit_story.stage == "dormant"
		chapter_goal.visible = exploring_changsha
		quest_heading.position.y = 30 if exploring_changsha else 9
		objective.position.y = 59 if exploring_changsha else 40
		objective.size.y = 43 if exploring_changsha else 60
		var goal: Dictionary = quest_navigation.get_goal(exploration)
		quest_heading.text=goal.quest_title+" · Q" if not goal.is_empty() else "강호행 · Q 의뢰"
		bottom_hint.hide()
		objective.text = goal.label if not goal.is_empty() else ("총무당 둘러보기 · 남쪽 출입 지점에서 F 이동" if exploration.area_name=="alliance_office" else "산길을 따라 북쪽 무창으로 · 출입 지점에서 F 이동" if exploration.area_name=="mountain_road" else "무창 둘러보기 · 남쪽 농촌 끝에서 장사 방면" if exploration.area_name=="wuchang" else "삼거리 산촌 · 북쪽 청애채 / 서쪽 무창 / 동쪽 남경 방면" if exploration.area_name=="qingya_hamlet" else "청애채 · 남쪽 정문으로 산촌에 돌아가기" if exploration.area_name=="qingya_camp" else "남경 탐사 · 객잔·창고·진회하 둘러보기" if exploration.area_name=="nanjing" else "시장·골목·나루·성밖 농촌 둘러보기")
		objective.tooltip_text=(chapter_goal.text+"\n" if exploring_changsha else "")+quest_heading.text+"\n"+objective.text
	bandit_story.maybe_start()
	alliance_story.maybe_start()

func toggle_city_map() -> void:
	if not dialogue_lines.is_empty() or state != "explore" or player_menu.visible: return
	if city_overview.visible:
		city_overview.hide()
		exploration.set_active(true)
	else:
		exploration.set_active(false)
		city_overview.open_for(exploration, quest_navigation.get_goal(exploration))

func say(lines: Array, done: Callable = Callable(), listeners: Array = ["hero"]) -> void:
	if is_instance_valid(adventure_ui):adventure_ui.tip("dialogue","F 다음 대사 · H 지난 대화")
	if is_instance_valid(dialogue_history): dialogue_history.close_history()
	if lines.is_empty():
		return
	exploration.set_active(false)
	# Keep playback independent: reset/load must never clear reusable scene data.
	dialogue_lines = lines.duplicate(true)
	_reserve_dialogue_space()
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
	_update_dialogue_backdrop()
	_show_line()

func _show_line() -> void:
	if dialogue_music_cues.has(dialogue_index):
		music.play_track(dialogue_music_cues[dialogue_index])
	var line = dialogue_lines[dialogue_index]
	var subtitle: String = str(line[2]) if line.size() > 2 and line[2] is String else ""
	dialogue_name.text = PORTRAITS.ACTORS[line[0]].name + (" · " + subtitle if not subtitle.is_empty() else "")
	dialogue_text.text = line[1]
	var staging: Dictionary = {}
	if line.size() > 2 and line[2] is Dictionary: staging = line[2].duplicate(true)
	if line.size() > 3 and line[3] is Dictionary: staging = line[3].duplicate(true)
	# Infer the hero's reply target from the script, so loading a line is deterministic.
	if not staging.has("to") and line[0] == "hero" and dialogue_index > 0:
		var previous: String = str(dialogue_lines[dialogue_index - 1][0])
		if previous != "hero": staging["to"] = previous
	dialogue_cast.set_speaker(line[0], staging)
	_layout_dialogue()

func advance_dialogue() -> void:
	if is_instance_valid(adventure_ui) and adventure_ui.window.visible and adventure_ui.mode=="result":adventure_ui.dismiss()
	if is_instance_valid(dialogue_history) and dialogue_history.visible: return
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
	if preload("res://scripts/overland_travel.gd").use(self,npc):return
	if waterfront_quest.handle_interaction(str(npc.id)):return
	if levy_quest.handle_interaction(str(npc.id)):return
	if book_quest.handle_interaction(str(npc.id)):return
	if cart_quest.handle_interaction(str(npc.id)):return
	if silk_quest.handle_interaction(str(npc.id)):return
	if nanjing_relief_quest.handle_interaction(str(npc.id)):return
	if qingya_quest.handle_interaction(str(npc.id)):return
	if alliance_story.handle_interaction(str(npc.id)):return
	if plaque_quest.handle_interaction(str(npc.id)):return
	if grain_quest.handle_interaction(str(npc.id)):return
	if wages_quest.handle_interaction(str(npc.id)):return
	if impostor_quest.handle_interaction(str(npc.id)):return
	if inn_quest.handle_interaction(str(npc.id)):return
	if duel_quest.handle_interaction(str(npc.id)):return
	if artisan_quest.handle_interaction(str(npc.id)):return
	if herbalist_quest.handle_interaction(str(npc.id)):return
	if alliance_visit.handle_interaction(str(npc.id)):return
	if ordinary_quests.handle_interaction(str(npc.id)): return
	if trade_intro.handle_interaction(str(npc.id)): return
	if bandit_story.handle_interaction(str(npc.id)): return
	if npc.has("service_id"):
		var service: Dictionary = {}
		for definition in exploration.city_data.services:
			if definition.id == npc.service_id:
				service = definition
		if not service.is_empty():
			var greeting: String = {"market": "근력을 돋우고 몸을 가볍게 할 영약이 있지요. 하급 영약은 한 알에 백문입니다. 약력도 과하면 독이니, 같은 약은 평생 열 알까지만 드세요.", "workshop": ("여기서는 정련검과 후배도, 균형창만 취급하오. 어느 것이든 삼백문이니 손에 맞는 병장기를 고르시오." if exploration.area_name=="changsha" else "검이든 도든 창이든, 손에 맞아야 제 위력을 내는 법이지요. 삼백, 오백, 칠백문짜리가 있으니 날과 무게를 살펴 고르시오."), "training": "무공 한 문을 전수하는 데 삼백오십문이오. 허나 근기와 깨달음이 따르지 않으면 배워도 펼칠 수 없소. K를 눌러 실전에 쓸 네 가지 초식을 미리 갖추시오."}[service.kind]
			pending_service_id = service.id
			say(service.get("greeting_lines",[[service.get("actor_id",service.id), greeting]]), _service_done)
		return
	if exploration.area_name in ["wuchang","nanjing"]:
		for entry in exploration.city_data.residents:
			if entry.id==npc.id:say(entry.dialogue);return
	if exploration.area_name=="changsha" and not npc.has("service_id") and npc.id not in ["bandit_officer","bandit_muster"]:
		for resident in exploration.city_data.residents:
			if resident.id==npc.id and resident.has("character_profile"):
				say([[str(npc.id),resident.character_profile.smalltalk]]);return
		say([[str(npc.id),"오늘도 장사 거리는 분주하군요. 무슨 일이 있거든 길가 사람들에게 물어보세요."]]);return
	match npc.id:
		"captain":
			say(prologue.lines("captain"), _captain_done)
		"apothecary", "sailor", "clerk":
			say(prologue.lines(npc.id))
		"boarding":
			if not talked_captain:
				say([["hero", "먼저 표두님께 인사하자."]])
			else:
				say(prologue.lines("boarding"), _boarding_done)
		"deck-sailor":
			say([["sailor", "물살은 괜찮군. 저 좁은 수로만 지나면 한동안 편할 거야."]])
		"deck-captain":
			say(prologue.lines("deck"), start_battle)
			dialogue_music_cues = {5: "ambush"}

func start_battle(encounter: Dictionary = {}) -> void:
	if is_instance_valid(adventure_ui):adventure_ui.dismiss()
	player_menu.dismiss()
	story_visual.hide()
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
	battle.player_stats = progress.stats.duplicate()
	battle.set_loadout(progress.loadout)
	battle.set_encounter(encounter)
	battle.begin()
	adventure_ui.tip("battle","행동을 고른 뒤 사용으로 실행 · L 교전 기록")

func _on_victory(hp: int) -> void:
	if state!="battle":return
	_finish_victory(hp)
	adventure_ui.record_result(true)

func _on_defeat() -> void:
	if state!="battle":return
	if preload("res://scripts/combat_outcome.gd").defeat_policy(battle.encounter)=="death":
		adventure_ui.record_result(false,false)
		enter_game_over()
		return
	if qingya_quest.in_battle():qingya_quest.after_defeat()
	elif impostor_quest.in_battle():impostor_quest.after_defeat()
	elif inn_quest.in_battle():inn_quest.after_defeat()
	elif duel_quest.in_battle():duel_quest.after_defeat()
	elif herbalist_quest.in_battle():herbalist_quest.after_defeat()
	elif bandit_story.in_battle():bandit_story.after_defeat()
	adventure_ui.record_result(false)

func enter_game_over() -> void:
	if state!="battle":return
	state="game_over"
	get_tree().paused=false
	adventure_ui.dismiss();adventure_ui.toast.hide();player_menu.dismiss();settings_menu.close_menu()
	dialogue_history.close_history();city_overview.hide();city_service.dismiss()
	dialogue_lines.clear();dialogue_done=Callable();dialogue_panel.hide();dialogue_cast.clear()
	top_hud.hide();bottom_hint.hide();ending.hide();choice_screen.hide();story_visual.hide();story_caption.hide()
	exploration.set_active(false);exploration.hide();exploration.camera.enabled=false
	battle.generation+=1;battle.running=false;battle.busy=false
	battle.use_button.disabled=true
	for button in battle.skill_buttons:button.disabled=true
	battle.basic_button.disabled=true;battle.enemy_actor.stop();battle.player_actor.fall()
	music.play_track("title")
	death_screen.present()

func _finish_victory(hp: int) -> void:
	if state != "battle": return
	if waterfront_quest.in_battle():
		waterfront_quest.after_victory()
		return
	if qingya_quest.in_battle():
		qingya_quest.after_victory()
		return
	if impostor_quest.in_battle():
		impostor_quest.after_victory()
		return
	if inn_quest.in_battle():
		inn_quest.after_victory()
		return
	if duel_quest.in_battle():
		duel_quest.after_victory()
		return
	if herbalist_quest.in_battle():
		herbalist_quest.after_victory()
		return
	if bandit_story.in_battle():
		bandit_story.after_victory()
		return
	if prologue.active:
		prologue.after_victory()
		return
	music.play_track("title")
	state = "end"
	ending_hp.text = "남은 체력   %d / 300" % hp
	ending.show()

func _input(event: InputEvent) -> void:
	if state == "title" and not settings_menu.window.visible and not adventure_ui.window.visible:
		if title_screen.handle_input(event): get_viewport().set_input_as_handled()
		return
	if state=="game_over":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.is_action_pressed("interact") or event.keycode in [KEY_ENTER,KEY_KP_ENTER]:death_screen.return_to_title()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(adventure_ui) and adventure_ui.window.visible:return
	if event is InputEventKey and event.pressed and not event.echo and not settings_menu.window.visible:
		if event.keycode==KEY_R:
			adventure_ui.open_favor();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_Q:
			adventure_ui.open_journal();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_F2:
			adventure_ui.open_help();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_L:
			adventure_ui.open_log();get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H and not dialogue_lines.is_empty():
		dialogue_history.open_history()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if player_menu.visible:
			if event.is_action_pressed("inventory"): player_menu.open_menu("inventory")
			elif event.is_action_pressed("martial_menu"): player_menu.open_menu("martial")
			elif event.keycode == KEY_ESCAPE: player_menu.close_menu()
			elif event.keycode == KEY_F1: reset()
			elif event.keycode == KEY_M: music.toggle()
			else: player_menu.handle_key(event)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("inventory") or event.is_action_pressed("martial_menu"):
			player_menu.open_menu("inventory" if event.is_action_pressed("inventory") else "martial")
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not city_overview.visible and state != "service":
		settings_menu.open_menu()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if state == "choice":
			if event.keycode == KEY_F1: reset()
			elif event.keycode == KEY_M: music.toggle()
			elif event.keycode in [KEY_UP, KEY_LEFT, KEY_1]: select_story_choice("treasure")
			elif event.keycode in [KEY_DOWN, KEY_RIGHT, KEY_2]: select_story_choice("rescue")
			elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]: confirm_story_choice()
			get_viewport().set_input_as_handled()
			return
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
		if event.keycode == KEY_TAB and state == "explore" and exploration.area_name in ["changsha","mountain_road","wuchang","alliance_office","qingya_hamlet","qingya_camp","nanjing"]:
			toggle_city_map()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			music.toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F1:
			reset()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") or (state == "battle" and event.keycode in [KEY_ENTER, KEY_KP_ENTER]):
			if state in ["explore", "story"]:
				interact()
				get_viewport().set_input_as_handled()
			elif state == "battle":
				if battle.selected:
					battle.use_selected()
				else:
					battle.select_basic_attack()
				get_viewport().set_input_as_handled()

func _build_story_choice() -> void:
	choice_screen = _full_overlay(Color("09181aef"))
	choice_screen.focus_mode = Control.FOCUS_ALL
	UI.label(choice_screen, "한쪽으로만 뻗을 수 있는 손", Rect2(180, 90, 980, 50), 32, UI.GOLD)
	var intro = UI.label(choice_screen, "귀물함은 왼쪽 물살로, 허만복은 반대편 잔해 아래로 떠밀려간다.
먼저 한쪽에 닿으면 다른 쪽으로 돌아갈 시간은 없다.", Rect2(180, 160, 950, 75), 21)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index in range(2):
		var button = UI.button(choice_screen, ["1  귀물함을 향해 헤엄친다", "2  허만복에게 손을 뻗는다"][index], Rect2(180, 275 + index * 110, 920, 55))
		button.pressed.connect(select_story_choice.bind(["treasure", "rescue"][index]))
		choice_buttons.append(button)
		UI.label(choice_screen, ["인도 시 보수 3,000문 · 허만복에게 돌아갈 시간은 없다.", "허만복을 구한다 · 귀물을 잃고 인도 보수는 받지 못한다."][index], Rect2(198, 335 + index * 110, 900, 35), 18)
	choice_confirm = UI.button(choice_screen, "선택한 행동을 실행 · Enter", Rect2(640, 520, 460, 58))
	choice_confirm.pressed.connect(confirm_story_choice)
	UI.label(choice_screen, "방향키 / 1·2 또는 클릭으로 선택 → Enter / 실행 버튼으로 확정
선택 중에는 시간이 흐르지 않습니다. F키로 확정되지 않습니다.", Rect2(180, 610, 950, 65), 17, UI.MUTED)
	choice_screen.hide()

func show_story_choice() -> void:
	state = "choice"
	pending_choice = ""
	story_visual.paused = true
	choice_confirm.disabled = true
	for button in choice_buttons: UI.selection(button,false)
	choice_screen.show()
	choice_screen.grab_focus()

func select_story_choice(value: String) -> void:
	if state != "choice": return
	pending_choice = value
	choice_confirm.disabled = false
	for index in range(2):
		UI.selection(choice_buttons[index],["treasure", "rescue"][index]==value)

func confirm_story_choice() -> void:
	if state == "choice" and not pending_choice.is_empty():
		prologue.choose(pending_choice)

func _captain_done() -> void:
	talked_captain = true
	objective.text = "오른쪽 널빤지를 건너 호송선에 오르기"

func _boarding_done() -> void:
	exploration.load_area("deck")
	music.play_track("voyage")
	location.text = "호송선 · 동정호 수로"
	objective.text = "갑판의 표두에게 출항 보고하기"

func _service_done() -> void:
	for service in exploration.city_data.get("services", []):
		if service.id == pending_service_id:
			state = "service"
			exploration.set_active(false)
			city_service.open_counter(service)

func _progress_changed(event: Dictionary) -> void:
	if not is_instance_valid(adventure_ui):return
	var name: String=progress.weapons.get_weapon(event.id).get("name",event.id) if event.get("kind")=="weapon" else progress.arts.get_skill(event.id).get("name",event.id) if event.get("kind")=="art" else progress.elixirs.get(event.id,{}).get("name",event.id)
	match event.event:
		"purchase":adventure_ui.notify(("무공 습득 · " if event.kind=="art" else "구매 완료 · ")+name+" · -%d문" % int(event.price),"learn" if event.kind=="art" else "coin")
		"manual_learn":adventure_ui.notify("무공 습득 · "+name+" · K에서 편성하세요.","learn")
		"consume":adventure_ui.notify("영약 복용 · "+name,"confirm")
		"loadout":adventure_ui.notify("초식 편성을 바꾸었습니다.","confirm")

func _schedule_dialogue_layout() -> void:
	if dialogue_layout_pending:return
	dialogue_layout_pending=true;_layout_dialogue.call_deferred()
func _layout_dialogue() -> void:
	dialogue_layout_pending=false
	if not is_instance_valid(dialogue_text) or not is_instance_valid(dialogue_badge):return
	var needed=dialogue_text.get_line_count()*dialogue_text.get_line_height()+4
	var height=clampf(maxf(float(needed),dialogue_reserved_height),81.0,410.0)+92.0
	dialogue_panel.position=Vector2(49,698-height);dialogue_panel.size=Vector2(1182,height)
	dialogue_text.size=Vector2(1091,height-92)
	dialogue_rule.position.y=height-56;dialogue_hint.position.y=height-44
	dialogue_history_button.position.y=height-46;dialogue_next.position.y=height-47
	var width=clampf(dialogue_name.get_theme_font("font").get_string_size(dialogue_name.text,HORIZONTAL_ALIGNMENT_LEFT,-1,25).x+28,201,600)
	dialogue_badge.size.x=width;dialogue_name.size.x=width-28
	dialogue_cast.position.y=minf(143,maxf(25,dialogue_panel.position.y-110))
	var available=maxf(70,dialogue_panel.position.y-dialogue_cast.position.y-10)
	if not is_equal_approx(dialogue_cast.size.y,available):
		var participants=[]
		for id in dialogue_cast.portraits:
			var actor=PORTRAITS.ACTORS[id].duplicate();actor.id=id;participants.append(actor)
		var active: String=dialogue_cast.active_actor
		dialogue_cast.size=Vector2(1280,available)
		if not participants.is_empty():
			dialogue_cast.set_participants(participants)
			if active!="" and not dialogue_lines.is_empty():
				var line=dialogue_lines[dialogue_index];var staging={}
				if line.size()>2 and line[2] is Dictionary:staging=line[2]
				if line.size()>3 and line[3] is Dictionary:staging=line[3]
				if not staging.has("to") and active=="hero" and dialogue_index>0 and dialogue_lines[dialogue_index-1][0]!="hero":staging=staging.merged({"to":dialogue_lines[dialogue_index-1][0]})
				dialogue_cast.set_speaker(active,staging)

func _reserve_dialogue_space() -> void:
	dialogue_reserved_height=81.0
	if not is_instance_valid(dialogue_text):return
	var font=dialogue_text.get_theme_font("font")
	var font_size=dialogue_text.get_theme_font_size("font_size")
	for line in dialogue_lines:
		var paragraph=TextParagraph.new();paragraph.width=1091
		paragraph.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
		paragraph.add_string(str(line[1]),font,font_size)
		dialogue_reserved_height=maxf(dialogue_reserved_height,paragraph.get_line_count()*dialogue_text.get_line_height()+8)
