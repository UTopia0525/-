extends "res://scripts/wuchang_map.gd"
func _init(area: String="blackguild_hall") -> void:
 data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/"+area.replace("_","-")+"/layout.json"))
 world_scale=Vector2(2,2);navigation_cell=24;map_bounds=Rect2(0,0,3072,2048)
