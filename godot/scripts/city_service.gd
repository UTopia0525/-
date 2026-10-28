extends Control
const STAT_MAX = preload("res://scripts/rules.gd").STAT_MAX
signal closed
const Icons = preload("res://scripts/catalog_icons.gd")
const UI = preload("res://scripts/ui.gd")
var game
var heading: Label
var balance_preview: Label
var message: RichTextLabel
var summary: Label
var feedback: Label
var portrait: TextureRect
var tabs: Array[Button] = []
var rows: VBoxContainer
var action: Button
var slots: Array[Button] = []
var service: Dictionary = {}
var selected_tab := 0
var selected_id := ""
var target_slot := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color("0b1414e0")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel = UI.panel(self, Rect2(65, 35, 1150, 650))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	heading = UI.label(panel, "", Rect2(26, 14, 1090, 36), 25, UI.GOLD)
	summary = UI.label(panel, "", Rect2(26, 56, 1090, 30), 16)
	portrait = TextureRect.new()
	portrait.position = Vector2(20, 108)
	portrait.size = Vector2(280, 350)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(portrait)
	for i in range(2):
		var tab = UI.button(panel, "", Rect2(315 + i * 205, 98, 195, 40))
		tab.pressed.connect(select_tab.bind(i))
		tabs.append(tab)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(315, 152)
	scroll.size = Vector2(390, 365)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 7)
	scroll.add_child(rows)
	balance_preview=UI.label(panel,"",Rect2(735,112,385,30),16,UI.GOLD)
	message = RichTextLabel.new()
	message.position=Vector2(735,155);message.size=Vector2(385,290);message.bbcode_enabled=false
	message.add_theme_font_override("normal_font",UI.BODY_FONT);message.add_theme_font_size_override("normal_font_size",16)
	message.add_theme_color_override("default_color",UI.TEXT);panel.add_child(message)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in range(4):
		var slot = UI.button(panel, str(i + 1) + "번 칸", Rect2(735 + (i % 2) * 190, 407 + (i / 2) * 42, 180, 37))
		slot.pressed.connect(select_target_slot.bind(i))
		slots.append(slot)
	action = UI.button(panel, "", Rect2(735, 500, 380, 44), true)
	action.pressed.connect(transact)
	feedback = UI.label(panel, "", Rect2(26, 548, 1090, 34), 16, UI.GOLD)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close = UI.button(panel, "돌아가기 · ESC", Rect2(880, 592, 235, 40))
	close.pressed.connect(close_counter)
	hide()

func open_counter(definition: Dictionary) -> void:
	service = definition.duplicate(true)
	heading.text = service.title + " · " + service.name
	game.dialogue_cast.apply_framing(portrait, game.PORTRAITS.ACTORS[service.get("actor_id",service.id)])
	var names: Array = {"market": ["영약 구매", "보유 영약 · 복용"], "workshop": ["무기 구매", "장비 장착"], "training": ["무공 전수", "전투 무공 편성"]}[service.kind]
	for i in range(tabs.size()): tabs[i].text = names[i]
	feedback.text = ""
	select_tab(0)
	show()
	if game.quest_navigation.facility_id==service.id:game.quest_navigation.facility_id=""
	game.adventure_ui.tip("trade","품목 비교 → 구매 → I 장착·복용 / K 편성")
	tabs[0].grab_focus()

func select_tab(index: int) -> void:
	if index not in [0, 1]: return
	selected_tab = index
	selected_id = ""
	for i in range(tabs.size()):
		tabs[i].disabled=false;UI.selection(tabs[i],i==index,false,true)
	refresh_list()
	update_detail()

