extends Node2D

const UI = preload("res://scripts/ui.gd")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const FOLLOW_CAMERA = preload("res://scripts/follow_camera.gd")
const FOOT_RADIUS = 11.0
const CITIZEN_RADIUS = 12.0
@export var map_bounds: Rect2 = Rect2(0, 0, 1280, 720)
@export_range(1.0, 3.0, 0.25) var camera_zoom: float = 1.5
var camera: Camera2D
var area_name: String = "dock"
var player
var background: Sprite2D
var npcs: Array[Dictionary] = []
var decorations: Node2D
var collision_root: Node2D
var walk_regions: Array[Rect2] = []
var blockers: Array[Rect2] = []
var astar = AStarGrid2D.new()
var city_data: Dictionary = {}
var ambient_nodes: Array[Node2D] = []
var art_tiles: Array[Dictionary] = []
var scenery_bounds: Array[Rect2] = []
var scenery_nodes: Array[Node2D] = []
var occlusion_roots: Array[Node2D] = []
const CITIZEN_REGIONS = {4: Rect2(69, 504, 254, 465), 5: Rect2(479, 529, 186, 440), 6: Rect2(829, 529, 272, 440), 7: Rect2(1236, 508, 205, 461)}
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
	camera = FOLLOW_CAMERA.new()
	camera.name = "FollowCamera"
	camera.exploration_zoom = camera_zoom
	player.add_child(camera)
	collision_root = Node2D.new()
	add_child(collision_root)
	hint = UI.label(self, "F  대화", Rect2(0, 0, 150, 30), 15, UI.GOLD)
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
	for node in ambient_nodes:
		node.free()
	ambient_nodes.clear()
	for node in occlusion_roots:
		node.free()
	occlusion_roots.clear()
	for node in background.get_children():
		node.free()
	art_tiles.clear()
	scenery_bounds.clear()
	scenery_nodes.clear()
	city_data = {}
	map_bounds = Rect2(0, 0, 1280, 720)
	camera.exploration_zoom = camera_zoom
	if value == "changsha":
		_load_changsha()
	elif value == "dock":
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
	background.position = map_bounds.position
	background.scale = map_bounds.size / background.texture.get_size()
	_build_collision_and_navigation()
	camera.set_map_bounds(map_bounds)
	camera.snap_to_player()

func _load_changsha() -> void:
	city_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/changsha/layout.json"))
	map_bounds = Rect2(0, 0, city_data.world_size[0], city_data.world_size[1])
	camera.exploration_zoom = 1.0
	background.texture = load(city_data.ground_texture)
	walk_regions.clear()
	blockers.clear()
	for rectangle in city_data.walk_regions:
		walk_regions.append(_city_rect(rectangle))
	for rectangle in city_data.blockers:
		blockers.append(_city_rect(rectangle))
	_build_city_art()
	player.position = city_point(city_data.spawn)
	for entry in city_data.residents:
		var citizen = CharacterBody2D.new()
		citizen.collision_layer = 2
		citizen.collision_mask = 3
		var feet = CollisionShape2D.new()
		var foot_shape = CircleShape2D.new()
		foot_shape.radius = CITIZEN_RADIUS
		feet.shape = foot_shape
		citizen.add_child(feet)
		var sprite = Sprite2D.new()
		var sprite_atlas = AtlasTexture.new()
		sprite_atlas.atlas = preload("res://assets/characters.png")
		sprite_atlas.region = CITIZEN_REGIONS[int(entry.frame)]
		sprite.texture = sprite_atlas
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * (82.0 / sprite.texture.get_height())
		sprite.offset = Vector2(-sprite.texture.get_width() / 2.0, -sprite.texture.get_height())
		citizen.add_child(sprite)
		citizen.position = _clear_citizen_position(city_point(entry.point), entry)
		citizen.name = entry.id
		citizen.set_meta("npc_id", entry.id)
		citizen.set_meta("display_name", entry.name)
		citizen.set_meta("quest_actor", entry.quest_actor)
		citizen.set_meta("post", entry.post)
		citizen.set_meta("frame", entry.frame)
		citizen.set_meta("service_id", entry.get("service_id", ""))
		citizen.set_meta("story_actor", entry.get("story_actor", false))
		# Use the same foot baseline as the player for Y sorting.
		decorations.add_child(citizen)
		ambient_nodes.append(citizen)
		if entry.has("service_id") or entry.get("story_actor", false):
			var marker = Node2D.new()
			marker.position = citizen.position
			var tag = UI.label(marker, entry.name + (" · 토벌" if entry.get("story_actor", false) else " · 거래"), Rect2(-105, -116, 210, 26), 15, UI.GOLD)
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tag.add_theme_color_override("font_outline_color", Color("12201c"))
			tag.add_theme_constant_override("outline_size", 5)
			decorations.add_child(marker)
			occlusion_roots.append(marker)
	player.position = safe_player_position(player.position)
	# Identify the new martial hall in the existing courtyard building.
	var hall = Node2D.new()
	hall.z_index = 1
	hall.position = city_point([944, 615])
	var plaque = UI.panel(hall, Rect2(-95, -38, 190, 38), Color("28241af2"))
	var hall_name = UI.label(plaque, "장사 무관", Rect2(5, 3, 180, 30), 20, UI.GOLD)
	hall_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decorations.add_child(hall)
	occlusion_roots.append(hall)

