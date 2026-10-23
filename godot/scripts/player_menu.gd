extends Control
## Safe exploration menus. Possessions/technique loadout use the same persistent data as shops.
const Icons = preload("res://scripts/catalog_icons.gd")
const UI = preload("res://scripts/ui.gd")
var game
var mode := "inventory"
var category := "weapon"
var selected_id := ""
var target_slot := 0
var heading: Label
var summary: Label
var detail: Label
var feedback: Label
var rows: VBoxContainer
var action: Button
var tabs: Array[Button] = []
var slots: Array[Button] = []
var basic_label: Label
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 var shade := ColorRect.new()
 shade.color = Color("09120fea")
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var panel = UI.panel(self, Rect2(85, 35, 1110, 650))
 panel.mouse_filter = Control.MOUSE_FILTER_STOP
 heading = UI.label(panel, "", Rect2(25, 16, 730, 35), 26, UI.GOLD)
 summary = UI.label(panel, "", Rect2(25, 65, 1060, 65), 16)
 var inventory = UI.button(panel, "소지품 · I", Rect2(750, 15, 155, 40))
 inventory.pressed.connect(switch_mode.bind("inventory"))
 var martial = UI.button(panel, "무공 · K", Rect2(920, 15, 155, 40))
 martial.pressed.connect(switch_mode.bind("martial"))
 for i in range(3):
  var button = UI.button(panel, ["무기", "영약", "의뢰 물품"][i], Rect2(25 + i * 142, 137, 132, 38))
  button.pressed.connect(select_category.bind(["weapon", "elixir", "quest"][i]))
  tabs.append(button)
 basic_label = UI.label(panel, "기본공격·기본방어도 바꿀 수 있습니다.\n실전에 펼칠 초식 네 가지를 갖추세요.", Rect2(25, 137, 430, 53), 17, UI.GOLD)
 var scroll := ScrollContainer.new()
 scroll.position = Vector2(25, 201)
 scroll.size = Vector2(430, 345)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(scroll)
 rows = VBoxContainer.new()
 rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 rows.add_theme_constant_override("separation", 8)
 scroll.add_child(rows)
 detail = UI.label(panel, "", Rect2(490, 142, 590, 246), 17)
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 for i in range(4):
  var slot = UI.button(panel, "", Rect2(490 + i * 146, 399, 138, 63))
  slot.add_theme_font_size_override("font_size", 16)
  slot.pressed.connect(select_slot.bind(i))
  slots.append(slot)
 action = UI.button(panel, "", Rect2(490, 482, 576, 46), true)
 action.pressed.connect(apply_selection)
 feedback = UI.label(panel, "", Rect2(25, 557, 1055, 40), 16, UI.GOLD)
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var close = UI.button(panel, "닫기 · ESC", Rect2(850, 600, 216, 35))
 close.pressed.connect(close_menu)
 UI.label(panel, "I 소지품 · K 무공 · 정비를 마치고 창을 닫으면 여정을 잇습니다.", Rect2(25, 607, 800, 25), 14, UI.MUTED)
 hide()
func open_menu(value: String) -> void:
 if visible:
  if value == mode: close_menu()
  else: switch_mode(value)
  return
 if game.state != "explore" or not game.dialogue_lines.is_empty() or game.city_overview.visible or game.city_service.visible or game.settings_menu.window.visible: return
 game.exploration.set_active(false)
 show()
 switch_mode(value)
func switch_mode(value: String) -> void:
 mode = value
 category = "weapon" if mode == "inventory" else "art"
 selected_id = ""
 feedback.text = ""
 refresh()
func close_menu() -> void:
 if not visible: return
 hide()
 if game.state == "explore" and game.dialogue_lines.is_empty() and not game.city_overview.visible and not game.city_service.visible:
  game.exploration.set_active(true)
func dismiss() -> void: hide()
func select_category(value: String) -> void:
 category = value
 selected_id = ""
 feedback.text = ""
 refresh()
func select_slot(index: int) -> void:
 target_slot = index
 update_detail()
func select_item(id: String) -> void:
 selected_id = id
 feedback.text = ""
 update_detail()
func refresh() -> void:
 var p = game.progress
 var s: Dictionary = p.stats
 var total := int(s.strength + s.agility + s.constitution + s.inner + s.insight)
 var realm: String = "절정까지 %d" % [100 - total] if total < 100 else p.RULES.realm(total)
 heading.text = "소지품 · I" if mode == "inventory" else "익힌 무공과 초식 편성 · K"
 summary.text = "소지금 %d문  |  근력%d · 기민%d · 근골%d · 내공%d · 오성%d\n합계%d / 500 · %s  |  장착: %s" % [game.money, s.strength, s.agility, s.constitution, s.inner, s.insight, total, realm, weapon_name()]
 for i in range(3):
  tabs[i].visible = mode == "inventory"
  tabs[i].disabled = category == ["weapon", "elixir", "quest"][i]
 basic_label.visible = mode == "martial"
 for child in rows.get_children():
  rows.remove_child(child)
  child.queue_free()
 var ids: Array = []
 match category:
  "weapon": ids = ["none"] + p.owned_weapons
  "elixir":
   for id in p.inventory:
    if p.inventory[id] > 0: ids.append(id)
  "quest": ids = game.trade_intro.quest_items()
  "art": ids = ["basic_attack", "basic_defense"] + p.learned.duplicate()
 for id in ids:
  var text: String = str(id)
  match category:
   "weapon": text = ("맨손" if id == "none" else str(p.weapons.get_weapon(id).name)) + (" · 장착 중" if id == game.battle.equipped_weapon_id else "")
   "elixir": text = "%s · %d개" % [p.elixirs[id].name, p.inventory[id]]
   "art":
    text = str(p.arts.get_skill(id).name)
    if id in p.loadout: text += " · 편성%d" % [p.loadout.find(id) + 1]
  var row = UI.button(rows, text, Rect2(0, 0, 410, 46))
  row.custom_minimum_size = Vector2(410, 52)
  Icons.apply(row, str(id))
  row.pressed.connect(select_item.bind(str(id)))
 if ids.is_empty(): UI.label(rows, "보유한 물품이 없습니다.", Rect2(0, 0, 410, 45), 17, UI.MUTED)
 if category == "art":
  var clear = UI.button(rows, "선택한 편성 칸 비우기", Rect2(0, 0, 410, 46))
  clear.custom_minimum_size = Vector2(410, 46)
  clear.pressed.connect(select_item.bind("clear"))
 update_detail()
