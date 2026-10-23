extends Control

signal victory(remaining_hp: int)

const UI = preload("res://scripts/ui.gd")
const Rules = preload("res://scripts/rules.gd")
var qi = preload("res://scripts/inner_qi.gd").new()
var weapon_label: Label
var qi_text: Label
var qi_bar: ProgressBar
var martial_arts = preload("res://scripts/martial_arts.gd").new()
# Overrides are available for balancing tests; the catalogue supplies the default costs.
var skill_qi_costs: Dictionary = {}
# Starter sword is unmodified; item identity determines equipment category.
var weapons = preload("res://scripts/weapons.gd").new()
var equipped_weapon_id := "plain_iron_sword"
var equipped_weapon_type := "sword"
var player_hp: int = Rules.PLAYER_MAX_HP
var enemy_hp: int = Rules.ENEMY_MAX_HP
var selected: bool = false
var selected_action: String = ""
var player_stats: Dictionary = Rules.STARTING_STATS.duplicate()
var loadout: Array = ["samjae", "", ""]
var skill_buttons: Array[Button] = []
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
var basic_button: Button
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
	var player_panel = UI.panel(self, Rect2(925, 293, 330, 200))
	weapon_label = UI.label(player_panel, "장착 무기 · 무문철검", Rect2(18, 10, 295, 24), 13, UI.GOLD)
	UI.label(player_panel, "주인공", Rect2(18, 34, 295, 32), 24)
	player_text = UI.label(player_panel, "", Rect2(18, 71, 295, 22), 16)
	player_bar = _health_bar(player_panel, Rect2(18, 103, 294, 9), Rules.PLAYER_MAX_HP)
	qi_text = UI.label(player_panel, "", Rect2(18, 136, 295, 22), 16, Color("a3dfe8"))
	qi_bar = _health_bar(player_panel, Rect2(18, 165, 294, 9), qi.MAXIMUM)
	var qi_fill = UI.box(Color("4eabbc"), Color("92d1dc"))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: qi_fill.set_content_margin(side, 0)
	qi_bar.add_theme_stylebox_override("fill", qi_fill)
	qi.changed.connect(_update_qi)
	_update_qi()
	turn_label = UI.label(self, "내 차례", Rect2(1065, 22, 190, 32), 16, UI.GOLD)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var description_panel = UI.panel(self, Rect2(24, 525, 610, 171))
	heading = UI.label(description_panel, "무공을 살펴보세요", Rect2(18, 12, 565, 30), 23, UI.GOLD)
	detail = UI.label(description_panel, "", Rect2(18, 53, 565, 62), 17)
	note = UI.label(description_panel, "", Rect2(18, 125, 390, 30), 12, UI.MUTED)
	use_button = UI.button(description_panel, "사용  ↵", Rect2(450, 119, 140, 38), true)
	use_button.pressed.connect(use_selected)
	var slots = UI.panel(self, Rect2(650, 525, 605, 171))
	UI.label(slots, "기본공격 1칸 · 편성 무공 3칸", Rect2(18, 8, 550, 24), 14, UI.GOLD)
	basic_button = UI.button(slots, "기본공격 · 고정", Rect2(18, 40, 277, 54))
	basic_button.toggle_mode = true
	basic_button.pressed.connect(select_basic_attack)
	for index in range(3):
		var point: Vector2 = [Vector2(310, 40), Vector2(18, 103), Vector2(310, 103)][index]
		var button = UI.button(slots, "—", Rect2(point, Vector2(277, 54)))
		button.toggle_mode = true
		button.pressed.connect(select_slot.bind(index))
		skill_buttons.append(button)
	select_button = skill_buttons[0]
	_update_slots()
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

func begin(inner_power: int = -1) -> void:
	qi.start(int(player_stats.inner) if inner_power < 0 else inner_power)
	generation += 1
	player_hp = Rules.PLAYER_MAX_HP
	enemy_hp = Rules.ENEMY_MAX_HP
	selected = false
	selected_action = ""
	basic_button.disabled = false
	basic_button.button_pressed = false
	busy = false
	running = true
	turn = 1
	_update_slots()
	for button in skill_buttons: button.button_pressed = false
	use_button.disabled = true
	damage_label.hide()
	heading.text = "무공을 살펴보세요"
	detail.text = "오른쪽 무공을 클릭하면 설명을 확인합니다."
	note.text = "선택만으로는 턴을 소모하지 않습니다."
	turn_label.text = "내 차례 · 첫 교전"
	_update_hp()
	show()
	basic_button.grab_focus()

func cancel() -> void:
	generation += 1
	running = false
	busy = false
	if float_tween and float_tween.is_valid():
		float_tween.kill()
	hide()

func select_basic_attack() -> void:
	if busy or not running:
		return
	selected = true
	selected_action = "basic_attack"
	basic_button.button_pressed = true
	for button in skill_buttons: button.button_pressed = false
	heading.text = "기본공격"
	detail.text = "근력 × 1 + 기민 × 1 + 내공 × 1\n현재 방어 전 피해: %s" % str(basic_attack_damage())
	note.text = "내기 소모: 0 · 무기 제한 없음 · 다음 턴 내공만큼 회복"
	use_button.disabled = false

func basic_attack_damage() -> float:
	var stats: Dictionary = player_stats.duplicate()
	stats.inner = qi.inner_power
	return Rules.basic_attack_damage(stats)

