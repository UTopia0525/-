extends Control

const UI = preload("res://scripts/ui.gd")
var map_image: TextureRect
var player_dot: ColorRect
var district_labels: Array[Label] = []
var actor_markers: Array[Control] = []
const MAP_RECT = Rect2(190, 65, 900, 600)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color("0b1414f5")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	UI.label(self, "長沙 · 장사 전체 지도", Rect2(35, 18, 1000, 35), 25, UI.GOLD)
	map_image = TextureRect.new()
	map_image.position = MAP_RECT.position
	map_image.size = MAP_RECT.size
	map_image.texture = load("res://assets/maps/changsha/city.png")
	map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	map_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_image)
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/changsha/layout.json"))
	for tile in data.detail_tiles:
		var atlas = AtlasTexture.new()
		atlas.atlas = load(tile.path)
		atlas.region = Rect2(tile.source[0], tile.source[1], tile.source[2], tile.source[3])
		var section = TextureRect.new()
		section.texture = atlas
		section.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		section.position = Vector2(tile.target[0], tile.target[1]) / Vector2(data.art_size[0], data.art_size[1]) * MAP_RECT.size
		section.size = Vector2(tile.target[2], tile.target[3]) / Vector2(data.art_size[0], data.art_size[1]) * MAP_RECT.size
		section.mouse_filter = Control.MOUSE_FILTER_IGNORE
		section.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		map_image.add_child(section)
	player_dot = ColorRect.new()
	player_dot.color = Color("ffe3a0")
	player_dot.size = Vector2(10, 10)
	player_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_dot)
	UI.label(self, "● 현재 위치     ·     TAB / ESC  지도 닫기", Rect2(190, 674, 900, 30), 17, UI.GOLD)
	hide()

func open_for(exploration, goal: Dictionary = {}) -> void:
	for marker in actor_markers:
		marker.free()
	actor_markers.clear()
	for label in district_labels:
		label.free()
	district_labels.clear()
	var art_size = Vector2(exploration.city_data.art_size[0], exploration.city_data.art_size[1])
	for district in exploration.city_data.districts:
		var point = Vector2(district.label[0], district.label[1]) / art_size * MAP_RECT.size + MAP_RECT.position
		var label = UI.label(self, district.name, Rect2(point - Vector2(70, 12), Vector2(140, 26)), 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_outline_color", Color("0b1714"))
		label.add_theme_constant_override("outline_size", 7)
		district_labels.append(label)
	for citizen in exploration.ambient_nodes:
		var marker = ColorRect.new()
		marker.size = Vector2(6, 6)
		marker.position = MAP_RECT.position + citizen.position / exploration.map_bounds.size * MAP_RECT.size - marker.size / 2.0
		marker.color = Color("81f0cf")
		marker.tooltip_text = str(citizen.get_meta("display_name", "주민")) + " · " + str(citizen.get_meta("post", ""))
		add_child(marker)
		actor_markers.append(marker)
	if not goal.is_empty():
		var marker = ColorRect.new()
		marker.size = Vector2(9, 9)
		marker.pivot_offset = marker.size / 2.0
		marker.rotation = PI / 4
		marker.position = MAP_RECT.position + goal.position / exploration.map_bounds.size * MAP_RECT.size - marker.size / 2.0
		marker.color = Color("ff9863")
		marker.tooltip_text = goal.label
		add_child(marker)
		actor_markers.append(marker)
	player_dot.position = MAP_RECT.position + exploration.player.position / exploration.map_bounds.size * MAP_RECT.size - Vector2(5, 5)
	move_child(player_dot, get_child_count() - 1)
	show()
