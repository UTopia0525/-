extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("CUIYUE_HALL: "+msg)
func key(code: Key,pressed: bool) -> void:
	var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event)
	await process_frame;await physics_frame
func travel(id: String) -> void:
	var w=game.exploration
	var exits=w.travel_exits.filter(func(e):return e.id==id)
	check(exits.size()==1,"one exit "+id)
	if exits.is_empty():return
	w.player.position=exits[0].position;w.player.stop();await physics_frame
	await key(KEY_F,true);await key(KEY_F,false)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"])
	game.start_wuchang();game.exploration.load_area("hangzhou")
	var w=game.exploration
	check(not w.path_to(w.city_point([785,425])).is_empty(),"entry reachable from Hangzhou arrival")
	await travel("travel:hall_entry")
	check(w.area_name=="cuiyue_hall","actual F enters hall")
	check(w.map_bounds.size==Vector2(3072,2048) and w.player.display_height==140,"world and consistent character size")
	check(w.scenery_nodes.size()==15 and w.ambient_nodes.size()==6,"independent furnishings and six approved residents")
	for p in [[768,560],[768,660],[768,800],[768,967],[500,550],[1035,550],[375,835],[1160,805]]:
		check(not w.path_to(w.city_point(p)).is_empty(),"reachable aisle "+str(p))
	for p in [[768,410],[300,620],[1230,620],[200,920],[1300,920],[50,700],[768,180]]:
		check(not w.can_stand(w.city_point(p)),"furniture/wall blocks "+str(p))
	# Keyboard walking respects physical banquet-table collision, not only A*.
	w.player.position=w.city_point([300,710]);w.player.stop();await physics_frame
	await key(KEY_W,true)
	for i in range(60):await physics_frame
	await key(KEY_W,false)
	check(w.player.position.y>1280 and w.player.position.y<1420,"W approaches and stops at banquet table")
	check(w.can_stand(w.player.position,12),"physical stop remains outside table")
	w.player.position=w.city_point([768,800]);w.player.stop()
	var start=w.player.position
	await key(KEY_W,true)
	for i in range(30):await physics_frame
	await key(KEY_W,false)
	check(w.player.position.y<start.y-100,"central carpet accepts keyboard movement")
	game.toggle_city_map();check(game.city_overview.visible,"TAB overview in hall");game.toggle_city_map()
	check(game.quest_navigation.track("suzhou_silk","offer"),"track existing quest")
	check(game.quest_navigation.get_goal(w).get("goal_id")=="travel:hall_exit","tracked quest guides outside first")
	w.player.stop();var saved=w.player.position
	check(game.save_system.write_slot(8),"save interior exploration")
	w.load_area("hangzhou");check(game.save_system.load_slot(8),"load interior save")
	check(w.area_name=="cuiyue_hall" and w.player.position.distance_to(saved)<1,"restore hall and position")
	check(game.save_system.area_name("cuiyue_hall")=="항주 · 취월루","readable save location")
	await travel("travel:hall_exit")
	check(w.area_name=="hangzhou" and w.can_stand(w.player.position),"F returns to safe exterior")
	check(not w.path_to(w.city_point([1080,60])).is_empty(),"canal remains reachable")
	await travel("travel:hall_entry");check(w.area_name=="cuiyue_hall","repeat entry")
	game.queue_free();await process_frame
	print("CUIYUE_HALL: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
