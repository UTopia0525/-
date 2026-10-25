extends Control

const UI = preload("res://scripts/ui.gd")
var map_rect: Rect2
var heading: Label
var facility_widgets: Array=[]
var map_image: TextureRect
var player_dot: ColorRect
var district_labels: Array[Label] = []
var actor_markers: Array[Control] = []
var facility_filter:="all"
var show_residents:=true
var world
const MAP_RECT = Rect2(190, 65, 900, 600)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color("0b1414f5")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	heading=UI.label(self, "長沙 · 장사 전체 지도", Rect2(35, 18, 1000, 35), 25, UI.GOLD)
	map_image = TextureRect.new()
	map_image.position = MAP_RECT.position
	map_image.size = MAP_RECT.size
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/changsha/layout.json"))
	map_image.texture = load(data.ground_texture)
	map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	map_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_image)
	player_dot = ColorRect.new()
	player_dot.color = Color("ffe3a0")
	player_dot.size = Vector2(10, 10)
	player_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_dot)
	var first_facility=get_child_count()
	UI.label(self,"시설 안내",Rect2(20,100,160,30),22,UI.GOLD)
	for spec in [["약 · 영약 상인","city_merchant"],["장 · 무기 장인","city_artisan"],["무 · 무공 교관","city_instructor"]]:
		var button=UI.button(self,spec[0],Rect2(20,145+(["city_merchant","city_artisan","city_instructor"].find(spec[1]))*53,155,43))
		button.add_theme_font_size_override("font_size",15);button.pressed.connect(track_facility.bind(spec[1]))
	var filters=OptionButton.new();filters.position=Vector2(20,330);filters.size=Vector2(155,40)
	for title in ["시설 전체 표시","상인만 표시","장인만 표시","교관만 표시"]:filters.add_item(title)
	filters.item_selected.connect(func(index):facility_filter=["all","city_merchant","city_artisan","city_instructor"][index];apply_filter())
	add_child(filters)
	var residents=CheckButton.new();residents.position=Vector2(20,390);residents.text="주민 표시";residents.button_pressed=true;residents.toggled.connect(func(value):show_residents=value;apply_filter());add_child(residents)
	UI.label(self,"약 / 장 / 무
시설 아이콘도
클릭해 안내",Rect2(20,450,150,100),16,UI.MUTED)
	UI.label(self,"! 수락 가능
? 완료 보고
◆ 의뢰 목표",Rect2(20,562,155,92),16,UI.GOLD)
	for i in range(first_facility,get_child_count()):facility_widgets.append(get_child(i))
	UI.label(self, "● 현재 위치     ·     TAB / ESC  지도 닫기", Rect2(190, 674, 900, 30), 17, UI.GOLD)
	hide()

func open_for(exploration, goal: Dictionary = {}) -> void:
	world=exploration
	map_rect=MAP_RECT
	if exploration.area_name!="changsha":
		var ratio: Vector2=exploration.map_bounds.size
		var fit=minf(MAP_RECT.size.x/ratio.x,MAP_RECT.size.y/ratio.y)
		map_rect=Rect2(MAP_RECT.get_center()-ratio*fit/2,ratio*fit)
	heading.text=exploration.city_data.name+" · 전체 지도"
	for widget in facility_widgets:widget.visible=not exploration.city_data.get("services",[]).is_empty()
	map_image.texture=exploration.background.texture
	map_image.position=map_rect.position;map_image.size=map_rect.size
	for child in map_image.get_children():child.free()
	for tile in exploration.art_tiles:
		var section=TextureRect.new();section.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		var atlas=AtlasTexture.new();atlas.atlas=tile.texture;atlas.region=tile.source;section.texture=atlas
		section.position=tile.target.position/Vector2(exploration.city_data.art_size[0],exploration.city_data.art_size[1])*map_rect.size
		section.size=tile.target.size/Vector2(exploration.city_data.art_size[0],exploration.city_data.art_size[1])*map_rect.size
		section.mouse_filter=Control.MOUSE_FILTER_IGNORE;map_image.add_child(section)
	for marker in actor_markers:
		marker.free()
	actor_markers.clear()
	for label in district_labels:
		label.free()
	district_labels.clear()
	var art_size = Vector2(exploration.city_data.art_size[0], exploration.city_data.art_size[1])
	for district in exploration.city_data.districts:
		var point = Vector2(district.label[0], district.label[1]) / art_size * map_rect.size + map_rect.position
		if district.category in ["workshops","martial_hall"]:point.y+=28
		var label = UI.label(self, district.name, Rect2(point - Vector2(70, 12), Vector2(140, 26)), 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_outline_color", Color("0b1714"))
		label.add_theme_constant_override("outline_size", 7)
		district_labels.append(label)
	for exit in exploration.travel_exits:
		var marker=UI.label(self,"○ "+exit.name,Rect2(map_rect.position+exit.position/exploration.map_bounds.size*map_rect.size-Vector2(85,18),Vector2(170,35)),16,Color("9de5ff"))
		marker.add_theme_color_override("font_outline_color",Color("14231e"));marker.add_theme_constant_override("outline_size",5);actor_markers.append(marker)
	for citizen in exploration.ambient_nodes:
		var marker = ColorRect.new()
		marker.size = Vector2(6, 6)
		marker.position = map_rect.position + citizen.position / exploration.map_bounds.size * map_rect.size - marker.size / 2.0
		marker.color = Color("81f0cf")
		var service: String=citizen.get_meta("service_id","")
		marker.set_meta("service",service);marker.set_meta("resident",service.is_empty())
		if not service.is_empty():
			marker.size=Vector2(22,22);marker.position-=Vector2(8,8);marker.color=Color("23352d")
			var badge=Button.new()
			badge.text={"city_merchant":"약","city_artisan":"장","city_instructor":"무"}[service]
			badge.add_theme_font_override("font",UI.BODY_FONT)
			badge.add_theme_font_size_override("font_size",13)
			var badge_style=UI.box(Color("23352d"),UI.GOLD)
			badge_style.content_margin_left=2;badge_style.content_margin_right=2;badge_style.content_margin_top=0;badge_style.content_margin_bottom=0
			for style_name in ["normal","hover","pressed","hover_pressed","disabled","focus"]:badge.add_theme_stylebox_override(style_name,badge_style)
			badge.minimum_size_changed.connect(func():badge.set_deferred("size",Vector2(22,22)))
			marker.add_child(badge)
			badge.set_deferred("size",Vector2(22,22))
			badge.size=Vector2(22,22);badge.pressed.connect(track_facility.bind(service))
		var errands=exploration.get_parent().ordinary_quests
		var symbol: String=errands.marker_for(citizen.get_meta("npc_id"))
		if symbol.is_empty() and errands.is_target(citizen.get_meta("npc_id")):symbol="◆"
		if not symbol.is_empty():
			var quest_badge=UI.label(self,symbol,Rect2(marker.position+Vector2(-18,-43),Vector2(48,48)),32,Color("ffe14b"))
			quest_badge.add_theme_color_override("font_outline_color",Color("14231e"));quest_badge.add_theme_constant_override("outline_size",4)
			quest_badge.set_meta("quest",true);actor_markers.append(quest_badge)
		marker.tooltip_text = str(citizen.get_meta("display_name", "주민")) + " · " + str(citizen.get_meta("post", ""))
		add_child(marker)
		actor_markers.append(marker)
	if not goal.is_empty():
		var marker = Panel.new()
		marker.size = Vector2(56, 56)
		marker.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var outline=StyleBoxFlat.new();outline.bg_color=Color.TRANSPARENT;outline.border_color=Color("ff9863");outline.set_border_width_all(2)
		marker.add_theme_stylebox_override("panel",outline)
		marker.pivot_offset=marker.size/2
		marker.rotation=PI/4
		marker.position=map_rect.position+goal.position/exploration.map_bounds.size*map_rect.size-marker.size/2
		add_child(marker);actor_markers.append(marker)
	player_dot.position = map_rect.position + exploration.player.position / exploration.map_bounds.size * map_rect.size - Vector2(5, 5)
	move_child(player_dot, get_child_count() - 1)
	apply_filter()
	show()

func apply_filter() -> void:
	for marker in actor_markers:
		if marker.get_meta("resident",false):marker.visible=show_residents
		elif not str(marker.get_meta("service","")).is_empty():marker.visible=facility_filter=="all" or marker.get_meta("service")==facility_filter
func track_facility(id: String) -> void:
	if not is_instance_valid(world):return
	world.get_parent().quest_navigation.facility_id=id
	world.get_parent().quest_navigation.target_changed.emit()
	world.get_parent().adventure_ui.notify("시설 안내 · "+{"city_merchant":"영약 상인","city_artisan":"무기 장인","city_instructor":"무공 교관"}[id],"confirm")
	world.get_parent().toggle_city_map()
