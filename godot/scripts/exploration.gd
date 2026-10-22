extends Node2D

const UI = preload("res://scripts/ui.gd")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
var area_name: String = "dock"
var player
var background: Sprite2D
var npcs: Array[Dictionary] = []
var decorations: Node2D
var collision_root: Node2D
var walk_regions: Array[Rect2] = []
var blockers: Array[Rect2] = []
var astar = AStarGrid2D.new()
var active: bool = false
var hint: Label

func _ready() -> void:
	background = Sprite2D.new()
	background.centered = false
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)
	decorations = Node2D.new()
	decorations.y_sort_enabled = true
	add_child(decorations)
	player = PLAYER_SCENE.instantiate()
	decorations.add_child(player)
	collision_root = Node2D.new()
	add_child(collision_root)
	hint = UI.label(self, "E  대화", Rect2(0, 0, 150, 30), 15, UI.GOLD)
	hint.add_theme_color_override("font_shadow_color", Color("102019"))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_area("dock")

func load_area(value: String) -> void:
	area_name = value
	player.stop()
	for entry in npcs:
		entry.node.free()
	npcs.clear()
	for child in collision_root.get_children():
		child.free()
	if value == "dock":
		background.texture = preload("res://assets/dock.png")
		walk_regions = [Rect2(85, 300, 650, 325), Rect2(705, 380, 210, 62)]
		blockers = [Rect2(85, 490, 90, 80), Rect2(600, 570, 65, 60)]
		player.position = Vector2(370, 510)
		_add_npc("captain", "서문길", Vector2(640, 380), 4)
		_add_npc("apothecary", "진소옥", Vector2(290, 315), 5)
		_add_npc("sailor", "허만복", Vector2(610, 535), 6)
		_add_npc("clerk", "육승", Vector2(445, 365), 7)
		_add_npc("boarding", "호송선에 오르기", Vector2(810, 415), -1)
	else:
		background.texture = preload("res://assets/deck.png")
		walk_regions = [Rect2(500, 215, 280, 365)]
		blockers = [Rect2(615, 215, 45, 113)]
		player.position = Vector2(585, 535)
		_add_npc("deck-captain", "서문길", Vector2(715, 350), 4)
		_add_npc("deck-sailor", "허만복", Vector2(540, 320), 6)
	background.scale = Vector2(1280.0 / background.texture.get_width(), 720.0 / background.texture.get_height())
	_build_collision_and_navigation()

func _add_npc(id: String, title: String, point: Vector2, frame: int) -> void:
	var body = Area2D.new()
	body.position = point
	body.collision_layer = 0
	body.collision_mask = 1
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 78
	collision.shape = circle
	body.add_child(collision)
	if frame >= 0:
		var sprite = Sprite2D.new()
		sprite.texture = UI.character_texture(frame)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * (104.0 / sprite.texture.get_height())
		sprite.position.y = -43
		body.add_child(sprite)
	var tag = UI.label(body, title, Rect2(-100, -108 if frame >= 0 else -25, 200, 28), 14, UI.TEXT)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_shadow_color", Color("142019"))
	tag.add_theme_constant_override("shadow_offset_x", 2)
	tag.add_theme_constant_override("shadow_offset_y", 2)
	decorations.add_child(body)
	npcs.append({"id": id, "name": title, "position": point, "node": body, "frame": frame})

func point_is_walkable(point: Vector2) -> bool:
	var inside = false
	for region in walk_regions:
		if region.has_point(point):
			inside = true
	for block in blockers:
		if block.has_point(point):
			return false
	return inside

func _build_collision_and_navigation() -> void:
	astar.region = Rect2i(0, 0, 64, 36)
	astar.cell_size = Vector2(20, 20)
	astar.offset = Vector2(10, 10)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in range(36):
		for x in range(64):
			var point = Vector2(x * 20 + 10, y * 20 + 10)
			astar.set_point_solid(Vector2i(x, y), not point_is_walkable(point))
	# Native Godot physics bodies along the perimeter of the walkable cells.
	var wall_body = StaticBody2D.new()
	wall_body.collision_layer = 2
	wall_body.collision_mask = 1
	collision_root.add_child(wall_body)
	for y in range(36):
		for x in range(64):
			var cell = Vector2i(x, y)
			if astar.is_point_solid(cell):
				continue
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor = cell + direction
				if astar.region.has_point(neighbor) and not astar.is_point_solid(neighbor):
					continue
				var center = Vector2(x * 20 + 10, y * 20 + 10) + Vector2(direction) * 10.0
				var shape = SegmentShape2D.new()
				var tangent = Vector2(-direction.y, direction.x) * 10
				shape.a = center - tangent
				shape.b = center + tangent
				var collision = CollisionShape2D.new()
				collision.shape = shape
				wall_body.add_child(collision)

func nearest() -> Dictionary:
	var found: Dictionary = {}
	var distance = 78.0
	for entry in npcs:
		var candidate = player.position.distance_to(entry.position)
		if candidate < distance:
			distance = candidate
			found = entry
	return found

func set_active(value: bool) -> void:
	active = value
	player.movement_enabled = value
	if not value:
		player.stop()
		hint.hide()

func _process(_delta: float) -> void:
	var target = nearest() if active else {}
	hint.visible = not target.is_empty()
	if not target.is_empty():
		hint.position = target.position + Vector2(-75, -142 if target.frame >= 0 else -65)
		hint.text = "E  승선" if target.id == "boarding" else "E  대화"

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_point = get_global_transform_with_canvas().affine_inverse() * event.position
		var destination = Vector2i(local_point / 20.0)
		var origin = Vector2i(player.position / 20.0)
		if astar.region.has_point(destination) and not astar.is_point_solid(destination):
			player.click_path = astar.get_point_path(origin, destination)
