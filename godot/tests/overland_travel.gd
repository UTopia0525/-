extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("OVERLAND: "+message)
func press_f() -> void:
	var key=InputEventKey.new();key.keycode=KEY_F;key.physical_keycode=KEY_F;key.pressed=true
	Input.parse_input_event(key);await process_frame
	key=InputEventKey.new();key.keycode=KEY_F;key.physical_keycode=KEY_F;key.pressed=false
	Input.parse_input_event(key);await physics_frame
func exit_to(area: String) -> void:
	for exit in game.exploration.travel_exits:
		if exit.travel.area==area:
			game.exploration.player.position=exit.position;game.exploration.player.stop()
			await physics_frame;await create_timer(.04).timeout
			check(exit.node.get_script()==preload("res://scripts/travel_portal.gd") and not exit.node is CollisionObject2D,"exit is a blue non-blocking portal")
			check(exit.node.available and game.exploration.hint.text=="F  이동","nearby portal highlights and prompts F")
			await press_f()
			check(game.exploration.area_name==area,"F crosses into "+area);return
	check(false,"missing exit to "+area)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city();game.money=700
	game.ordinary_quests.accept(str(game.ordinary_quests.definitions.keys()[0]))
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	await physics_frame
	var progress=game.progress.snapshot();var quests=game.ordinary_quests.snapshot();var intro=game.chapter_one.snapshot()
	var city=game.exploration
	check(city.travel_exits[0].position.x>city.map_bounds.size.x*.9,"Changsha portal is at eastern farmland edge")
	check(not city.path_to(city.travel_exits[0].position).is_empty(),"Changsha spawn reaches eastern farmland portal")
	await exit_to("mountain_road")
	check(city.ambient_nodes.is_empty() and city.npcs.is_empty(),"road adds no NPCs")
	check(city.map_bounds.size==Vector2(4096,5120) and city.player.display_height==140,"half height retains horizontal size and actor proportions")
	var arrival=city.player.position
	await press_f()
	check(city.area_name=="mountain_road" and city.player.position.distance_to(arrival)<1,"F away from a portal never transfers")
	var portal=city.travel_exits[0].node
	var phase: float=portal.phase
	game.settings_menu.open_menu();await create_timer(.12).timeout
	check(portal.phase==phase,"portal animation obeys settings pause")
	game.settings_menu.close_menu()
	check(city.travel_exits.size()==2,"both road ends remain after quest refresh")
	var destination=city.travel_exits[1].position
	var path=city.path_to(destination)
	check(not path.is_empty(),"entire east-then-north road is connected")
	var last: Vector2=city.player.position
	var east_seen=false
	for point in path:
		if point.x>2700:east_seen=true
		if point.y<4250:check(east_seen,"horizontal eastern leg comes before northern leg")
		check(city.can_stand(point),"path clears mountain edge and props")
		check(not city.player.test_move(Transform2D(0,last),point-last),"actual feet traverse every road path segment")
		last=point
	check(city.can_stand(city.city_point([720,1175])) and not city.can_stand(city.city_point([400,750])),"turn is passable but mountains cannot be crossed")
	game.toggle_city_map();check(not city.active and game.city_overview.visible,"TAB opens route map and pauses movement")
	check(is_equal_approx(game.city_overview.map_rect.size.x/game.city_overview.map_rect.size.y,.8),"route overview preserves vertical aspect")
	for widget in game.city_overview.facility_widgets:check(not widget.visible,"empty road has no trade buttons")
	game.toggle_city_map()
	city.player.position=city.city_point([630,700]);city.player.stop()
	check(game.save_system.write_slot(1),"road can be saved")
	check(game.save_system.load_slot(1),"road save loads")
	check(city.area_name=="mountain_road" and city.can_stand(city.player.position),"restored mountain position is valid")
	city.player.position=city.city_point([650,450]);city.player.stop()
	var legacy=game.save_system.capture();legacy.world.erase("layout_version");legacy.world.position[1]*=2
	var expected: Vector2=city.player.position
	var file=FileAccess.open(game.save_system.path(3),FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	check(game.save_system.load_slot(3),"original long road save still loads")
	check(city.player.position.is_equal_approx(expected),"old north/south position migrates even from inside new height")
	check(game.save_system.capture().world.layout_version==2,"loaded position is tagged to prevent double migration")
	var invalid=game.save_system.capture();invalid.world.position=[100,5121]
	check(not game.save_system.validate(invalid),"new map coordinate bounds validated")
	await exit_to("wuchang")
	check(city.ambient_nodes.size()==12 and city.npcs.is_empty(),"Wuchang has nine civilians and three alliance members")
	check(city.player.position.y>6144 and city.can_stand(city.player.position),"arrive safely in southern Wuchang farmland")
	check(city.district_at_player()=="남문 밖 농촌","arrival is outside city walls")
	var gate=city.decorations.get_node("south_gate")
	var gate_route=city.path_to(gate.position+Vector2(0,-40))
	check(not gate_route.is_empty(),"rural arrival reaches city through south gate")
	check(not city.path_to(city.travel_exits.filter(func(e):return e.travel.area=="mountain_road")[0].position).is_empty(),"rural arrival reaches exit beyond farms")
	for field in city.city_data.fields:
		var point=city._city_rect(field.rect).get_center()
		check(not city.can_stand(point),"crop plots block feet and navigation")
		var query=PhysicsPointQueryParameters2D.new();query.position=point;query.collision_mask=2
		check(not city.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"crop plots have matching physical collision")
	check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"Wuchang exploration save roundtrip")
	var old_city=game.save_system.capture();old_city.world.position=[4400,5960]
	file=FileAccess.open(game.save_system.path(4),FileAccess.WRITE);file.store_string(JSON.stringify(old_city));file.close()
	check(game.save_system.load_slot(4) and city.player.position.is_equal_approx(Vector2(4400,5960)),"old Wuchang city saves keep original positions after rural extension")
	await exit_to("mountain_road");await exit_to("changsha")
	check(city.ambient_nodes.size()>0 and city.regional_map==null,"return restores existing Changsha NPCs and terrain")
	check(city.can_stand(city.player.position),"return point clear of gate and NPCs")
	game.toggle_city_map()
	for widget in game.city_overview.facility_widgets:check(widget.visible,"Changsha facility tools return")
	game.toggle_city_map()
	check(JSON.parse_string(JSON.stringify(game.progress.snapshot()))==JSON.parse_string(JSON.stringify(progress)) and game.ordinary_quests.snapshot()==quests and game.chapter_one.snapshot()==intro and game.money==700,"travel preserves money, equipment and active quest progress")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_OVERLAND: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
