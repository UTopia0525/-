extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("NANJING_COUNTRY: "+message)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
	var w=game.exploration;w.load_area("nanjing");await physics_frame
	var farms=0
	for o in w.city_data.objects:
		check(not str(o.id).begins_with("imperial_"),"no active palace building")
		if str(o.id).begins_with("countryside_"):
			farms+=1
			var r=o.rect;var front=w.city_point([r[0]+r[2]/2.0,r[1]+r[3]+18])
			check(w.can_stand(front),"clear farm entrance "+o.id)
			check(not w.path_to(front).is_empty(),"reachable farm entrance "+o.id)
	check(farms==4,"three northern homes and a barn")
	for p in [[120,700],[120,1020],[120,1260]]:check(not w.can_stand(w.city_point(p)),"western canal cannot be walked on "+str(p))
	check(w.can_stand(w.city_point([170,830])),"west landing retained")
	for o in w.city_data.objects:
		if str(o.id).begins_with("countryside_"):check(o.rect[0]>=430 and o.rect[1]<248,"farms grouped on dry northern bank")
	for x in range(480,1660,25):check(not w.can_stand(w.city_point([x,290])),"closed north wall "+str(x))
	for exit in w.travel_exits:check(not w.path_to(exit.position).is_empty(),"exit remains reachable "+exit.id)
	for p in [[650,90],[1050,225],[1360,220],[1708,650],[120,825]]:
		check(not w.path_to(w.city_point(p)).is_empty(),"connected countryside path "+str(p))
	var old_bank=game.save_system.capture();old_bank.world.position=[480,2960]
	DirAccess.make_dir_recursive_absolute(game.save_system.path(9).get_base_dir())
	var file=FileAccess.open(game.save_system.path(9),FileAccess.WRITE);file.store_string(JSON.stringify(old_bank));file.close()
	check(game.save_system.load_slot(9),"old western farmland save remains loadable")
	check(w.can_stand(w.player.position),"old western farmland save relocates onto dry ground")
	game.queue_free();await process_frame;print("NANJING_COUNTRY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
