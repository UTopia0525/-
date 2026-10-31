extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("CITY_FORTS: "+message)
func move_for(w,direction: String,frames: int) -> void:
	Input.action_press(direction)
	for i in range(frames):await physics_frame
	Input.action_release(direction);await physics_frame;w.player.stop()
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
	for area in ["changsha","wuchang","nanjing"]:
		if area=="wuchang":game.alliance_visit.phase="visiting"
		var w=game.exploration;w.load_area(area);await physics_frame
		check(w.city_data.get("fortifications_built",false),"fortifications installed "+area)
		for n in w.ambient_nodes:
			check(not w.path_to(n.position,true).is_empty(),"reachable resident "+area+"/"+str(n.name))
			var body=Rect2(n.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
			for r in w.scenery_bounds:check(not body.grow(4).intersects(r),"full body clear "+area+"/"+str(n.name))
		for exit in w.travel_exits:check(not w.path_to(exit.position).is_empty(),"reachable exit "+area+"/"+exit.id)
		var gates={"changsha":[[1145,510],[768,75],[768,945],[260,200],[260,460],[260,670]],"wuchang":[[1100,1440],[1950,945],[230,945]],"nanjing":[[255,830],[1670,1295],[385,280]]}[area]
		for p in gates:check(w.can_stand(w.city_point(p)),"open passage "+area+"/"+str(p))
		if area=="nanjing":
			for y in range(335,1071,10):check(w.can_stand(w.city_point([900,y])),"clear central avenue at "+str(y))
			check(not w.can_stand(w.city_point([900,275])),"palace closed")
			for p in [[574,1120],[910,1140],[1484,1150]]:check(w.can_stand(w.city_point(p)),"river bridge retained "+str(p))
		if area=="changsha":
			w.set_active(true);w.player.position=w.city_point([1100,510]);await physics_frame;await move_for(w,"move_right",110)
			check(w.player.position.x>w.city_point([1200,510]).x,"keyboard crosses Changsha east gate")
		elif area=="wuchang":
			w.set_active(true);w.player.position=w.city_point([1890,945]);await physics_frame;await move_for(w,"move_right",110)
			check(w.player.position.x>w.city_point([2000,945]).x,"keyboard crosses Wuchang east gate")
		else:
			w.set_active(true);w.player.position=w.city_point([180,830]);await physics_frame;await move_for(w,"move_right",110)
			check(w.player.position.x>w.city_point([330,830]).x,"keyboard crosses Nanjing west gate")
			w.player.position=w.city_point([900,350]);w.player.stop()
			check(game.save_system.write_slot(9) and game.save_system.load_slot(9),"new capital save")
			check(w.player.position.distance_to(w.city_point([900,350]))<1,"new capital save is not translated twice")
			var legacy=game.save_system.capture();legacy.world.layout_version=2;legacy.world.position=[2000,2120]
			check(game.save_system.validate(legacy),"previous capital save accepted")
			var f=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close()
			var money=game.money;var stats=game.progress.stats.duplicate()
			check(game.save_system.load_slot(8),"previous capital save migrates")
			check(w.player.position.distance_to(w.city_point([660,830]))<1,"previous city coordinates translated")
			check(game.money==money and game.progress.stats==stats,"migration preserves money and stats")
	game.queue_free();await process_frame;print("CITY_FORTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
