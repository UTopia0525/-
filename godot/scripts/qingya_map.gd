extends "res://scripts/wuchang_map.gd"
func _init(area: String="qingya_hamlet",ruined: bool=false) -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/"+area.replace("_","-")+"/layout.json"))
	world_scale=Vector2(3,3);navigation_cell=24
	map_bounds=Rect2(0,0,data.world_size[0],data.world_size[1])
	if area=="qingya_hamlet" and ruined:
		for entry in data.objects:
			if str(entry.id).begins_with("house_"):entry.prefab="ruined_home"
			elif entry.id=="grain_store":entry.prefab="ruined_store"
