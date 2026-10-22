extends RefCounted

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
	node.add_theme_stylebox_override("hover", box(Color("e4c98f") if primary else Color("3a4c39"), GOLD))
	node.add_theme_stylebox_override("pressed", box(Color("aa925d") if primary else Color("4b5840"), GOLD))
	node.add_theme_stylebox_override("disabled", box(Color("25342b"), Color("4c5947")))
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), Color("f3dca3")))
	node.add_theme_color_override("font_color", Color("17241c") if primary else TEXT)
	node.add_theme_color_override("font_hover_color", Color("17241c") if primary else TEXT)
	node.add_theme_color_override("font_pressed_color", Color("17241c") if primary else TEXT)
	node.add_theme_color_override("font_disabled_color", Color("73816d"))
	parent.add_child(node)
	return node

static func character_texture(frame: int) -> AtlasTexture:
	var sheet: Texture2D = preload("res://assets/characters.png")
	var cell = Vector2(sheet.get_width() / 4.0, sheet.get_height() / 2.0)
	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(frame % 4, frame / 4) * cell, cell)
	return atlas
