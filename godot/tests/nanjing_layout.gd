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
	for p in [[414,820],[750,840],[1324,850]]:check(w.can_stand(w.city_point(p)),"bridge center is traversable "+str(p))
	for p in [[560,825],[1020,855],[1435,867]]:check(not w.can_stand(w.city_point(p)),"river blocks walking "+str(p))
	# The riverside landing now opens directly into the city thoroughfare.
	for x in range(110,261,5):check(w.can_stand(w.city_point([x,530])),"open quay entrance "+str(x))
	for x in range(1380,1496,15):check(w.can_stand(w.city_point([x,530])),"avenue remains outside palace corner "+str(x))
	for pt in [[1450,560],[1450,600],[1430,680]]:check(w.can_stand(w.city_point(pt)),"south turning palace verge "+str(pt))
	w.player.position=w.city_point([255,530])
	for npc in w.ambient_nodes:check(not w.path_to(npc.position,true).is_empty(),"every civilian/quest actor reachable "+str(npc.name))
	check(not w.scenery_nodes.any(func(n):return n.name=="west_city_gate"),"no palace gate/wall fragment at the river landing")
	check(not w.path_to(w.travel_exits[0].position,true).is_empty(),"landing exit remains accessible from the city")
	check(w.city_data.reference=="docs/cities/designs/nanjing-npc-preview.png","original design explicitly remains the source of layout")
	game.queue_free();await process_frame
	print("NANJING_LAYOUT: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
