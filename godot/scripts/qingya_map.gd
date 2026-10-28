extends "res://scripts/wuchang_map.gd"
func _init(area: String="qingya_hamlet",ruined: bool=false,restored: bool=false,camp_open: bool=false) -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/"+area.replace("_","-")+"/layout.json"))
	world_scale=Vector2(3,3);navigation_cell=24
	map_bounds=Rect2(0,0,data.world_size[0],data.world_size[1])
	if area=="qingya_camp" and camp_open:
		data.objects=data.objects.filter(func(o):return o.id!="sealed_front_gate")
		data.terrain_blockers=data.terrain_blockers.filter(func(r):return not (r[0]==640 and r[1]==815))
	if area=="qingya_hamlet" and restored:
		for entry in data.objects:
			if entry.id=="house_nw":entry.prefab="ruined_home"
			elif entry.id=="grain_store":entry.prefab="ruined_store"
		data.objects.append({"id":"repair_lumber","prefab":"cargo","rect":[640,650,110,75]})
	elif area=="qingya_hamlet" and ruined:
		for entry in data.objects:
			if str(entry.id).begins_with("house_"):entry.prefab="ruined_home"
			elif entry.id=="grain_store":entry.prefab="ruined_store"
