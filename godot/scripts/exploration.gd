extends Node2D

const UI = preload("res://scripts/ui.gd")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const FOLLOW_CAMERA = preload("res://scripts/follow_camera.gd")
const Metrics=preload("res://scripts/exploration_metrics.gd")
const FOOT_RADIUS = Metrics.PLAYER_RADIUS
const CITIZEN_RADIUS = Metrics.CITIZEN_RADIUS
const CITIZEN_BOUNDS=Metrics.CITIZEN_BOUNDS
@export var map_bounds: Rect2 = Rect2(0, 0, 1280, 720)
@export_range(1.0, 3.0, 0.25) var camera_zoom: float = 1.5
var camera: Camera2D
var regional_map: Node2D
var travel_exits: Array[Dictionary]=[]
var area_name: String = "dock"
var player
var background: Sprite2D
var npcs: Array[Dictionary] = []
var decorations: Node2D
var collision_root: Node2D
var walk_regions: Array[Rect2] = []
var blockers: Array[Rect2] = []
var astar: AStarGrid2D = AStarGrid2D.new()
var city_data: Dictionary = {}
var ambient_nodes: Array[Node2D] = []
var art_tiles: Array[Dictionary] = []
var scenery_bounds: Array[Rect2] = []
var scenery_nodes: Array[Node2D] = []
var occlusion_roots: Array[Node2D] = []
const CITIZEN_REGIONS = {4: Rect2(69, 504, 254, 465), 5: Rect2(479, 529, 186, 440), 6: Rect2(829, 529, 272, 440), 7: Rect2(1236, 508, 205, 461)}
var load_revision:=0
var objectives: Array[Dictionary]=[]
var indicator: Node2D
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
	indicator=preload("res://scripts/interaction_indicator.gd").new()
	indicator.z_index=5
	decorations.add_child(indicator)
	indicator.hide()
	load_area("dock")

func load_area(value: String) -> void:
	load_revision+=1
	objectives.clear()
	travel_exits.clear()
	if is_instance_valid(regional_map):regional_map.free()
	regional_map=null
	area_name = value
	player.stop()
	player.set_display_height(float(player.animation_metadata.target_height) if value in ["changsha","mountain_road","wuchang","alliance_office"] else Metrics.PROLOGUE_HEIGHT)
	camera.set_focus_height(player.display_height*Metrics.CAMERA_FOCUS_RATIO)
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
	if value in ["mountain_road","wuchang","alliance_office"]:
		_load_regional(value)
	elif value == "changsha":
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
	if not is_instance_valid(regional_map):_build_collision_and_navigation()
	preload("res://scripts/overland_travel.gd").install(self)
	camera.set_map_bounds(map_bounds)
	camera.snap_to_player()

func _load_regional(value: String) -> void:
	regional_map=load("res://scripts/"+("mountain_road_map.gd" if value=="mountain_road" else "alliance_office_map.gd" if value=="alliance_office" else "wuchang_map.gd")).new()
	add_child(regional_map)
	city_data=regional_map.data.duplicate(true)
	city_data.ground_texture="res://assets/maps/"+("changsha-wuchang" if value=="mountain_road" else "alliance-office" if value=="alliance_office" else "wuchang")+"/ground.png"
	for district in city_data.districts:
		district.bounds=district.rect;district.category={"market":"market","workshops":"workshops","martial":"martial_hall"}.get(district.get("id",""),"regional")
	map_bounds=regional_map.map_bounds;camera.exploration_zoom=1.0
	background.texture=load(city_data.ground_texture)
	# The cached floor contains terrain only. Independent props retain shared Y sorting.
	regional_map.get_child(0).hide()
	blockers.assign(regional_map.blockers);walk_regions=[regional_map.walk_bounds]
	astar=regional_map.astar
	for node in regional_map.scenery_nodes:
		node.reparent(decorations);occlusion_roots.append(node);scenery_nodes.append(node);scenery_bounds.append(node.visual_rect)
		var spec: Dictionary=node.definition;var prefab: Dictionary=regional_map.prefabs[spec.prefab]
		var target=Rect2(spec.rect[0],spec.rect[1],spec.rect[2],spec.rect[3])
		if prefab.has("content_rect"):
			var c: Array=prefab.content_rect
			target=Rect2(target.position+Vector2(c[0],c[1])*target.size,target.size*Vector2(c[2],c[3]))
		art_tiles.append({"texture":load(prefab.texture),"source":Rect2(prefab.source[0],prefab.source[1],prefab.source[2],prefab.source[3]),"target":target})
	art_tiles.sort_custom(func(a,b):return a.target.end.y<b.target.end.y)
	player.position=city_point(city_data.spawn)
	if value=="wuchang":
		var civil=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_residents.json"))
		city_data.residents=civil.npcs;city_data.services=civil.services
		city_data.road_centers=[]
		for road in city_data.roads:
			for i in range(road.points.size()-1):
				var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var r=Rect2(a.min(b),a.max(b)-a.min(b)).grow(float(road.width)/2)
				city_data.road_centers.append([r.position.x,r.position.y,r.size.x,r.size.y])
		_populate_residents(city_data.residents)
		regional_map.resident_positions.assign(ambient_nodes.map(func(n):return n.position))
		regional_map._build_navigation()
		astar=regional_map.astar
		player.position=safe_player_position(player.position)

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
	_populate_residents(city_data.residents)
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

