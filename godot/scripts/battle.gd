extends Control

signal victory(remaining_hp: int)
signal defeat
signal sound_requested(id: String)
signal event_recorded(entry: Dictionary)
var records: Array[Dictionary]=[]

const Icons = preload("res://scripts/catalog_icons.gd")
var combat = preload("res://scripts/combat_actions.gd").new()
var enemy_qi = preload("res://scripts/inner_qi.gd").new()
var enemy_stats: Dictionary = {}
var enemy_weapon := "thickback_saber"
var enemy_skills: Array = ["bandit_chop", "soemok"]
var enemy_intent := "basic_attack"
var enemy_guard := 0
var ready_turns: Dictionary = {}
var enemy_ready_turns: Dictionary = {}
var intent_label: Label
var intent_icon: TextureRect
const Actor = preload("res://scripts/battle_actor.gd")
const DamageBar = preload("res://scripts/damage_health_bar.gd")
var player_actor: Node2D
var enemy_actor: Node2D
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
var encounter: Dictionary = {}
var enemy_max_hp: int = Rules.ENEMY_MAX_HP
var enemy_constitution: int = Rules.ENEMY_CONSTITUTION
var enemy_raw_damage: int = Rules.DEMO_ENEMY_RAW_DAMAGE
var enemy_name: Label
var enemy_faction: Label
var selected: bool = false
var selected_action: String = ""
var player_stats: Dictionary = Rules.STARTING_STATS.duplicate()
var loadout: Array = ["basic_attack", "basic_defense", "samjae", ""]
var skill_buttons: Array[Button] = []
var busy: bool = false
var running: bool = false
var generation: int = 0
var turn: int = 1
var scene_image: TextureRect
var enemy_text: Label
var player_text: Label
var enemy_bar
var player_bar
var heading: Label
var executed_icon: TextureRect
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
	scene_image.texture = preload("res://assets/battle/deck-empty.png")
	scene_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene_image.size = Vector2(1280, 510)
	add_child(scene_image)
	player_actor = Actor.new()
	player_actor.strike_started.connect(func():
		if running and busy: sound_requested.emit("attack_"+player_actor.weapon_type))
	add_child(player_actor)
	player_actor.configure(false, equipped_weapon_type, Vector2(350,490))
	enemy_actor = Actor.new()
	enemy_actor.strike_started.connect(func():
		if running and busy: sound_requested.emit("attack_"+enemy_actor.weapon_type))
	add_child(enemy_actor)
	enemy_actor.configure(true, "saber", Vector2(945,300))
	var enemy_panel = UI.panel(self, Rect2(24, 24, 390, 140))
	enemy_faction = UI.label(enemy_panel, "흑린채 · 일반 수적", Rect2(18, 10, 285, 24), 13, UI.GOLD)
	enemy_name = UI.label(enemy_panel, "흑린채 수적", Rect2(18, 34, 285, 32), 24)
	enemy_text = UI.label(enemy_panel, "", Rect2(18, 71, 355, 22), 16)
	enemy_bar = _health_bar(enemy_panel, Rect2(18, 103, 354, 20), Rules.ENEMY_MAX_HP)
	var intent_panel = UI.panel(self, Rect2(430, 24, 450, 82))
	intent_label = UI.label(intent_panel, "", Rect2(18, 12, 414, 58), 24, UI.GOLD)
	intent_icon = TextureRect.new()
	intent_icon.position = Vector2(12,14)
	intent_icon.size = Vector2(52,52)
	intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intent_panel.add_child(intent_icon)
	var player_panel = UI.panel(self, Rect2(925, 293, 330, 200))
	weapon_label = UI.label(player_panel, "장착 무기 · 무문철검", Rect2(18, 10, 295, 24), 13, UI.GOLD)
	UI.label(player_panel, "도원", Rect2(18, 34, 295, 32), 24)
	player_text = UI.label(player_panel, "", Rect2(18, 71, 295, 22), 16)
	player_bar = _health_bar(player_panel, Rect2(18, 103, 294, 20), Rules.PLAYER_MAX_HP)
	qi_text = UI.label(player_panel, "", Rect2(18, 136, 295, 22), 16, Color("a3dfe8"))
	qi_bar = _health_bar(player_panel, Rect2(18, 165, 294, 9), qi.MAXIMUM, false)
	var qi_fill = UI.box(Color("4eabbc"), Color("92d1dc"))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: qi_fill.set_content_margin(side, 0)
	qi_bar.add_theme_stylebox_override("fill", qi_fill)
	qi.changed.connect(_update_qi)
	_update_qi()
	turn_label = UI.label(self, "나의 차례", Rect2(1065, 22, 190, 32), 16, UI.GOLD)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var description_panel = UI.panel(self, Rect2(24, 525, 610, 171))
	heading = UI.label(description_panel, "펼칠 무공을 고르시오", Rect2(18, 12, 565, 30), 23, UI.GOLD)
	executed_icon=TextureRect.new();executed_icon.position=Vector2(18,10);executed_icon.size=Vector2(34,34)
	executed_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;description_panel.add_child(executed_icon);executed_icon.hide()
	detail = UI.label(description_panel, "", Rect2(18, 53, 565, 62), 17)
	note = UI.label(description_panel, "", Rect2(18, 125, 390, 30), 12, UI.MUTED)
	use_button = UI.button(description_panel, "사용  ↵", Rect2(450, 119, 140, 38), true)
	use_button.pressed.connect(use_selected)
	var slots = UI.panel(self, Rect2(650, 525, 605, 171))
	UI.label(slots, "초식 네 자리 · 탐험 중 K로 정비", Rect2(18, 8, 550, 24), 14, UI.GOLD)
	for index in range(4):
		var point := Vector2(18 + (index % 2) * 292, 40 + (index / 2) * 63)
		var button = UI.button(slots, "—", Rect2(point, Vector2(277, 54)))
		button.toggle_mode = true
		button.pressed.connect(select_slot.bind(index))
		skill_buttons.append(button)
	basic_button = skill_buttons[0]
	select_button = skill_buttons[2]
	_update_slots()
	damage_label = UI.label(self, "", Rect2(930, 190, 200, 65), 48, Color("ff4f55"))
	damage_label.add_theme_color_override("font_shadow_color", Color("151018"))
	damage_label.add_theme_color_override("font_outline_color", Color("1d1018"))
	damage_label.add_theme_constant_override("outline_size", 5)
	damage_label.add_theme_constant_override("shadow_offset_x", 3)
	damage_label.add_theme_constant_override("shadow_offset_y", 3)
	damage_label.hide()

