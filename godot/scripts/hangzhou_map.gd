extends "res://scripts/wuchang_map.gd"
func _init() -> void:
 data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/hangzhou/layout.json"))
 world_scale=Vector2(3.2,3.2);navigation_cell=24;map_bounds=Rect2(0,0,5888,5632)
