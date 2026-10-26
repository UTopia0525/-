extends "res://scripts/wuchang_map.gd"
func _init() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/nanjing/layout.json"))
	world_scale=Vector2(3,3);navigation_cell=24
	map_bounds=Rect2(0,0,data.world_size[0],data.world_size[1])