func _health_bar(parent: Node, area: Rect2, maximum: int, damage_trail: bool = true) -> ProgressBar:
	var bar = DamageBar.new() if damage_trail else ProgressBar.new()
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

func set_encounter(value: Dictionary) -> void:
	encounter = value.duplicate(true)
	enemy_max_hp = int(encounter.get("max_hp", Rules.ENEMY_MAX_HP))
	enemy_constitution = int(encounter.get("constitution", Rules.ENEMY_CONSTITUTION))
	enemy_stats = encounter.get("stats", {"strength":12,"agility":12,"constitution":5,"inner":6,"insight":5}).duplicate()
	enemy_stats.constitution = enemy_constitution
	enemy_weapon = str(encounter.get("weapon", "thickback_saber"))
	enemy_skills = encounter.get("skills", ["bandit_chop", "soemok"]).duplicate()
	enemy_raw_damage = int(Rules.basic_attack_damage(enemy_stats))
	enemy_guard = 0
	enemy_qi.start(int(enemy_stats.inner))
	enemy_intent = combat.enemy_plan(enemy_stats,enemy_weapon,enemy_skills,enemy_qi.amount,1)
	_update_intent()
	enemy_name.text = str(encounter.get("name", "흑린채 수적"))
	enemy_faction.text = str(encounter.get("faction", "흑린채 · 일반 수적"))
	enemy_bar.max_value = enemy_max_hp
	scene_image.texture = load("res://assets/battle/road-empty.png" if not encounter.is_empty() else "res://assets/battle/deck-empty.png")
	enemy_actor.set_weapon(weapons.weapon_type(enemy_weapon))

func begin(inner_power: int = -1) -> void:
	ready_turns.clear();enemy_ready_turns.clear()
	records.clear()
	qi.start(int(player_stats.inner) if inner_power < 0 else inner_power)
	enemy_qi.start(int(enemy_stats.get("inner", 6)))
	enemy_guard = 0
	generation += 1
	_reset_presentation()
	player_hp = Rules.PLAYER_MAX_HP
	enemy_hp = enemy_max_hp
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
	use_button.text = "사용  ↵"
	damage_label.hide()
	heading.text = "펼칠 무공을 고르시오"
	detail.text = "오른쪽 무공을 클릭하면 설명을 확인합니다."
	note.text = "선택만으로는 턴을 소모하지 않습니다."
	turn_label.text = "나의 차례 · 첫 교전"
	_prepare_enemy()
	_update_hp()
	show()
	basic_button.grab_focus()

