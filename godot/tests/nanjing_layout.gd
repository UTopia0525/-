extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("NANJING_LAYOUT: "+msg)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang()
	game.exploration.load_area("nanjing");game.exploration.set_active(true);await physics_frame
	var w=game.exploration
	for p in [[414,820],[750,840],[1324,850]]:check(w.can_stand(w.city_point([p[0]+160,p[1]+300])),"bridge center is traversable "+str(p))
	for p in [[560,825],[1020,855],[1435,867]]:check(not w.can_stand(w.city_point([p[0]+160,p[1]+300])),"river blocks walking "+str(p))
	# The riverside landing now opens directly into the city thoroughfare.
	for x in range(110,261,5):check(w.can_stand(w.city_point([x+160,830])),"open quay entrance "+str(x))
	for x in range(1380,1496,15):check(w.can_stand(w.city_point([x+160,830])),"avenue remains outside palace corner "+str(x))
	for pt in [[1450,560],[1450,600],[1430,680]]:check(w.can_stand(w.city_point([pt[0]+160,pt[1]+300])),"south turning palace verge "+str(pt))
	w.player.position=w.city_point([415,830])
	for npc in w.ambient_nodes:check(not w.path_to(npc.position,true).is_empty(),"every civilian/quest actor reachable "+str(npc.name))
	check(w.scenery_nodes.any(func(n):return n.name=="west_city_gate" and n.definition.prefab=="fort_west"),"west-facing city gate at landing")
	var quay_exit=w.travel_exits.filter(func(e):return e.id=="travel:hamlet")[0]
	check(not w.path_to(quay_exit.position,true).is_empty(),"landing exit remains accessible from the city")
	for exit in w.travel_exits:check(not w.path_to(exit.position,true).is_empty(),"all travel exits stay reachable "+str(exit.name))
	for node in w.scenery_nodes:
		if not node.definition.has("prefab"):continue
		var prefab: Dictionary=w.regional_map.prefabs[node.definition.prefab]
		if not prefab.get("preserve_aspect",false):continue
		check(is_equal_approx(node.sprite.scale.x,node.sprite.scale.y),"no stretched building "+str(node.name))
		check(is_zero_approx(node.sprite.rotation),"no rotated facade "+str(node.name))
		var plot=w.regional_map.rect(node.definition.rect)
		check(plot.grow(.1).encloses(node.visual_rect),"building remains inside its plot "+str(node.name))
	check(w.background.material.shader.resource_path.ends_with("nanjing_terrain.gdshader"),"playable scene uses painted material detail")
	check(w.city_data.capital_axis==900 and w.city_data.layout_version==3,"new avenue/northern palace layout explicitly versioned")
	game.queue_free();await process_frame
	print("NANJING_LAYOUT: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
