extends "res://scripts/wuchang_map.gd"
func _init() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/nanjing/layout.json"))
	world_scale=Vector2(4,4);navigation_cell=24
	map_bounds=Rect2(0,0,data.world_size[0],data.world_size[1])

var city_time:=0.0
func _process(delta: float) -> void:
	city_time+=delta
	var world=get_parent()
	if not is_instance_valid(world) or world.get("area_name")!="nanjing":return
	for actor in world.ambient_nodes:
		if not str(actor.get_meta("npc_id","")).begins_with("nj_crowd_"):continue
		for child in actor.get_children():
			if child is Sprite2D:
				# Small idle gestures, never move the collision feet or a dialogue target.
				child.position.y=sin(city_time*1.7+actor.position.x*.01)*1.1
	for node in scenery_nodes:
		if not str(node.name).begins_with("capital_lantern_"):continue
		var warmth=.96+.04*sin(city_time*1.3+node.position.x*.003)
		node.sprite.modulate=Color(1.0,warmth,.91+.04*warmth)