func cancel() -> void:
	ready_turns.clear();enemy_ready_turns.clear()
	generation += 1
	running = false
	busy = false
	_reset_presentation()
	player_actor.stop()
	enemy_actor.stop()
	hide()

func select_basic_attack() -> void:
	select_skill("basic_attack")

func basic_attack_damage() -> float:
	var stats: Dictionary = player_stats.duplicate()
	stats.inner = qi.inner_power
	return Rules.basic_attack_damage(stats)

func set_loadout(value: Array) -> void:
	loadout = value.duplicate()
	if loadout.size() == 3: loadout.push_front("basic_attack")
	if is_node_ready(): _update_slots()

func _has_usable_action() -> bool:
	for id in loadout:
		var a: Dictionary = combat.action(str(id), player_stats, equipped_weapon_id)
		if not a.is_empty() and cooldown_remaining(str(id))==0 and qi.can_spend(current_qi_cost(str(id))): return true
	return false

func cooldown_remaining(id: String) -> int:return combat.cooldown_remaining(id,turn,ready_turns)

func _update_slots() -> void:
	for i in range(skill_buttons.size()):
		var id: String = str(loadout[i])
		skill_buttons[i].text = "—" if id == "" else str(martial_arts.get_skill(id).name)
		if cooldown_remaining(id)>0:skill_buttons[i].text += " · 대기 %d턴" % cooldown_remaining(id)
		Icons.apply(skill_buttons[i], id)
		skill_buttons[i].disabled = busy or id == ""
	# Contextual free fallback prevents a soft lock after removing both basic actions.
	if running and not busy and not _has_usable_action():
		skill_buttons[0].text = "임시 기본공격 · 내기 부족/장비 불일치"
		Icons.apply(skill_buttons[0], "basic_attack")
		skill_buttons[0].disabled = false

func select_slot(index: int) -> void:
	if index == 0 and not _has_usable_action(): select_basic_attack()
	elif index >= 0 and index < loadout.size() and loadout[index] != "": select_skill(str(loadout[index]))

func refresh_selection() -> void:
	if selected_action != "": select_skill(selected_action)

func select_samjae() -> void:
	select_skill("samjae")

func select_skill(id: String) -> void:
	if busy or not running: return
	if id not in loadout and not (id == "basic_attack" and not _has_usable_action()): return
	var item: Dictionary = martial_arts.get_skill(id)
	if item.is_empty(): return
	selected = true
	selected_action = id
	for i in range(skill_buttons.size()): skill_buttons[i].button_pressed = loadout[i] == id
	heading.text = item.name
	_show_action_icon(id)
	var names := {"strength":"근력", "agility":"기민", "constitution":"근골", "inner":"내공", "insight":"오성"}
	var terms: Array = []
	if int(item.get("base_damage",0)) > 0: terms.append(str(int(item.base_damage)))
	for key in item.damage_coefficients: terms.append("%s × %d" % [names[key], int(item.damage_coefficients[key])])
	var a: Dictionary = combat.action(id, player_stats, equipped_weapon_id)
	detail.text = "다음 적 행동의 피해20% 감소 · 공격하지 않음" if id == "basic_defense" else " + ".join(terms) + "\n현재 방어 전 피해: " + str(a.get("raw",0))
	if item.weapon_style == "support":detail.text="내공의%d%%만큼 내기 회복 · 현재 %d\n다음 상대 행동 피해%d%% 감소 · 사용 후%d턴 재사용 불가" % [item.qi_restore_inner_percent,a.qi_restore,item.guard_percent,item.cooldown_turns]
	if item.weapon_style == "sword": detail.text += " · 다음 적 행동 피해20% 감소"
	note.text = "내기 소모: %d · %s" % [current_qi_cost(id), martial_arts.weapon_requirement(id)]
	use_button.disabled = not martial_arts.can_use_with_weapon(id, equipped_weapon_type) or cooldown_remaining(id)>0
	if cooldown_remaining(id)>0:note.text += " · 재사용까지 %d턴" % cooldown_remaining(id)

func _prepare_enemy() -> void:
	enemy_intent = combat.enemy_plan(enemy_stats,enemy_weapon,enemy_skills,enemy_qi.amount,turn,enemy_ready_turns)
	_update_intent()

func _update_intent() -> void:
	# Intent category only: no move name, cost, move-specific icon or tooltip leaks.
	intent_icon.texture = null
	intent_icon.hide()
	intent_label.tooltip_text = ""
	var action: Dictionary = combat.action(enemy_intent,enemy_stats,enemy_weapon)
	intent_label.text = "적이 공격을 하려고 한다" if action.get("raw",0)>0 else "상대가 수세를 취하고 있다"

