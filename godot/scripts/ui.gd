extends RefCounted

const BODY_FONT = preload("res://assets/fonts/ink_body.tres")
const BRUSH_FONT = preload("res://assets/fonts/ink_brush.tres")

const EXPLORATION_HINT="WASD/방향키 이동 · F 대화/거래/조사 · Q 의뢰 · I 소지품 · K 무공 · R 호의도 · TAB 지도 · F2 도움말 · ESC 설정"

const GOLD = Color("d9b879")
const TEXT = Color("eee8d8")
const MUTED = Color("b2bca8")

static func box(fill: Color = Color("101e20ee"), border: Color = Color("c8ad75")) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func panel(parent: Node, area: Rect2, fill: Color = Color("101e20ee")) -> Panel:
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
	if text in ["!","?"] or text.begins_with("◆") or (text.is_empty() and font_size==68):node.set_meta("quest_marker",true)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, area: Rect2, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.clip_text=true
	node.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	node.position = area.position
	node.size = area.size
	node.add_theme_font_size_override("font_size", 18)
	node.add_theme_stylebox_override("normal", box(Color("d2b273") if primary else Color("203b36f2")))
	var hover := box(Color("f2d79a") if primary else Color("35564d"), Color("8cbdb0"))
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
	node.set_meta("primary",primary)
	selection(node, false)
	return node

static func item_highlight(button: Button, active: bool = true) -> void:
	button.set_meta("highlight_active",active)
	if not button.has_meta("item_highlight"):
		var rim := Panel.new()
		rim.name = "ItemHoverHighlight"
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := box(Color.TRANSPARENT,Color("8cbdb0"))
		style.set_border_width_all(2)
		style.shadow_color = Color(.40,.74,.65,.13)
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
	var hovered=button.get_viewport().gui_get_hovered_control()
	frame.visible = active and button.is_visible_in_tree() and is_instance_valid(hovered) and (hovered==button or button.is_ancestor_of(hovered))

static func character_texture(frame: int) -> AtlasTexture:
	var sheet: Texture2D = preload("res://assets/characters.png")
	var cell = Vector2(sheet.get_width() / 4.0, sheet.get_height() / 2.0)
	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(frame % 4, frame / 4) * cell, cell)
	return atlas

# Selection is independent of focus, ownership and availability. Never disable
# a selectable row just because the action it describes cannot currently run.
static func selection(button: Button, chosen: bool, paper: bool = false, tab: bool = false) -> void:
	button.set_meta("selected", chosen)
	button.set_meta("paper", paper)
	if not button.has_meta("selection_base"):
		var base = {}
		for state in ["normal", "hover", "pressed"]:base[state] = button.get_theme_stylebox(state).duplicate()
		button.set_meta("selection_base", base)
	var base: Dictionary = button.get_meta("selection_base")
	for state in ["normal", "hover", "pressed"]:
		var style: StyleBoxFlat = base[state].duplicate()
		if chosen:
			style.bg_color = Color("d7dfd3") if paper else Color("244e47")
			if state in ["hover", "pressed"]:style.bg_color = style.bg_color.lightened(.06)
			style.border_color = Color("40766b") if paper else Color("81bbab")
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(state,style)
	button.add_theme_stylebox_override("hover_pressed",button.get_theme_stylebox("pressed").duplicate())
	var focus = box(Color.TRANSPARENT, Color("aa772f") if paper else Color("f3d69a"))
	focus.set_border_width_all(2);button.add_theme_stylebox_override("focus",focus)
	var mark: ColorRect
	if button.has_node("SelectionMark"):mark=button.get_node("SelectionMark")
	else:
		mark=ColorRect.new();mark.name="SelectionMark";mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(mark)
	mark.color=Color("38695e") if paper else Color("a2d5bd")
	if tab:
		mark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);mark.offset_left=8;mark.offset_right=-8;mark.offset_top=-3;mark.offset_bottom=0
	else:
		mark.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE);mark.offset_left=0;mark.offset_right=3;mark.offset_top=8;mark.offset_bottom=-8
	mark.visible=chosen
	var primary: bool=button.get_meta("primary",false)
	var foreground=Color("f5eedb") if paper and primary else Color("293c38") if paper or primary else TEXT
	button.add_theme_color_override("font_focus_color",foreground)
	button.add_theme_color_override("font_pressed_color",foreground)
	if paper:button.add_theme_color_override("font_hover_color",foreground)

static func unavailable(button: Button, reason: String) -> void:
	button.disabled=not reason.is_empty()
	button.tooltip_text=reason
	button.set_meta("unavailable_reason",reason)

static func applied(node: CanvasItem) -> void:
	node.self_modulate=Color(1.18,1.14,.92)
	node.create_tween().tween_property(node,"self_modulate",Color.WHITE,.35)
