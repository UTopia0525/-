extends Control

signal victory(remaining_hp: int)

const UI = preload("res://scripts/ui.gd")
const Rules = preload("res://scripts/rules.gd")
var player_hp: int = Rules.PLAYER_MAX_HP
var enemy_hp: int = Rules.ENEMY_MAX_HP
var selected: bool = false
var busy: bool = false
var running: bool = false
var generation: int = 0
var turn: int = 1
var scene_image: TextureRect
var enemy_text: Label
var player_text: Label
var enemy_bar: ProgressBar
var player_bar: ProgressBar
var heading: Label
var detail: Label
var note: Label
var turn_label: Label
var select_button: Button
var use_button: Button
var damage_label: Label
var float_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_image = TextureRect.new()
	scene_image.texture = preload("res://assets/battle-deck.png")
	scene_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene_image.size = Vector2(1280, 510)
	add_child(scene_image)
	var enemy_panel = UI.panel(self, Rect2(24, 24, 320, 126))
	UI.label(enemy_panel, "흑린채 · 일반 수적", Rect2(18, 10, 285, 24), 13, UI.GOLD)
	UI.label(enemy_panel, "흑린채 수적", Rect2(18, 34, 285, 32), 24)
	enemy_text = UI.label(enemy_panel, "", Rect2(18, 71, 285, 22), 16)
	enemy_bar = _health_bar(enemy_panel, Rect2(18, 103, 284, 9), Rules.ENEMY_MAX_HP)
	var player_panel = UI.panel(self, Rect2(925, 367, 330, 126))
	UI.label(player_panel, "첫 표행의 신참 표사", Rect2(18, 10, 295, 24), 13, UI.GOLD)
	UI.label(player_panel, "주인공", Rect2(18, 34, 295, 32), 24)
	player_text = UI.label(player_panel, "", Rect2(18, 71, 295, 22), 16)
	player_bar = _health_bar(player_panel, Rect2(18, 103, 294, 9), Rules.PLAYER_MAX_HP)
	turn_label = UI.label(self, "내 차례", Rect2(1065, 22, 190, 32), 16, UI.GOLD)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var description_panel = UI.panel(self, Rect2(24, 525, 610, 171))
	heading = UI.label(description_panel, "무공을 살펴보세요", Rect2(18, 12, 565, 30), 23, UI.GOLD)
	detail = UI.label(description_panel, "", Rect2(18, 53, 565, 62), 17)
	note = UI.label(description_panel, "", Rect2(18, 125, 390, 30), 12, UI.MUTED)
	use_button = UI.button(description_panel, "사용  ↵", Rect2(450, 119, 140, 38), true)
	use_button.pressed.connect(use_selected)
	var slots = UI.panel(self, Rect2(650, 525, 605, 171))
	UI.label(slots, "편성 무공", Rect2(18, 8, 550, 24), 14, UI.GOLD)
	select_button = UI.button(slots, "삼재검법", Rect2(18, 40, 277, 54))
	select_button.toggle_mode = true
	select_button.pressed.connect(select_samjae)
	for point in [Vector2(310, 40), Vector2(18, 103), Vector2(310, 103)]:
		var empty = UI.button(slots, "—", Rect2(point, Vector2(277, 54)))
		empty.disabled = true
	damage_label = UI.label(self, "", Rect2(930, 190, 200, 65), 48, Color("ffe3ac"))
	damage_label.add_theme_color_override("font_shadow_color", Color("151f18"))
	damage_label.add_theme_constant_override("shadow_offset_x", 3)
	damage_label.add_theme_constant_override("shadow_offset_y", 3)
	damage_label.hide()

func _health_bar(parent: Node, area: Rect2, maximum: int) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = area.position
	bar.size = area.size
	bar.max_value = maximum
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_style = UI.box(Color("0d1612"), Color("555f48"))
	var fill_style = UI.box(Color("bc5745"), Color("d58a63"))
	for style in [background_style, fill_style]:
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	parent.add_child(bar)
	return bar