func _build_city_art() -> void:
	var prefabs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(city_data.prefabs_path))
	var world_scale := map_bounds.size / Vector2(city_data.art_size[0], city_data.art_size[1])
	for spec in city_data.objects:
		var prefab: Dictionary = prefabs[spec.prefab]
		var node = preload("res://scripts/city_scenery.gd").new()
		node.configure(spec, prefab, world_scale)
		decorations.add_child(node)
		occlusion_roots.append(node)
		scenery_nodes.append(node)
		scenery_bounds.append(node.visual_rect)
		for rectangle in node.collision_rects:
			blockers.append(rectangle)
			city_data.scenery_objects.append({"kind":prefab.kind, "bounds":[rectangle.position.x / world_scale.x, rectangle.position.y / world_scale.y, rectangle.size.x / world_scale.x, rectangle.size.y / world_scale.y]})
		var src: Array = prefab.source
		var target: Array = spec.rect
		art_tiles.append({"texture":load(prefab.texture), "source":Rect2(src[0], src[1], src[2], src[3]), "target":Rect2(target[0], target[1], target[2], target[3])})
	art_tiles.sort_custom(func(a,b): return a.target.end.y < b.target.end.y)

func city_point(point: Array) -> Vector2:
	return Vector2(point[0], point[1]) * map_bounds.size / Vector2(city_data.art_size[0], city_data.art_size[1])

func _city_rect(rectangle: Array) -> Rect2:
	return Rect2(city_point([rectangle[0], rectangle[1]]), city_point([rectangle[2], rectangle[3]]))

func district_at_player() -> String:
	for district in city_data.get("districts", []):
		if _city_rect(district.bounds).has_point(player.position):
			return district.name
	return "성내 거리"

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

func _inside_walk_regions(point: Vector2) -> bool:
	for region in walk_regions:
		if region.has_point(point): return true
	return false

func can_stand(point: Vector2, radius: float = FOOT_RADIUS, residents: bool = true) -> bool:
	# A free center alone does not guarantee that the character's feet fit.
	if not _inside_walk_regions(point): return false
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-0.707, -0.707), Vector2(0.707, -0.707), Vector2(-0.707, 0.707), Vector2(0.707, 0.707)]:
		if not _inside_walk_regions(point + direction * radius): return false
	for block in blockers:
		if point.distance_squared_to(point.clamp(block.position, block.end)) <= radius * radius: return false
	if residents:
		for citizen in ambient_nodes:
			if point.distance_to(citizen.position) <= radius + CITIZEN_RADIUS: return false
	return true

func _citizen_fits(point: Vector2, entry: Dictionary) -> bool:
	if not can_stand(point, CITIZEN_RADIUS): return false
	var visual := Rect2(point - Vector2(28, 96), Vector2(56, 96))
	for bounds in scenery_bounds:
		if visual.grow(6).intersects(bounds): return false
	for block in blockers:
		if visual.grow(6).intersects(block): return false
	for other in ambient_nodes:
		if visual.grow(8).intersects(Rect2(other.position - Vector2(28, 96), Vector2(56, 96))): return false
	var art_point := point / (map_bounds.size / Vector2(city_data.art_size[0], city_data.art_size[1]))
	for road in city_data.road_centers:
		if Rect2(road[0], road[1], road[2], road[3]).has_point(art_point): return false
	# Keep shop staff in their assigned district when moving them away from scenery.
	if entry.has("service_id"):
		var categories = {"city_merchant":"market", "city_artisan":"workshops", "city_instructor":"martial_hall"}
		for district in city_data.districts:
			if district.category == categories[entry.service_id] and not _city_rect(district.bounds).has_point(point): return false
	return true

func _clear_citizen_position(preferred: Vector2, entry: Dictionary) -> Vector2:
	if _citizen_fits(preferred, entry): return preferred
	# Deterministic local search; art revisions cannot silently put NPCs on roofs.
	for ring in range(1, 49):
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if absi(x) != ring and absi(y) != ring: continue
				var candidate := preferred + Vector2(x, y) * 8.0
				if _citizen_fits(candidate, entry): return candidate
	push_error("No clear position for city NPC: " + str(entry.id))
	return preferred

func safe_player_position(preferred: Vector2) -> Vector2:
	if can_stand(preferred): return preferred
	for ring in range(1, 65):
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if absi(x) != ring and absi(y) != ring: continue
				var candidate := preferred + Vector2(x, y) * 20.0
				if can_stand(candidate): return candidate
	return city_point(city_data.spawn) if area_name == "changsha" else preferred

