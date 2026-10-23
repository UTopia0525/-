extends Control

const UI = preload("res://scripts/ui.gd")
var map_image: TextureRect
var player_dot: ColorRect
var district_labels: Array[Label] = []
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
	player_dot = ColorRect.new()
	player_dot.color = Color("ffe3a0")
	player_dot.size = Vector2(10, 10)
	player_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_dot)
	UI.label(self, "● 현재 위치     ·     TAB / ESC  지도 닫기", Rect2(190, 674, 900, 30), 17, UI.GOLD)
	hide()

func open_for(exploration) -> void:
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
	player_dot.position = MAP_RECT.position + exploration.player.position / exploration.map_bounds.size * MAP_RECT.size - Vector2(5, 5)
	move_child(player_dot, get_child_count() - 1)
	show()