func set_loadout(value: Array) -> void:
	loadout = value.duplicate()
	if is_node_ready(): _update_slots()

func _update_slots() -> void:
	for i in range(skill_buttons.size()):
		var id: String = str(loadout[i])
		skill_buttons[i].text = "—" if id == "" else str(martial_arts.get_skill(id).name)
		skill_buttons[i].disabled = busy or id == ""

func select_slot(index: int) -> void:
	if index >= 0 and index < loadout.size() and loadout[index] != "": select_skill(str(loadout[index]))

func refresh_selection() -> void:
	if selected_action == "basic_attack": select_basic_attack()
	elif selected_action != "": select_skill(selected_action)

func select_samjae() -> void:
	select_skill("samjae")

func select_skill(id: String) -> void:
	if busy or not running or id not in loadout or not martial_arts.definitions.has(id): return
	selected = true
	selected_action = id
	basic_button.button_pressed = false
	for i in range(skill_buttons.size()): skill_buttons[i].button_pressed = loadout[i] == id
	var item: Dictionary = martial_arts.get_skill(id)
	heading.text = item.name
	var names := {"strength":"근력", "agility":"기민", "constitution":"근골", "inner":"내공", "insight":"오성"}
	var terms: Array = []
	for key in item.damage_coefficients: terms.append("%s × %d" % [names[key], int(item.damage_coefficients[key])])
	detail.text = " + ".join(terms) + "\n현재 방어 전 피해: " + str(weapons.attack_damage(martial_arts.raw_damage(id, player_stats), equipped_weapon_id, item))
	note.text = "내기 소모: %d · %s" % [current_qi_cost(id), martial_arts.weapon_requirement(id)]
	use_button.disabled = not martial_arts.can_use_with_weapon(id, equipped_weapon_type)

func use_selected() -> void:
	if not running or not selected or busy:
		return
	var is_basic := selected_action == "basic_attack"
	if not is_basic and not martial_arts.can_use_with_weapon(selected_action, equipped_weapon_type):
		note.text = martial_arts.weapon_requirement(selected_action)
		return
	var cost: int = current_qi_cost(selected_action)
	if not try_spend_qi(cost):
		note.text = "내기가 부족합니다. 필요 %d / 현재 %d" % [cost, qi.amount] if cost >= 0 else "기술의 내기 비용을 확인해 주세요."
		return
	var action_name: String = "기본공격" if is_basic else str(martial_arts.get_skill(selected_action).name)
	var raw: float = basic_attack_damage() if is_basic else weapons.attack_damage(martial_arts.raw_damage(selected_action, player_stats), equipped_weapon_id, martial_arts.get_skill(selected_action))
	busy = true
	basic_button.disabled = true
	for button in skill_buttons: button.disabled = true
	use_button.disabled = true
	var token = generation
	turn_label.text = "주인공의 공격"
	detail.text = action_name + "을 펼칩니다."
	note.text = ""
	await get_tree().create_timer(Rules.DEMO_ATTACK_DELAY, false).timeout
	if token != generation:
		return
	var hit = Rules.damage(raw, Rules.ENEMY_CONSTITUTION)
	enemy_hp = maxi(0, enemy_hp - hit)
	_update_hp()
	_float_damage(hit, false)
	detail.text = "%s 명중.\n수적에게 %d의 피해를 주었습니다." % [action_name, hit]
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
	var counter = weapons.received_damage(Rules.DEMO_ENEMY_RAW_DAMAGE, player_stats.constitution, equipped_weapon_id)
	player_hp = maxi(0, player_hp - counter)
	_update_hp()
	_float_damage(counter, true)
	await get_tree().create_timer(Rules.DEMO_TURN_DELAY, false).timeout
	if token != generation:
		return
	turn += 1
	qi.recover_turn()
	busy = false
	basic_button.disabled = false
	_update_slots()
	use_button.disabled = false
	turn_label.text = "내 차례 · %d번째 교전" % turn
	refresh_selection()
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

func try_spend_qi(cost: int) -> bool:
	# Called once when an attack/defence action is committed, never on preview.
	if not running or busy: return false
	return qi.spend(cost)

func _update_qi() -> void:
	qi_text.text = "내기   %d / %d    (+%d/턴)" % [qi.amount, qi.MAXIMUM, qi.inner_power]
	qi_bar.value = qi.amount

func equip_weapon(type: String) -> bool:
	if not weapons.DEFAULT_BY_TYPE.has(type): return false
	return equip_weapon_item(weapons.DEFAULT_BY_TYPE[type])

func equip_weapon_item(id: String) -> bool:
	if busy or not weapons.exists(id): return false
	equipped_weapon_id = id
	equipped_weapon_type = weapons.weapon_type(id)
	if is_instance_valid(weapon_label): weapon_label.text = "장착 무기 · " + str(weapons.get_weapon(id).get("name", "맨손"))
	if running and selected: refresh_selection()
	return true

func current_qi_cost(skill_id: String) -> int:
	if skill_id == "basic_attack": return 0
	var base: int = int(skill_qi_costs.get(skill_id, martial_arts.qi_cost(skill_id)))
	return weapons.qi_cost(base, equipped_weapon_id, martial_arts.get_skill(skill_id))
