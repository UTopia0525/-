extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("HANGZHOU_PAINTED: "+message)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("hangzhou")
	var w=game.exploration;var map=w.regional_map
	check(w.background.material==map.get_child(0).material,"same painted floor in real exploration")
	for node in map.scenery_nodes:
		var spec=node.definition;var prefab=map.prefabs[spec.prefab]
		if prefab.kind!="building":continue
		check(prefab.get("preserve_aspect",false),"no stretched building "+spec.id)
		var source=Vector2(prefab.source[2],prefab.source[3])
		check(is_equal_approx(node.visual_rect.size.aspect(),source.aspect()),"authored proportions "+spec.id)
		var front=Vector2(node.visual_rect.get_center().x,node.visual_rect.end.y+60)
		check(not w.path_to(front).is_empty(),"visible doorway approach "+spec.id)
	for pair in [["travel:bg_warehouse","warehouse"],["travel:bg_hall","home_1525_950"],["travel:hall_entry","zuiyue_tower"]]:
		var exit=w.travel_exits.filter(func(e):return e.id==pair[0])[0]
		var facade=map.scenery_nodes.filter(func(n):return n.definition.id==pair[1])[0].visual_rect
		check(exit.position.x>=facade.position.x and exit.position.x<=facade.end.x,"portal below matching facade "+pair[0])
		check(exit.position.y>=facade.end.y and exit.position.y-facade.end.y<150,"portal near front door "+pair[0])
		check(not w.path_to(exit.position).is_empty(),"path from north entry to portal "+pair[0])
		var back=preload("res://scripts/overland_travel.gd").LINKS[exit.travel.area].filter(func(e):return e.area=="hangzhou")[0]
		check(w.can_stand(w.city_point(back.arrival)),"clear return point "+pair[0])
	game.queue_free();await process_frame;print("HANGZHOU_PAINTED: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