func _populate_residents(entries: Array) -> void:
	for entry in entries:
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
		sprite_atlas.atlas = load(entry.sprite_texture) if entry.has("sprite_texture") else preload("res://assets/characters.png")
		sprite_atlas.region = Rect2(entry.sprite_region[0],entry.sprite_region[1],entry.sprite_region[2],entry.sprite_region[3]) if entry.has("sprite_region") else CITIZEN_REGIONS[int(entry.frame)]
		sprite.texture = sprite_atlas
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * minf(Metrics.CITIZEN_HEIGHT / sprite.texture.get_height(),88.0/sprite.texture.get_width())
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
		citizen.set_meta("show_name",entry.has("service_id") or entry.get("story_actor",false) or entry.has("character_profile") or area_name=="wuchang")
		# Use the same foot baseline as the player for Y sorting.
		decorations.add_child(citizen)
		ambient_nodes.append(citizen)
		if citizen.get_meta("show_name"):
			var marker = Node2D.new()
			marker.set_meta("npc_id",entry.id)
			marker.position = citizen.position
			var tag = UI.label(marker, entry.name + (" · "+str(entry.role) if entry.has("character_profile") else "") + (" · 토벌" if entry.get("story_actor", false) else " · 거래" if entry.has("service_id") else ""), Rect2(-105, -Metrics.CITIZEN_HEIGHT-Metrics.NAME_GAP, 210, 26), 15, UI.GOLD)
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tag.add_theme_color_override("font_outline_color", Color("12201c"))
			tag.add_theme_constant_override("outline_size", 5)
			decorations.add_child(marker)
			occlusion_roots.append(marker)

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
		var atlas=AtlasTexture.new()
		atlas.atlas=preload("res://assets/characters.png")
		atlas.region=CITIZEN_REGIONS[frame]
		sprite.texture = atlas
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered=false
		sprite.scale = Vector2.ONE * (Metrics.PROLOGUE_HEIGHT / sprite.texture.get_height())
		sprite.offset=Vector2(-sprite.texture.get_width()/2,-sprite.texture.get_height())
		body.add_child(sprite)
	var tag = UI.label(body, title, Rect2(-100, -Metrics.PROLOGUE_HEIGHT-Metrics.NAME_GAP if frame >= 0 else -25, 200, 28), 14, UI.TEXT)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_shadow_color", Color("142019"))
	tag.add_theme_constant_override("shadow_offset_x", 2)
	tag.add_theme_constant_override("shadow_offset_y", 2)
	decorations.add_child(body)
	npcs.append({"id": id, "name": title, "position": point, "node": body, "frame": frame})

func point_is_walkable(point: Vector2) -> bool:
	if is_instance_valid(regional_map):return regional_map.can_stand(point,0)
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
	if is_instance_valid(regional_map):
		if not regional_map.can_stand(point,radius):return false
		if residents:
			for citizen in ambient_nodes:
				if point.distance_to(citizen.position)<=radius+CITIZEN_RADIUS:return false
		return true
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
	var visual := Rect2(point+CITIZEN_BOUNDS.position,CITIZEN_BOUNDS.size)
	for bounds in scenery_bounds:
		if visual.grow(6).intersects(bounds): return false
	for block in blockers:
		if visual.grow(6).intersects(block): return false
	for other in ambient_nodes:
		if visual.grow(8).intersects(Rect2(other.position+CITIZEN_BOUNDS.position,CITIZEN_BOUNDS.size)): return false
	var art_point := point / (map_bounds.size / Vector2(city_data.art_size[0], city_data.art_size[1]))
	for road in city_data.road_centers:
		if Rect2(road[0], road[1], road[2], road[3]).has_point(art_point): return false
	if entry.has("district"):
		for district in city_data.districts:
			if district.id==entry.district and not _city_rect(district.bounds).has_point(point):return false
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
	return city_point(city_data.spawn) if area_name in ["changsha","mountain_road","wuchang","alliance_office"] else preferred

