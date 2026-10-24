extends Node2D
## Standalone map review. No quest/NPC/state mutation before layout approval.
const SCENERY=preload("res://scripts/city_scenery.gd")
const GROUND=preload("res://scripts/wuchang_ground.gd")
const CELL=32
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/wuchang/layout.json"))
var prefabs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/changsha/layered/prefabs.json"))
var actors: Node2D
var scenery_nodes: Array=[]
var blockers: Array[Rect2]=[]
var astar=AStarGrid2D.new()
var world_scale=Vector2(4,4)
var map_bounds=Rect2(0,0,8192,6144)
var walk_bounds: Rect2
func _ready() -> void:
	prefabs.alliance_hall={"texture":"res://assets/maps/wuchang/alliance-hall.png","source":[0,0,1536,1024],"kind":"building","footprints":[[.10,.62,.80,.35]]}
	walk_bounds=rect(data.walk_bounds)
	var floor=GROUND.new();floor.data=data;floor.scale=world_scale;add_child(floor)
	actors=Node2D.new();actors.y_sort_enabled=true;add_child(actors)
	for spec in data.objects:
		var node=SCENERY.new();node.configure(spec,prefabs[spec.prefab],world_scale)
		actors.add_child(node);scenery_nodes.append(node);blockers.append_array(node.collision_rects)
	# Physical outer/river limits match the navigation walk bounds.
	for bounds in [Rect2(-128,-128,walk_bounds.position.x+128,6400),Rect2(walk_bounds.end.x,-128,1024,6400),Rect2(0,-128,8192,walk_bounds.position.y+128),Rect2(0,walk_bounds.end.y,8192,1024)]:
		var body=StaticBody2D.new();body.collision_layer=2
		var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=bounds.size;shape.shape=box;shape.position=bounds.get_center();body.add_child(shape);add_child(body)
	_build_navigation()
func point(value: Array) -> Vector2:return Vector2(value[0],value[1])*world_scale
func rect(value: Array) -> Rect2:return Rect2(point(value),Vector2(value[2],value[3])*world_scale)
func can_stand(p: Vector2,radius: float=16) -> bool:
	if not walk_bounds.grow(-radius).has_point(p):return false
	for bounds in blockers:
		if bounds.grow(radius).has_point(p):return false
	return true
func _build_navigation() -> void:
	astar.region=Rect2i(0,0,256,192);astar.cell_size=Vector2(CELL,CELL);astar.offset=Vector2(CELL,CELL)/2
	astar.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;astar.update()
	for y in range(astar.region.size.y):
		for x in range(astar.region.size.x):
			var p=Vector2(x*CELL+CELL/2,y*CELL+CELL/2)
			if not walk_bounds.grow(-16).has_point(p):astar.set_point_solid(Vector2i(x,y))
	for bounds in blockers:
		var grown=bounds.grow(16+float(CELL)/2)
		var low=Vector2i((grown.position/float(CELL)).floor()).max(Vector2i.ZERO)
		var high=Vector2i((grown.end/float(CELL)).ceil()).min(astar.region.end-Vector2i.ONE)
		for y in range(low.y,high.y+1):
			for x in range(low.x,high.x+1):astar.set_point_solid(Vector2i(x,y))
func _cell(p: Vector2) -> Vector2i:
	var cell=Vector2i((p/float(CELL)).floor())
	if astar.is_in_boundsv(cell) and not astar.is_point_solid(cell):return cell
	for radius in range(1,5):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var test=cell+Vector2i(x,y)
				if not astar.is_in_boundsv(test) or astar.is_point_solid(test):continue
				var target=astar.get_point_position(test)
				var clear=true
				for step in range(1,17):
					if not can_stand(p.lerp(target,step/16.0)):clear=false;break
				if clear:return test
	return Vector2i(-1,-1)
func path_to(from: Vector2,to: Vector2) -> PackedVector2Array:
	if not can_stand(to):return PackedVector2Array()
	var start=_cell(from);var end=_cell(to)
	if start.x<0 or end.x<0:return PackedVector2Array()
	var path=astar.get_point_path(start,end)
	if not path.is_empty():path.append(to)
	return path
func district_at(p: Vector2) -> String:
	for entry in data.districts:
		if rect(entry.rect).has_point(p):return entry.name
	return "남문길" if p.y>5200 else "성내 대로"