func use_selected() -> void:
	if not running and player_hp == 0 and encounter.is_empty():
		begin()
		return
	if not running or not selected or busy:
		return
	var is_basic := selected_action in ["basic_attack", "basic_defense"]
	if not is_basic and not martial_arts.can_use_with_weapon(selected_action, equipped_weapon_type):
		note.text = martial_arts.weapon_requirement(selected_action)
		return
	if cooldown_remaining(selected_action)>0:
		note.text="재사용까지 %d턴 남았습니다." % cooldown_remaining(selected_action)
		return
	var cost: int = current_qi_cost(selected_action)
	if not try_spend_qi(cost):
		note.text = "내기가 부족합니다. 필요 %d / 현재 %d" % [cost, qi.amount] if cost >= 0 else "기술의 내기 비용을 확인해 주세요."
		return
	var player_action: Dictionary = combat.action(selected_action,player_stats,equipped_weapon_id)
	var opponent_action: Dictionary = combat.action(enemy_intent,enemy_stats,enemy_weapon)
	var action_name: String = str(player_action.name)
	var raw: float = float(player_action.raw)
	var restored: int=combat.commit_support(player_action,qi,ready_turns,turn)
	if int(player_action.get("qi_restore",0))>0:log_action("도원",action_name+" · 내기 회복",0,-restored,int(player_action.guard),qi.amount,"recovery")
	busy = true
	basic_button.disabled = true
	for button in skill_buttons: button.disabled = true
	use_button.disabled = true
	var token = generation
	turn_label.text = "나의 수비" if selected_action == "basic_defense" else "나의 출수"
	detail.text = action_name + "을 펼칩니다."
	note.text = ""
	if raw > 0:
		player_actor.attack()
	else:
		player_actor.defend(1.8)
		sound_requested.emit("block")
	if enemy_intent == "basic_defense": enemy_actor.defend()
	await get_tree().create_timer(Rules.DEMO_ATTACK_DELAY, false).timeout
	if token != generation:
		return
	var active_enemy_guard: int = int(opponent_action.guard) if float(opponent_action.raw)==0 else enemy_guard
	var hit: int = combat.damage(raw, enemy_constitution, enemy_weapon, active_enemy_guard)
	enemy_guard = 0
	log_action("도원",action_name,hit,cost,active_enemy_guard,qi.amount)
	enemy_hp = maxi(0, enemy_hp - hit)
	_update_hp(true)
	if raw > 0: sound_requested.emit("hit" if hit > 0 else "block")
	if hit > 0: enemy_actor.hurt()
	_float_damage(hit, false)
	detail.text = ("내기 %d 회복 · 방어 태세를 취했습니다." % restored if int(player_action.get("qi_restore",0))>0 else "방어 태세를 취했습니다.") if raw == 0 else "%s 명중.\n%s에게 %d의 피해를 주었습니다." % [action_name, enemy_name.text, hit]
	await get_tree().create_timer(Rules.DEMO_TURN_DELAY, false).timeout
	if token != generation:
		return
	if enemy_hp == 0:
		running = false
		busy = false
		damage_label.hide()
		victory.emit(player_hp)
		return
	# Pay the locked enemy action only when the living actor actually takes its turn.
	enemy_qi.spend(int(opponent_action.cost))
	var enemy_restored: int=combat.commit_support(opponent_action,enemy_qi,enemy_ready_turns,turn)
	if int(opponent_action.get("qi_restore",0))>0:log_action(enemy_name.text,opponent_action.name+" · 내기 회복",0,-enemy_restored,int(opponent_action.guard),enemy_qi.amount,"recovery")
	# A sword guard begins after the attack, protecting against the next player action.
	if opponent_action.raw > 0: enemy_guard = int(opponent_action.guard)
	turn_label.text = "상대의 차례"
	heading.text = enemy_name.text + "의 반격"
	# Reveal the icon only after this living opponent commits its action.
	_show_action_icon(enemy_intent)
	detail.text = "%s: %s" % [enemy_name.text, opponent_action.name]
	if opponent_action.raw > 0:
		enemy_actor.attack()
	else:
		enemy_actor.defend()
		sound_requested.emit("block")
	await get_tree().create_timer(Rules.DEMO_ATTACK_DELAY, false).timeout
	if token != generation:
		return
	var counter: int = combat.damage(float(opponent_action.raw), player_stats.constitution, equipped_weapon_id, int(player_action.guard))
	log_action(enemy_name.text,opponent_action.name,counter,int(opponent_action.cost),int(player_action.guard),enemy_qi.amount)
	player_hp = maxi(0, player_hp - counter)
	_update_hp(true)
	if opponent_action.raw > 0: sound_requested.emit("hit" if counter > 0 else "block")
	if counter > 0: player_actor.hurt()
	_float_damage(counter, true)
	await get_tree().create_timer(Rules.DEMO_TURN_DELAY, false).timeout
	if token != generation:
		return
	if player_hp == 0:
		running = false
		busy = false
		damage_label.hide()
		defeat.emit()
		if encounter.is_empty():
			heading.text = "교전에서 밀려났습니다"
			detail.text = "다시 도전하면 체력과 내기를 회복해 시작합니다."
			use_button.text = "다시 도전"
			use_button.disabled = false
		return
	turn += 1
	var old_qi: int=qi.amount
	var old_enemy_qi: int=enemy_qi.amount
	qi.recover_turn()
	enemy_qi.recover_turn()
	log_action("도원","내기 회복",0,old_qi-qi.amount,0,qi.amount,"recovery")
	log_action(enemy_name.text,"내기 회복",0,old_enemy_qi-enemy_qi.amount,0,enemy_qi.amount,"recovery")
	_prepare_enemy()
	busy = false
	basic_button.disabled = false
	_update_slots()
	use_button.disabled = false
	turn_label.text = "나의 차례 · %d번째 교전" % turn
	_update_hp()
	if selected_action not in loadout and _has_usable_action():
		selected = false
		selected_action = ""
		use_button.disabled = true
	else: refresh_selection()
	use_button.grab_focus()