func path_to(point: Vector2, interaction: bool = false) -> PackedVector2Array:
	var origin := Vector2i(player.position / 20.0)
	var destination := Vector2i(point / 20.0)
	if not astar.region.has_point(origin): return []
	if astar.is_point_solid(origin):
		# The feet can fit even when the containing cell's center is too close to a wall.
		var neighbors: Array[Vector2i] = []
		for y in range(-2, 3):
			for x in range(-2, 3):
				var cell := origin + Vector2i(x, y)
				if not astar.region.has_point(cell) or astar.is_point_solid(cell): continue
				var target := astar.get_point_position(cell)
				var clear := true
				for step in range(1, 9):
					if not can_stand(player.position.lerp(target, step / 8.0)): clear = false; break
				if clear: neighbors.append(cell)
		if neighbors.is_empty(): return []
		neighbors.sort_custom(func(a, b): return astar.get_point_position(a).distance_squared_to(player.position) < astar.get_point_position(b).distance_squared_to(player.position))
		origin = neighbors[0]
	if astar.region.has_point(destination) and not astar.is_point_solid(destination):
		return astar.get_point_path(origin, destination)
	if not interaction: return []
	# Stop beside an occupied NPC instead of pathing into their collision body.
	var candidates: Array[Vector2i] = []
	for y in range(-3, 4):
		for x in range(-3, 4):
			var cell := destination + Vector2i(x, y)
			if astar.region.has_point(cell) and not astar.is_point_solid(cell) and astar.get_point_position(cell).distance_to(point) < 70:
				candidates.append(cell)
	candidates.sort_custom(func(a, b): return astar.get_point_position(a).distance_squared_to(player.position) < astar.get_point_position(b).distance_squared_to(player.position))
	for cell in candidates:
		var path := astar.get_point_path(origin, cell)
		if not path.is_empty(): return path
	return []

func _build_collision_and_navigation() -> void:
	var origin = Vector2i(floori(map_bounds.position.x / 20.0), floori(map_bounds.position.y / 20.0))
	var end = Vector2i(ceili(map_bounds.end.x / 20.0), ceili(map_bounds.end.y / 20.0))
	astar.region = Rect2i(origin, end - origin)
	astar.cell_size = Vector2(20, 20)
	astar.offset = Vector2(10, 10)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in range(astar.region.position.y, astar.region.end.y):
		for x in range(astar.region.position.x, astar.region.end.x):
			astar.set_point_solid(Vector2i(x, y), not can_stand(Vector2(x * 20 + 10, y * 20 + 10)))
	var wall_body = StaticBody2D.new()
	wall_body.name = "SceneryCollision"
	wall_body.collision_layer = 2
	wall_body.collision_mask = 3
	collision_root.add_child(wall_body)
	# Exact scenery shapes serve both keyboard movement and moving NPC bodies.
	var terrain_blocks: Array[Rect2] = []
	if area_name == "changsha":
		for rectangle in city_data.blockers: terrain_blocks.append(_city_rect(rectangle))
	else: terrain_blocks = blockers
	for block in terrain_blocks:
		var shape = RectangleShape2D.new()
		shape.size = block.size
		var collision = CollisionShape2D.new()
		collision.position = block.get_center()
		collision.shape = shape
		wall_body.add_child(collision)
	# Only the outer walk-region boundary uses cells; scenery is never grid-rounded.
	for y in range(astar.region.position.y, astar.region.end.y):
		for x in range(astar.region.position.x, astar.region.end.x):
			var point := Vector2(x * 20 + 10, y * 20 + 10)
			if not _inside_walk_regions(point): continue
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if _inside_walk_regions(point + Vector2(direction) * 20.0): continue
				var center = point + Vector2(direction) * 10.0
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
		if candidate < distance and _clear_interaction(entry.position, entry.node):
			distance = candidate
			found = entry
	for citizen in ambient_nodes:
		var service_id: String = citizen.get_meta("service_id", "")
		if service_id.is_empty() and not citizen.get_meta("story_actor", false):
			continue
		var candidate = player.position.distance_to(citizen.position)
		if candidate < distance and _clear_interaction(citizen.position, citizen):
			distance = candidate
			found = {"id": citizen.get_meta("npc_id"), "name": citizen.get_meta("display_name"), "position": citizen.position, "node": citizen, "frame": citizen.get_meta("frame")}
			if not service_id.is_empty(): found["service_id"] = service_id
	return found

func _clear_interaction(point: Vector2, target: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(player.global_position, to_global(point), 2)
	if target is CollisionObject2D: query.exclude = [target.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

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
		hint.text = "F  승선" if target.id == "boarding" else ("F  거래" if target.has("service_id") else "F  대화")

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_point = get_global_transform_with_canvas().affine_inverse() * event.position
		var target: Vector2 = local_point
		var interaction := false
		for citizen in ambient_nodes:
			if Rect2(citizen.position - Vector2(28, 82), Vector2(56, 94)).has_point(local_point):
				target = citizen.position
				interaction = true
				break
		player.click_path = path_to(target, interaction)
