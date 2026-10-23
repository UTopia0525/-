extends Panel
## Local, north-up terrain map. Marker coordinates come from live world positions.
const UI = preload("res://scripts/ui.gd")
const VIEW_SIZE = Vector2(240, 150)
const WORLD_WIDTH = 1920.0
var exploration
var place_label: Label
var map_view: Control
var world_window: Rect2
var npc_markers: PackedVector2Array = []
var player_marker: Vector2
var facing := "down"

class MapView extends Control:
	var owner_map
	func _draw() -> void:
		owner_map.draw_map(self)

func _ready() -> void:
	position = Vector2(24, 24)
	size = Vector2(264, 230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UI.box(Color("12221bf5")))
	place_label = UI.label(self, "", Rect2(12, 9, 240, 26), 16, UI.TEXT)
	place_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	map_view = MapView.new()
	map_view.owner_map = self
	map_view.position = Vector2(12, 42)
	map_view.size = VIEW_SIZE
	map_view.clip_contents = true
	map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(map_view)
	UI.label(self, "▲ 나", Rect2(12, 198, 55, 22), 13, UI.GOLD)
	UI.label(self, "● 주민", Rect2(73, 198, 70, 22), 13, Color("81f0cf"))
	UI.label(self, "북쪽 ↑", Rect2(179, 198, 70, 22), 13, UI.TEXT)

func bind_world(world) -> void:
	exploration = world
	refresh()

func refresh() -> void:
	if not is_instance_valid(exploration):
		return
	var bounds: Rect2 = exploration.map_bounds
	var ratio = VIEW_SIZE.x / VIEW_SIZE.y
	var width = minf(WORLD_WIDTH, minf(bounds.size.x, bounds.size.y * ratio))
	var span = Vector2(width, width / ratio)
	var center: Vector2 = exploration.player.position
	var start = center - span / 2.0
	start.x = clampf(start.x, bounds.position.x, bounds.end.x - span.x)
	start.y = clampf(start.y, bounds.position.y, bounds.end.y - span.y)
	world_window = Rect2(start, span)
	player_marker = project_point(center)
	facing = exploration.player.facing
	npc_markers.clear()
	for citizen in exploration.ambient_nodes:
		if world_window.has_point(citizen.position):
			npc_markers.append(project_point(citizen.position))
	for npc in exploration.npcs:
		if npc.frame >= 0 and world_window.has_point(npc.position):
			npc_markers.append(project_point(npc.position))
	map_view.queue_redraw()

func project_point(point: Vector2) -> Vector2:
	return (point - world_window.position) / world_window.size * VIEW_SIZE

func draw_map(canvas: Control) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("12251f"))
	if not is_instance_valid(exploration) or world_window.size.x <= 0:
		return
	var texture: Texture2D = exploration.background.texture
	var bounds: Rect2 = exploration.map_bounds
	var source = Rect2((world_window.position - bounds.position) / bounds.size * texture.get_size(), world_window.size / bounds.size * texture.get_size())
	canvas.draw_texture_rect_region(texture, Rect2(Vector2.ZERO, VIEW_SIZE), source, Color(0.75, 0.83, 0.77))
	for tile in exploration.art_tiles:
		var intersection: Rect2 = source.intersection(tile.target)
		if not intersection.has_area():
			continue
		var destination = Rect2((intersection.position - source.position) / source.size * VIEW_SIZE, intersection.size / source.size * VIEW_SIZE)
		var sample = Rect2(tile.source.position + (intersection.position - tile.target.position) / tile.target.size * tile.source.size, intersection.size / tile.target.size * tile.source.size)
		canvas.draw_texture_rect_region(tile.texture, destination, sample, Color(0.75, 0.83, 0.77))
	for point in npc_markers:
		canvas.draw_circle(point, 4.0, Color("10251e"))
		canvas.draw_circle(point, 2.8, Color("81f0cf"))
	canvas.draw_circle(player_marker, 7, Color("10251e"))
	var angle: float = {"down": 0.0, "left": PI / 2, "right": -PI / 2, "up": PI}.get(facing, 0.0)
	var triangle = PackedVector2Array()
	for point in [Vector2(-5, -4), Vector2(5, -4), Vector2(0, 6)]:
		triangle.append(player_marker + point.rotated(angle))
	canvas.draw_colored_polygon(triangle, Color("ffdb79"))
	canvas.draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), UI.GOLD, false, 1)

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		refresh()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventMouseButton and get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