func refresh_list() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var p = game.progress
	var s: Dictionary = p.stats
	summary.text = "소지금 %d문  |  근력%d · 기민%d · 근골%d · 내공%d · 오성%d  |  %s" % [game.money, s.strength, s.agility, s.constitution, s.inner, s.insight, p.RULES.realm(int(s.strength + s.agility + s.constitution + s.inner + s.insight))]
	var ids: Array = []
	match service.kind:
		"market": ids = p.elixirs.keys().filter(func(id):return p.elixirs[id].get("acquisition")=="city_merchant")
		"workshop": ids = p.weapons.definitions.keys() if selected_tab == 0 else ["none"] + p.owned_weapons
		"training": ids = p.arts.definitions.keys() if selected_tab == 0 else ["basic_attack", "basic_defense"] + p.learned.duplicate()
	if selected_tab==0 and service.kind=="workshop":ids=weapon_stock()
	for id in ids:
		var text := ""
		match service.kind:
			"market": text = "%s · %s" % [p.elixirs[id].name, "100문" if selected_tab == 0 else "보유%d / 복용%d·10" % [p.inventory[id], p.consumed[id]]]
			"workshop":
				if selected_tab == 0 and p.weapons.get_weapon(id).get("price") == null: continue
				text = "무기 해제 · 맨손" if id == "none" else str(p.weapons.get_weapon(id).name)
				if selected_tab == 0: text += " · %d문" % p.weapons.get_weapon(id).price
				if id == game.battle.equipped_weapon_id: text += " · 장착 중"
			"training":
				if selected_tab == 0 and p.arts.get_skill(id).get("price") == null: continue
				text = str(p.arts.get_skill(id).name)
				if selected_tab==1 and id in p.loadout:text+=" · 편성 %d" % [p.loadout.find(id)+1]
				if selected_tab == 0: text += " · " + ("습득 완료" if id in p.learned else "350문")
		var button = UI.button(rows, text, Rect2(0, 0, 365, 43))
		button.custom_minimum_size = Vector2(365, 50)
		Icons.apply(button, str(id))
		button.add_theme_font_size_override("font_size", 16)
		button.set_meta("item_id",str(id));UI.selection(button,str(id)==selected_id)
		button.pressed.connect(select_item.bind(str(id)))
	if service.kind == "training" and selected_tab == 1:
		var clear = UI.button(rows, "선택한 칸 비우기", Rect2(0, 0, 365, 43))
		clear.custom_minimum_size = Vector2(365, 43)
		clear.set_meta("item_id","clear");UI.selection(clear,selected_id=="clear");clear.pressed.connect(select_item.bind("clear"))

func weapon_stock() -> Array:
	var stock: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/city_weapon_stock.json"))
	return stock.get(game.exploration.area_name,game.progress.weapons.definitions.keys())

func select_target_slot(index: int) -> void:
	target_slot = index
	update_detail()

func select_item(id: String) -> void:
	selected_id = id
	feedback.text = ""
	update_detail()