func path_to(point: Vector2, interaction: bool = false) -> PackedVector2Array:
	if is_instance_valid(regional_map):
		if not interaction:return regional_map.path_to(player.position,point)
		var candidates: Array[Vector2]=[]
		for radius in [48.0,64.0]:
			for i in range(16):
				var p=point+Vector2.from_angle(TAU*i/16)*radius
				if can_stand(p):candidates.append(p)
		candidates.sort_custom(func(a,b):return a.distance_squared_to(player.position)<b.distance_squared_to(player.position))
		for candidate in candidates:
			var path=regional_map.path_to(player.position,candidate)
			if not path.is_empty():return path
		return []
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
	var candidates: Array=npcs.duplicate()
	candidates.append_array(travel_exits)
	var owner_game=get_parent()
	var errands=owner_game.get("ordinary_quests")
	for citizen in ambient_nodes:
		var id: String=citizen.get_meta("npc_id")
		var entry={"id":id,"name":citizen.get_meta("display_name"),"position":citizen.position,"node":citizen,"frame":citizen.get_meta("frame"),"important":citizen.get_meta("story_actor",false)}
		var service: String=citizen.get_meta("service_id","")
		if not service.is_empty():entry.service_id=service;entry.important=true
		if is_instance_valid(errands) and (not errands.marker_for(id).is_empty() or errands.is_target(id)):entry.important=true
		candidates.append(entry)
	candidates.append_array(objectives)
	var found: Dictionary={}
	var best:=INF
	for entry in candidates:
		var distance: float=player.position.distance_to(entry.position)
		if distance>=78 or not _clear_interaction(entry.position,entry.node):continue
		# A small tie preference prevents a nearby bystander stealing a marked interaction.
		var score: float=distance-(12.0 if entry.get("important",false) else 0.0)
		if score<best:best=score;found=entry
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
	for exit in travel_exits:
		exit.node.set_available(not target.is_empty() and target.id==exit.id)
	hint.visible = not target.is_empty()
	indicator.visible = not target.is_empty() and not target.has("travel")
	if not target.is_empty():
		indicator.position=target.position
		indicator.set_body_height((Metrics.CITIZEN_HEIGHT if area_name in ["changsha","wuchang"] else Metrics.PROLOGUE_HEIGHT) if target.frame>=0 else 0.0)
	if not target.is_empty():
		hint.add_theme_color_override("font_color",Color("9de5ff") if target.has("travel") else UI.GOLD)
		hint.position = target.position + Vector2(-75, 20 if target.has("travel") else 14)
		hint.text = "F  이동" if target.has("travel") else "F  조사" if str(target.id).begins_with("quest_goal:") else "F  승선" if target.id == "boarding" else ("F  거래" if target.has("service_id") else "F  대화")

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_point = get_global_transform_with_canvas().affine_inverse() * event.position
		var target: Vector2 = local_point
		var interaction := false
		for citizen in ambient_nodes:
			if Rect2(citizen.position+CITIZEN_BOUNDS.position,CITIZEN_BOUNDS.size).has_point(local_point):
				target = citizen.position
				interaction = true
				break
		# Prologue actors use Area2D sprites rather than city ambient bodies.
		# A click on their head must approach their feet, not an unwalkable
		# point in the illustration above them.
		for entry in npcs:
			var hit=false
			if entry.frame>=0:
				for child in entry.node.get_children():
					if child is Sprite2D and child.get_rect().has_point(child.to_local(to_global(local_point))):hit=true;break
			else:hit=Rect2(entry.position-Vector2(55,35),Vector2(110,70)).has_point(local_point)
			if hit:target=entry.position;interaction=true;break
		for entry in objectives+travel_exits:
			var hitbox=Rect2(entry.position-Vector2(62,130),Vector2(124,160)) if entry.has("travel") else Rect2(entry.position-Vector2(25,40),Vector2(50,60))
			if hitbox.has_point(local_point):target=entry.position;interaction=true;break
		player.click_path = path_to(target, interaction)
