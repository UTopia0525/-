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
	# The side gate must provide a continuous west-east route under its roof.
	for x in range(110,261,5):check(w.can_stand(w.city_point([x,530])),"gate foot corridor "+str(x))
	w.player.position=w.city_point([255,530])
	for npc in w.ambient_nodes:check(not w.path_to(npc.position,true).is_empty(),"every civilian/quest actor reachable "+str(npc.name))
	var gate=w.scenery_nodes.filter(func(n):return n.name=="west_city_gate")[0]
	check(gate.position.y>w.city_point([175,530]).y and w.decorations.y_sort_enabled,"gate roof sorts over character in passage")
	check(w.city_data.reference=="docs/cities/designs/nanjing-npc-preview.png","original design explicitly remains the source of layout")
	game.queue_free();await process_frame
	print("NANJING_LAYOUT: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