func _update_hp(animate: bool = false) -> void:
	enemy_text.text = "체력 %d/%d · 내기 %d/500 (+%d)" % [enemy_hp, enemy_max_hp, enemy_qi.amount, enemy_qi.inner_power]
	player_text.text = "체력   %d / %d" % [player_hp, Rules.PLAYER_MAX_HP]
	enemy_bar.set_health(enemy_hp, enemy_max_hp, animate)
	player_bar.set_health(player_hp, Rules.PLAYER_MAX_HP, animate)

func _float_damage(value: int, on_player: bool) -> void:
	if float_tween and float_tween.is_valid():
		float_tween.kill()
	if value <= 0:
		damage_label.hide()
		return
	damage_label.position = (player_actor.home + Vector2(-35,-235)) if on_player else (enemy_actor.home + Vector2(-20,-190))
	damage_label.text = "−%d" % value
	damage_label.modulate.a = 1.0
	damage_label.show()
	float_tween = create_tween().set_parallel()
	float_tween.tween_property(damage_label, "position:y", damage_label.position.y - 38, 0.65)
	float_tween.tween_property(damage_label, "modulate:a", 0.0, 0.65)

func _reset_presentation() -> void:
	if is_instance_valid(executed_icon):executed_icon.hide();heading.position.x=18
	if float_tween and float_tween.is_valid(): float_tween.kill()
	if is_instance_valid(damage_label): damage_label.hide()
	player_actor.reset_motion()
	enemy_actor.reset_motion()
	enemy_bar.snap()
	player_bar.snap()

func _show_action_icon(id: String) -> void:
	executed_icon.texture=Icons.texture(id);executed_icon.visible=executed_icon.texture!=null
	heading.position.x=62 if executed_icon.visible else 18
	heading.size.x=520 if executed_icon.visible else 565

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
	if is_instance_valid(player_actor): player_actor.set_weapon(equipped_weapon_type)
	if is_instance_valid(weapon_label): weapon_label.text = "장착 무기 · " + str(weapons.get_weapon(id).get("name", "맨손"))
	if running and selected: refresh_selection()
	return true

func current_qi_cost(skill_id: String) -> int:
	if skill_id in ["basic_attack", "basic_defense"]: return 0
	var base: int = int(skill_qi_costs.get(skill_id, martial_arts.qi_cost(skill_id)))
	return weapons.qi_cost(base, equipped_weapon_id, martial_arts.get_skill(skill_id))

func log_action(actor: String,technique: String,damage: int,cost: int,guard: int,amount: int,kind: String="action") -> void:
	var entry={"turn":turn,"actor":actor,"technique":technique,"damage":damage,"cost":cost,"guard":guard,"qi":amount,"kind":kind}
	records.append(entry)
	if records.size()>400:records.pop_front()
	event_recorded.emit(entry)
