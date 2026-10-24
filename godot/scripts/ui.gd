extends RefCounted

const BODY_FONT = preload("res://assets/fonts/ink_body.tres")
const BRUSH_FONT = preload("res://assets/fonts/ink_brush.tres")

const EXPLORATION_HINT="WASD/방향키·클릭 이동 · F 대화/거래/조사 · Q 의뢰 · I 소지품 · K 무공 · TAB 지도 · F2 도움말 · ESC 설정"

const GOLD = Color("d9b879")
const TEXT = Color("eee8d8")
const MUTED = Color("b2bca8")

static func box(fill: Color = Color("14231ef5"), border: Color = Color("967e51")) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func panel(parent: Node, area: Rect2, fill: Color = Color("14231ef5")) -> Panel:
	var node = Panel.new()
	node.position = area.position
	node.size = area.size
	node.add_theme_stylebox_override("panel", box(fill))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func label(parent: Node, text: String, area: Rect2, font_size: int = 20, color: Color = TEXT) -> Label:
	var node = Label.new()
	node.text = text
	node.position = area.position
	node.size = area.size
	node.add_theme_font_size_override("font_size", font_size)
	if font_size >= 22: node.add_theme_font_override("font", BRUSH_FONT)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, area: Rect2, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.position = area.position
	node.size = area.size
	node.add_theme_font_size_override("font_size", 18)
	node.add_theme_stylebox_override("normal", box(Color("d2b273") if primary else Color("26372df5")))
	var hover := box(Color("f2d79a") if primary else Color("4b6049"), Color("ffe0a0"))
	hover.set_border_width_all(2)
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("hover_pressed", hover)
	node.add_theme_stylebox_override("pressed", box(Color("aa925d") if primary else Color("4b5840"), GOLD))
	node.add_theme_stylebox_override("disabled", box(Color("25342b"), Color("4c5947")))
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), Color("f3dca3")))
	node.add_theme_color_override("font_color", Color("17241c") if primary else TEXT)
	node.add_theme_color_override("font_hover_color", Color("17241c") if primary else TEXT)
	node.add_theme_color_override("font_pressed_color", Color("17241c") if primary else TEXT)
	node.add_theme_color_override("font_disabled_color", Color("73816d"))
	node.add_theme_color_override("icon_normal_color", Color(.84,.84,.84))
	node.add_theme_color_override("icon_hover_color", Color.WHITE)
	node.add_theme_color_override("icon_hover_pressed_color", Color.WHITE)
	parent.add_child(node)
	return node

static func item_highlight(button: Button, active: bool = true) -> void:
	button.set_meta("highlight_active",active)
	if not button.has_meta("item_highlight"):
		var rim := Panel.new()
		rim.name = "ItemHoverHighlight"
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := box(Color.TRANSPARENT,Color("ffe2a0"))
		style.set_border_width_all(2)
		style.shadow_color = Color(1,.77,.32,.23)
		style.shadow_size = 4
		rim.add_theme_stylebox_override("panel",style)
		button.add_child(rim)
		rim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rim.hide()
		button.set_meta("item_highlight",rim)
		button.mouse_entered.connect(func():
			rim.visible = bool(button.get_meta("highlight_active",false)) and button.is_visible_in_tree())
		button.mouse_exited.connect(func(): rim.hide())
		button.visibility_changed.connect(func():
			if not button.is_visible_in_tree(): rim.hide())
	var frame: Panel = button.get_meta("item_highlight")
	frame.visible = active and button.is_visible_in_tree() and button.get_global_rect().has_point(button.get_global_mouse_position())

static func character_texture(frame: int) -> AtlasTexture:
	var sheet: Texture2D = preload("res://assets/characters.png")
	var cell = Vector2(sheet.get_width() / 4.0, sheet.get_height() / 2.0)
	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(frame % 4, frame / 4) * cell, cell)
	return atlas
