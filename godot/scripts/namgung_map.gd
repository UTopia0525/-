extends "res://scripts/wuchang_map.gd"
func _init(admitted: bool=false) -> void:
 data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/namgung-estate/layout.json"))
 world_scale=Vector2(3,3);navigation_cell=24
 map_bounds=Rect2(0,0,data.world_size[0],data.world_size[1])
 data.admission_open=admitted
 if not admitted:
  # Closed perimeter prevents entering around the side walls as well as the gate.
  data.terrain_blockers.append_array(data.admission_barriers)
