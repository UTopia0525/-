extends "res://scripts/wuchang_map.gd"
var walk_polygon: PackedVector2Array
func _init() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/changsha-wuchang/layout.json"))
	world_scale=Vector2(data.world_size[0],data.world_size[1])/Vector2(data.art_size[0],data.art_size[1]);navigation_cell=16.0
	map_bounds=Rect2(0,0,data.world_size[0],data.world_size[1])
	var line=PackedVector2Array()
	for p in data.route:line.append(point(p))
	walk_polygon=Geometry2D.offset_polyline(line,float(data.half_width)*world_scale.x,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)[0]
func _inside(p: Vector2,radius: float) -> bool:
	if not Geometry2D.is_point_in_polygon(p,walk_polygon):return false
	for i in range(walk_polygon.size()):
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,walk_polygon[i],walk_polygon[(i+1)%walk_polygon.size()]))<radius:return false
	return true
func _build_boundaries() -> void:
	var body=StaticBody2D.new();body.collision_layer=2;add_child(body)
	for i in range(walk_polygon.size()):
		var shape=SegmentShape2D.new();shape.a=walk_polygon[i];shape.b=walk_polygon[(i+1)%walk_polygon.size()]
		var collision=CollisionShape2D.new();collision.shape=shape;body.add_child(collision)
