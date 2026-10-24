extends Panel
## Local, north-up terrain map. Marker coordinates come from live world positions.
const UI = preload("res://scripts/ui.gd")
const VIEW_SIZE = Vector2(240, 150)
const WORLD_WIDTH = 1920.0
var exploration
var quest_navigation
var facility_legend: Label
var quest_label: Label
var quest_active := false
var quest_offscreen := false
var quest_marker := Vector2.ZERO
var quest_direction := Vector2.ZERO
const QUEST_COLOR = Color("ff9863")
var place_label: Label
var map_view: Control
var world_window: Rect2
var facility_markers: Array[Dictionary]=[]
var npc_markers: PackedVector2Array = []
var player_marker: Vector2
var facing := "down"

class MapView extends Control:
	var owner_map
	func _draw() -> void:
		owner_map.draw_map(self)

func _ready() -> void:
	position = Vector2(24, 24)
	size = Vector2(264, 290)
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	UI.label(self, "◆ 목표", Rect2(164, 198, 80, 22), 13, QUEST_COLOR)
	var north = UI.label(map_view, "N ↑", Rect2(106, 2, 28, 20), 12, UI.TEXT)
	north.add_theme_color_override("font_outline_color", Color.BLACK)
	north.add_theme_constant_override("outline_size", 4)
	facility_legend=UI.label(self,"약 상인 · 장 장인 · 무 교관",Rect2(12,225,240,22),13,UI.GOLD)
	quest_label = UI.label(self, "추적 중인 퀘스트 없음", Rect2(12, 254, 240, 22), 13, UI.MUTED)
	quest_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func bind_world(world) -> void:
	exploration = world
	refresh()

func refresh() -> void:
	if not is_instance_valid(exploration):
		return
	facility_legend.text="약 상인 · 장 장인 · 무 교관" if not exploration.city_data.get("services",[]).is_empty() else "○ 푸른 포탈 · 가까이에서 F 이동"
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
	facility_markers.clear()
	for citizen in exploration.ambient_nodes:
		if world_window.has_point(citizen.position):
			npc_markers.append(project_point(citizen.position))
			var id: String=citizen.get_meta("service_id", "")
			if not id.is_empty():facility_markers.append({"id":id,"position":project_point(citizen.position)})
	for npc in exploration.npcs:
		if npc.frame >= 0 and world_window.has_point(npc.position):
			npc_markers.append(project_point(npc.position))
	_refresh_quest()
	map_view.queue_redraw()

func _refresh_quest() -> void:
	var goal: Dictionary = quest_navigation.get_goal(exploration) if is_instance_valid(quest_navigation) else {}
	quest_active = not goal.is_empty()
	quest_offscreen = false
	quest_marker = Vector2.ZERO
	quest_direction = Vector2.ZERO
	if not quest_active:
		quest_label.text = "산길 북쪽 무창 · 서쪽 장사" if exploration.area_name=="mountain_road" else "추적 중인 퀘스트 없음"
		quest_label.tooltip_text = ""
		return
	quest_label.text = "목표 · " + goal.label
	quest_label.tooltip_text = goal.quest_title + " · " + goal.label
	var projected = project_point(goal.position)
	quest_offscreen = not world_window.has_point(goal.position)
	var lower = Vector2(12, 12)
	var upper = VIEW_SIZE - lower
	quest_direction = (projected - player_marker).normalized()
	if not quest_offscreen:
		quest_marker = projected.clamp(lower, upper)
		return
	var start = player_marker.clamp(lower, upper)
	var distance := INF
	if quest_direction.x > 0.0001:
		distance = minf(distance, (upper.x - start.x) / quest_direction.x)
	elif quest_direction.x < -0.0001:
		distance = minf(distance, (lower.x - start.x) / quest_direction.x)
	if quest_direction.y > 0.0001:
		distance = minf(distance, (upper.y - start.y) / quest_direction.y)
	elif quest_direction.y < -0.0001:
		distance = minf(distance, (lower.y - start.y) / quest_direction.y)
	quest_marker = start + quest_direction * distance

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
	var art_size=Vector2(exploration.city_data.get("art_size",[texture.get_width(),texture.get_height()])[0],exploration.city_data.get("art_size",[texture.get_width(),texture.get_height()])[1])
	var art_source=Rect2((world_window.position-bounds.position)/bounds.size*art_size,world_window.size/bounds.size*art_size)
	for tile in exploration.art_tiles:
		var intersection: Rect2 = art_source.intersection(tile.target)
		if not intersection.has_area():
			continue
		var destination = Rect2((intersection.position - art_source.position) / art_source.size * VIEW_SIZE, intersection.size / art_source.size * VIEW_SIZE)
		var sample = Rect2(tile.source.position + (intersection.position - tile.target.position) / tile.target.size * tile.source.size, intersection.size / tile.target.size * tile.source.size)
		canvas.draw_texture_rect_region(tile.texture, destination, sample, Color(0.75, 0.83, 0.77))
	for exit in exploration.travel_exits:
		if not world_window.has_point(exit.position):continue
		var point=project_point(exit.position)
		canvas.draw_circle(point,6,Color("102e42"));canvas.draw_arc(point,4,0,TAU,20,Color("50bfff"),2);canvas.draw_circle(point,1.5,Color("c1f6ff"))
	for point in npc_markers:
		canvas.draw_circle(point, 4.0, Color("10251e"))
		canvas.draw_circle(point, 2.8, Color("81f0cf"))
	for facility in facility_markers:
		var color: Color={"city_merchant":Color("92dca1"),"city_artisan":Color("e7b777"),"city_instructor":Color("9fc5fc")}[facility.id]
		canvas.draw_circle(facility.position,8,Color("16261e"));canvas.draw_arc(facility.position,8,0,TAU,20,color,1.5)
		canvas.draw_string(UI.BODY_FONT,facility.position+Vector2(-5,5),{"city_merchant":"약","city_artisan":"장","city_instructor":"무"}[facility.id],HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
	if quest_active:
		if quest_offscreen:
			var tangent = Vector2(-quest_direction.y, quest_direction.x)
			canvas.draw_circle(quest_marker, 9, Color("14251e"))
			canvas.draw_colored_polygon(PackedVector2Array([quest_marker + quest_direction * 7, quest_marker - quest_direction * 5 + tangent * 5, quest_marker - quest_direction * 5 - tangent * 5]), QUEST_COLOR)
		else:
			var diamond = PackedVector2Array([quest_marker + Vector2(-7, 0), quest_marker + Vector2(0, -7), quest_marker + Vector2(7, 0), quest_marker + Vector2(0, 7), quest_marker + Vector2(-7, 0)])
			canvas.draw_polyline(diamond, Color("14251e"), 5)
			canvas.draw_polyline(diamond, QUEST_COLOR, 2)
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
