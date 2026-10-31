extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("HANGZHOU_FORT: "+message)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("hangzhou");game.exploration.set_active(true)
	var w=game.exploration;var player=w.player
	check(w.map_bounds.size==Vector2(5888,5632),"expanded bounds")
	var gate: Image=load("res://assets/maps/hangzhou/painted/city-gate.png").get_image()
	if gate.is_compressed():gate.decompress()
	check(gate.get_pixel(627,451).a>.98,"upstairs window conceals passing hero")
	check(gate.get_pixel(627,1028).a<.01,"lower arch remains alpha transparent")
	check(player.position==w.city_point([1080,90]),"arrive outside northern wall")
	check(not w.path_to(w.city_point([1080,470])).is_empty(),"outside-to-city path crosses open gate")
	for y in range(100,471,5):check(w.can_stand(w.city_point([1080,y])),"central passage clear at "+str(y))
	for p in [[750,385],[1300,385],[438,1000],[1790,1000],[1300,1725],[1590,360]]:check(not w.can_stand(w.city_point(p)),"walls/water cannot be crossed "+str(p))
	# Exercise CharacterBody2D motion using the same action as keyboard movement.
	player.position=w.city_point([1080,285]);await physics_frame
	Input.action_press("move_down")
	for i in range(110):await physics_frame
	Input.action_release("move_down");await physics_frame
	check(player.position.y>w.city_point([1080,420]).y,"actual movement through gate")
	player.position=w.city_point([750,335]);player.stop();await physics_frame
	Input.action_press("move_down")
	for i in range(65):await physics_frame
	Input.action_release("move_down");await physics_frame
	check(player.position.y<w.city_point([750,371]).y,"actual wall collision blocks movement")
	var records=preload("res://scripts/overland_travel.gd").LINKS
	var incoming=records.suzhou_hangzhou_canal.filter(func(e):return e.area=="hangzhou")[0]
	check(incoming.arrival==[1080,90],"canal arrival is outside")
	player.position=w.city_point([1080,100]);player.stop()
	check(game.save_system.write_slot(9) and game.save_system.load_slot(9),"new exterior saves load")
	check(player.position.distance_to(w.city_point([1080,100]))<1,"new save does not shift twice")
	var legacy=game.save_system.capture();legacy.world.layout_version=1;legacy.world.position=[3456,1472]
	check(game.save_system.validate(legacy),"old Hangzhou save remains valid")
	var before=game.progress.snapshot();var money=game.money
	var file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	check(game.save_system.load_slot(8),"old city save migrates")
	check(player.position.distance_to(w.city_point([1080,860]))<1,"old position translated with existing city")
	check(game.progress.snapshot()==before and game.money==money,"migration preserves progress and money")
	check(game.save_system.write_slot(8) and game.save_system.load_slot(8),"migrated save reloads")
	check(player.position.distance_to(w.city_point([1080,860]))<1,"translation occurs only once")
	game.queue_free();await process_frame;print("HANGZHOU_FORT: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
