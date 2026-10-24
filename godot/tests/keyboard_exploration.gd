extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("KEYBOARD MAP: "+message)
func click(screen: Vector2) -> void:
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=screen;e.global_position=screen;e.pressed=pressed;Input.parse_input_event(e);await process_frame
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_city()
	for area in ["dock","deck","changsha","mountain_road","wuchang","alliance_office"]:
		var w=game.exploration;w.load_area(area);w.set_active(true);await physics_frame
		var before: Vector2=w.player.position
		var points=[before+Vector2(60,0)]
		if not w.npcs.is_empty():points.append(w.npcs[0].position-Vector2(0,65))
		if not w.ambient_nodes.is_empty():points.append(w.ambient_nodes[0].position-Vector2(0,65))
		if not w.travel_exits.is_empty():points.append(w.travel_exits[0].position)
		for point in points:
			await click(w.get_global_transform_with_canvas()*point);await create_timer(.08).timeout
			check(w.player.position.distance_to(before)<.1 and w.area_name==area,"clicks never move/interact/transfer in "+area)
			check(game.dialogue_lines.is_empty(),"map click starts no conversation in "+area)
	game.start_city();await physics_frame
	game.player_menu.open_menu("inventory");await process_frame
	var tab=game.player_menu.tabs[1]
	await click(tab.get_global_rect().get_center())
	check(game.player_menu.category=="elixir","inventory tabs retain real mouse clicks")
	game.player_menu.close_menu()
	# Facility purchase buttons still accept mouse input.
	game.money=1000;game.state="service";game.city_service.open_counter(game.exploration.city_data.services[0]);await process_frame
	game.city_service.select_item("light_step_pill");await process_frame
	var count=int(game.progress.inventory.light_step_pill)
	await click(game.city_service.action.get_global_rect().get_center())
	check(game.progress.inventory.light_step_pill==count+1,"trade purchase retains real mouse clicks")
	game.city_service.close_counter();game.reset();await create_timer(.2).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	if not failed:print("KEYBOARD MAP PASS: six maps ignore clicks; inventory and purchases retain mouse input")
	quit(1 if failed else 0)