func begin() -> void:
	generation += 1
	player_hp = Rules.PLAYER_MAX_HP
	enemy_hp = Rules.ENEMY_MAX_HP
	selected = false
	busy = false
	running = true
	turn = 1
	select_button.disabled = false
	select_button.button_pressed = false
	use_button.disabled = true
	damage_label.hide()
	heading.text = "무공을 살펴보세요"
	detail.text = "오른쪽 무공을 클릭하면 설명을 확인합니다."
	note.text = "선택만으로는 턴을 소모하지 않습니다."
	turn_label.text = "내 차례 · 첫 교전"
	_update_hp()
	show()
	select_button.grab_focus()

func cancel() -> void:
	generation += 1
	running = false
	busy = false
	if float_tween and float_tween.is_valid():
		float_tween.kill()
	hide()

func select_samjae() -> void:
	if busy or not running:
		return
	selected = true
	select_button.button_pressed = true
	heading.text = "삼재검법"
	detail.text = "근력 × 3 + 기민 × 2\n현재 방어 전 피해: 50"
	note.text = "구체적인 부가 효과는 추후 설정됩니다."
	use_button.disabled = false

func use_selected() -> void:
	if not running or not selected or busy:
		return
	busy = true
	select_button.disabled = true
	use_button.disabled = true
	var token = generation
	turn_label.text = "주인공의 공격"
	detail.text = "삼재검법을 펼칩니다."
	note.text = ""
	await get_tree().create_timer(Rules.DEMO_ATTACK_DELAY, false).timeout
	if token != generation:
		return
	var hit = Rules.damage(Rules.samjae_damage(), Rules.ENEMY_CONSTITUTION)
	enemy_hp = maxi(0, enemy_hp - hit)
	_update_hp()
	_float_damage(hit, false)
	detail.text = "삼재검법 명중.\n수적에게 %d의 피해를 주었습니다." % hit
	await get_tree().create_timer(Rules.DEMO_TURN_DELAY, false).timeout
	if token != generation:
		return
	if enemy_hp == 0:
		running = false
		busy = false
		damage_label.hide()
		victory.emit(player_hp)
		return
	turn_label.text = "상대 차례"
	heading.text = "수적의 반격"
	detail.text = "수적이 도를 휘두릅니다."
	await get_tree().create_timer(Rules.DEMO_ATTACK_DELAY, false).timeout
	if token != generation:
		return
	var counter = Rules.damage(Rules.DEMO_ENEMY_RAW_DAMAGE, Rules.STARTING_STATS.constitution)
	player_hp = maxi(0, player_hp - counter)
	_update_hp()
	_float_damage(counter, true)
	await get_tree().create_timer(Rules.DEMO_TURN_DELAY, false).timeout
	if token != generation:
		return
	turn += 1
	busy = false
	select_button.disabled = false
	use_button.disabled = false
	turn_label.text = "내 차례 · %d번째 교전" % turn
	select_samjae()
	use_button.grab_focus()

func _update_hp() -> void:
	enemy_text.text = "체력   %d / %d" % [enemy_hp, Rules.ENEMY_MAX_HP]
	player_text.text = "체력   %d / %d" % [player_hp, Rules.PLAYER_MAX_HP]
	enemy_bar.value = enemy_hp
	player_bar.value = player_hp

func _float_damage(value: int, on_player: bool) -> void:
	if float_tween and float_tween.is_valid():
		float_tween.kill()
	damage_label.position = Vector2(350, 320) if on_player else Vector2(990, 170)
	damage_label.text = "−%d" % value
	damage_label.modulate.a = 1.0
	damage_label.show()
	float_tween = create_tween().set_parallel()
	float_tween.tween_property(damage_label, "position:y", damage_label.position.y - 38, 0.65)
	float_tween.tween_property(damage_label, "modulate:a", 0.0, 0.65)
