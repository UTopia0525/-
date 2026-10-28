extends "res://scripts/suzhou_map.gd"
## A short canal-side route with one small wharf spur. Water is physically inaccessible.
func _init() -> void:
 data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/suzhou-hangzhou/layout.json"))
 mountain_pass=true;world_scale=Vector2(2,2);navigation_cell=20;map_bounds=Rect2(0,0,3072,2048)
 var line=PackedVector2Array()
 for p in data.route:line.append(point(p))
 walk_polygon=Geometry2D.offset_polyline(line,float(data.half_width)*2,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)[0]
 var spur=PackedVector2Array()
 for p in data.spur:spur.append(point(p))
 var quay=Geometry2D.offset_polyline(spur,48,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)[0]
 walk_polygon=Geometry2D.merge_polygons(walk_polygon,quay)[0]