func weapon_name() -> String:
 return str(game.progress.weapons.get_weapon(game.battle.equipped_weapon_id).get("name", "맨손"))
func update_detail() -> void:
 var p = game.progress
 for i in range(4):
  slots[i].visible = mode == "martial"
  slots[i].disabled = target_slot == i
  Icons.apply(slots[i], str(p.loadout[i]), 30)
  slots[i].text = "%d번 칸\n%s" % [i + 1, "비어 있음" if p.loadout[i] == "" else p.arts.get_skill(p.loadout[i]).name]
 action.disabled = selected_id.is_empty()
 action.text = "선택하세요"
 detail.text = "보유한 물건을 골라 장착하거나 복용하세요.\n물건 구매는 상점가·공방에서 할 수 있습니다." if mode == "inventory" else "이미 익힌 무공 가운데 실전에 펼칠 수를 고르세요.\n무공과 자리를 골라 편성할 수 있습니다.\n새 무공은 무관 교관에게 전수받을 수 있습니다."
 if selected_id.is_empty(): return
 match category:
  "weapon":
   var item: Dictionary = p.weapons.get_weapon(selected_id)
   detail.text = "무기를 해제해 맨손으로 전환합니다.\n권법·장법은 맨손일 때 사용할 수 있습니다." if selected_id == "none" else "%s\n\n%s\n\n해당 무기 무공의 공격+%d%% · 받는 피해-%d%%\n해당 창법 내기 소모-%d%%" % [item.name, item.description, item.attack_bonus_percent, item.damage_reduction_percent, item.qi_reduction_percent]
   action.text = "맨손으로 전환" if selected_id == "none" else "이 무기 장착"
   action.disabled = selected_id == game.battle.equipped_weapon_id
  "elixir":
   var item: Dictionary = p.elixirs[selected_id]
   var gains: Dictionary = item.permanent_stat_gains
   detail.text = "%s\n\n%s\n\n근력+%d · 기민+%d · 근골+%d · 내공+%d\n오성 상승 없음 · 보유%d · 누적 복용%d/10" % [item.name, item.description, gains.strength, gains.agility, gains.constitution, gains.inner, p.inventory[selected_id], p.consumed[selected_id]]
   action.text = "1개 복용"
   action.disabled = p.inventory[selected_id] <= 0
  "quest":
   detail.text = selected_id + "\n\n현재 연계 의뢰의 전달 물품입니다.\n미니맵에 표시된 상대에게 F로 말을 걸어 전달하세요."
   action.text = "대화로 전달"
   action.disabled = true
  "art":
   if selected_id == "clear": detail.text = "선택한 편성 칸만 비웁니다. 기본 행동을 포함해 네 칸 모두 바꿀 수 있습니다."
   else:
    var item: Dictionary = p.arts.get_skill(selected_id)
    var names := {"strength":"근력", "agility":"기민", "constitution":"근골", "inner":"내공", "insight":"오성"}
    var terms: Array = []
    if int(item.get("base_damage",0)) > 0: terms.append(str(int(item.base_damage)))
    for key in item.damage_coefficients: terms.append("%s×%d" % [names[key], int(item.damage_coefficients[key])])
    detail.text = "%s\n\n%s\n\n%s\n내기 소모%d · %s" % [item.name, item.description, " + ".join(terms), game.progress.weapons.qi_cost(item.qi_cost, game.battle.equipped_weapon_id, item), p.arts.weapon_requirement(selected_id)]
    if not p.arts.can_use_with_weapon(selected_id, game.battle.equipped_weapon_type): detail.text += "\n현재 장비로 사용 불가 · I에서 장비를 바꾸세요."
   if selected_id not in ["clear", "basic_attack", "basic_defense"] and p.arts.get_skill(selected_id).weapon_style == "sword": detail.text += "\n사용 후 다음 적 행동 피해20% 감소"
   action.text = "%d번 칸 비우기" % [target_slot + 1] if selected_id == "clear" else "%d번 칸에 편성" % [target_slot + 1]
func apply_selection() -> void:
 if action.disabled or not visible or game.state != "explore": return
 var ok := false
 var p = game.progress
 match category:
  "weapon":
   if selected_id == "none" or selected_id in p.owned_weapons: ok = game.battle.equip_weapon_item(selected_id)
  "elixir": ok = p.consume(selected_id)
  "art":
   ok = p.assign("" if selected_id == "clear" else selected_id, target_slot)
   game.battle.set_loadout(p.loadout)
 refresh()
 feedback.text = "적용했습니다." if ok else (p.error if category == "elixir" else "적용할 수 없습니다.")
