extends Node
## First chapter handoff: greeting, real quest acceptance, then one chapter card.
var game
var intro_started := false
var intro_complete := false
var banner_shown := false
var accepted_quests: Dictionary = {}
var banner: Control
var banner_tween: Tween
var greeting: Array
const FIRST_QUEST = "changsha_cloth"

func _ready() -> void:
	greeting = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_one_intro.json"))
	banner = Control.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color("081613e8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.add_child(shade)
	var label = Label.new()
	label.text = "1장"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_font_override("font", preload("res://scripts/ui.gd").BRUSH_FONT)
	label.add_theme_color_override("font_color", Color("e8d7af"))
	banner.add_child(label)
	game.ui_root.add_child(banner)
	banner.hide()

func reset() -> void:
	if banner_tween and banner_tween.is_valid(): banner_tween.kill()
	banner.hide()
	intro_started = false
	intro_complete = false
	banner_shown = false
	accepted_quests.clear()

func begin() -> void:
	if intro_started or intro_complete: return
	intro_started = true
	game.chapter_number = 1
	game.state = "story"
	game.exploration.set_active(false)
	game.top_hud.hide()
	game.story_caption.text = "항구 앞 포목점"
	game.story_caption.show()
	game.bottom_hint.text = "F  다음 대사     ·     M  음악     ·     F1  타이틀"
	game.prologue.save_checkpoint()
	game.say(greeting, _accept_first_quest)

func _accept_first_quest() -> void:
	if not intro_started or intro_complete: return
	intro_complete = true
	accepted_quests[FIRST_QUEST] = {"status":"active", "stage":"deliver"}
	game.quest_navigation.track(FIRST_QUEST, "deliver")
	show_banner()

func show_banner() -> void:
	if banner_shown:
		finish_handoff()
		return
	banner_shown = true
	game.state = "chapter_transition"
	game.exploration.set_active(false)
	game.story_caption.hide()
	game.bottom_hint.hide()
	banner.modulate.a = 0.0
	banner.show()
	game.prologue.save_checkpoint()
	banner_tween = create_tween()
	banner_tween.tween_property(banner, "modulate:a", 1.0, 0.45)
	banner_tween.tween_interval(1.4)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.55)
	banner_tween.tween_callback(finish_handoff)

func finish_handoff() -> void:
	banner.hide()
	game.story_caption.hide()
	game.top_hud.show()
	game.bottom_hint.text = preload("res://scripts/ui.gd").EXPLORATION_HINT
	game.bottom_hint.show()
	game.state = "explore"
	game.exploration.set_active(true)

func snapshot() -> Dictionary:
	return {"intro_complete":intro_complete, "banner_shown":banner_shown, "accepted_quests":accepted_quests.duplicate(true)}

func restore(data: Dictionary) -> void:
	reset()
	intro_complete = data.get("intro_complete", false)
	banner_shown = data.get("banner_shown", false)
	if not intro_complete:
		begin()
		return
	intro_started = true
	game.chapter_number = 1
	accepted_quests = data.accepted_quests.duplicate(true)
	game.quest_navigation.track(FIRST_QUEST, accepted_quests[FIRST_QUEST].stage)
	if banner_shown: finish_handoff()
	else: show_banner()