func update_detail() -> void:
	for row in rows.get_children():
		if row is Button:UI.selection(row,str(row.get_meta("item_id",""))==selected_id)
	var p = game.progress
	var is_loadout: bool = service.kind == "training" and selected_tab == 1
	message.size.y = 240 if is_loadout else 330
	for i in range(4):
		slots[i].visible = is_loadout
		slots[i].disabled = false
		UI.selection(slots[i],target_slot==i)
		Icons.apply(slots[i], str(p.loadout[i]), 24)
		slots[i].text = "%d: %s" % [i + 1, "비움" if p.loadout[i] == "" else p.arts.get_skill(p.loadout[i]).name]
		slots[i].add_theme_font_size_override("font_size", 12)
	action.disabled = selected_id.is_empty()
	balance_preview.text=""
	message.text = "품목을 선택하면 설명과 조건을 확인합니다."
	action.text = "선택하세요"
	if selected_id.is_empty(): return
	var problem := ""
	match service.kind:
		"market":
			var item: Dictionary = p.elixirs[selected_id]
			var g: Dictionary = item.permanent_stat_gains
			message.text = "%s\n\n%s\n\n근력+%d · 기민+%d · 근골+%d · 내공+%d\n오성 상승 없음\n보유%d개 · 누적 복용%d/10개" % [item.name, item.description, g.strength, g.agility, g.constitution, g.inner, p.inventory[selected_id], p.consumed[selected_id]]
			action.text = "100문 · 1개 구매" if selected_tab == 0 else "1개 복용"
			if selected_tab == 0: problem = p.issue("elixir", selected_id, game.money)
			elif int(p.consumed[selected_id])>=int(item.max_lifetime_uses):problem="평생 복용 한도 도달 · 10/10"
			elif p.inventory[selected_id] <= 0: problem = "보유한 영약이 없습니다."
			else:
				var can_gain=false
				for key in g:
					if key!="insight" and int(g[key])>0 and int(p.stats[key])<STAT_MAX:can_gain=true
				if not can_gain:problem="상승할 능력치가 없습니다."
		"workshop":
			var item: Dictionary = p.weapons.get_weapon(selected_id)
			message.text = "맨손으로 전환합니다. 권법·장법을 사용할 수 있습니다." if selected_id == "none" else "%s\n\n%s\n\n공격+%d%% · 받는 피해-%d%%\n해당 창법 내기-%d%%" % [item.name, item.description, item.attack_bonus_percent, item.damage_reduction_percent, item.qi_reduction_percent]
			action.text = "%d문 · 구매" % item.get("price", 0) if selected_tab == 0 else "장착" if selected_id != "none" else "무기 해제"
			if selected_tab == 0: problem = p.issue("weapon", selected_id, game.money)
			if selected_tab==0 and selected_id not in weapon_stock():problem="이 도시에서는 판매하지 않는 병장기입니다."
			if selected_tab==1 and selected_id==game.battle.equipped_weapon_id:problem="현재 장착 중입니다."
		"training":
			if selected_id == "clear": message.text = "선택한 편성 칸을 비웁니다. 기본 행동도 교체할 수 있습니다."
			else:
				var item: Dictionary = p.arts.get_skill(selected_id)
				var req: Array = []
				var names := {"strength":"근력", "agility":"기민", "constitution":"근골", "inner":"내공", "insight":"오성"}
				var terms: Array = []
				if int(item.get("base_damage",0)) > 0: terms.append(str(int(item.base_damage)))
				for key in item.damage_coefficients: terms.append("%s×%d" % [names[key], int(item.damage_coefficients[key])])
				for key in item.requirements.stats: req.append("%s%d" % [names[key], item.requirements.stats[key]])
				message.text = "%s\n\n%s\n\n위력: %s\n내기 소모%d · %s\n학습: %s\n다섯 스탯 합계%d 이상" % [item.name, item.description, " + ".join(terms), item.qi_cost, p.arts.weapon_requirement(selected_id), " · ".join(req), item.requirements.minimum_total]
			if selected_id not in ["clear", "basic_attack", "basic_defense"] and p.arts.get_skill(selected_id).weapon_style == "sword": message.text += "\n사용 후 다음 적 행동 피해20% 감소"
			action.text = "350문 · 전수받기" if selected_tab == 0 else "%d번 칸에 편성" % [target_slot + 1]
			if selected_tab == 0: problem = p.issue("art", selected_id, game.money)
	if service.kind=="workshop":message.add_text("\n\n"+preload("res://scripts/item_comparison.gd").weapon(p,selected_id,game.battle.equipped_weapon_id))
	if service.kind=="training" and selected_id not in ["clear","basic_attack","basic_defense"]:preload("res://scripts/item_comparison.gd").append_art(message,p,selected_id,game.battle.equipped_weapon_id)
	if selected_tab==0:
		var kind: String={"market":"elixir","workshop":"weapon","training":"art"}[service.kind]
		var left: int=game.money-p.price_for(kind,selected_id)
		balance_preview.text="구매 후 소지금 %d문" % left if left>=0 else "%d문 필요 · %d문 부족" % [p.price_for(kind,selected_id),-left]
	UI.unavailable(action,problem)
	if not problem.is_empty():
		message.push_color(Color("f8a494"));message.add_text("\n\n"+problem);message.pop()
		action.disabled = true

func transact() -> void:
	if service.is_empty() or selected_id.is_empty() or game.state != "service": return
	var p = game.progress
	var ok := false
	if selected_tab == 0:
		var kind: String = {"market":"elixir", "workshop":"weapon", "training":"art"}[service.kind]
		if kind=="weapon" and selected_id not in weapon_stock():
			feedback.text="이 도시에서는 판매하지 않는 병장기입니다."
			return
		ok = p.purchase(kind, selected_id, game)
		feedback.text = {"market":"약은 보유 영약 탭에서 복용하시면 됩니다.", "workshop":"잘 골랐네요. 장비 장착 탭에서 손에 쥐어보세요.", "training":"배운 수를 잊지 마시오. 편성 탭에서 쓸 무공을 고르시오."}[service.kind] if ok else p.error
	else:
		match service.kind:
			"market":
				ok = p.consume(selected_id)
				feedback.text = "영약을 복용했습니다. 능력치가 영구 상승했습니다." if ok else p.error
			"workshop":
				if selected_id == "none" or selected_id in p.owned_weapons: ok = game.battle.equip_weapon_item(selected_id)
				feedback.text = ("맨손으로 전환했습니다." if selected_id=="none" else str(p.weapons.get_weapon(selected_id).name)+"을 장착했습니다.") if ok else "장착할 수 없습니다."
			"training":
				ok = p.assign("" if selected_id == "clear" else selected_id, target_slot)
				feedback.text = "편성했습니다. 네 칸 모두 교체할 수 있습니다." if ok else "편성할 수 없습니다."
	if ok and selected_tab==1 and service.kind=="workshop":game.adventure_ui.notify("장비를 바꾸었습니다.","confirm")
	refresh_list()
	update_detail()
	if ok:UI.applied(feedback)

func close_counter() -> void:
	hide()
	service.clear()
	closed.emit()

func dismiss() -> void:
	hide()
	service.clear()
