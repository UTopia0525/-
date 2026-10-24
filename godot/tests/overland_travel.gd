extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("OVERLAND: "+message)
func exit_to(area: String) -> void:
	for exit in game.exploration.travel_exits:
		if exit.travel.area==area:
			game.exploration.player.position=exit.position;game.exploration.player.stop()
			await physics_frame;game.interact();await physics_frame
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
	check(not city.path_to(city.travel_exits[0].position).is_empty(),"Changsha spawn reaches north-gate trail entrance")
	await exit_to("mountain_road")
	check(city.ambient_nodes.is_empty() and city.npcs.is_empty(),"road adds no NPCs")
	check(city.travel_exits.size()==2,"both road ends remain after quest refresh")
	var destination=city.travel_exits[1].position
	var path=city.path_to(destination)
	check(not path.is_empty(),"entire east-then-north road is connected")
	var last: Vector2=city.player.position
	var east_seen=false
	for point in path:
		if point.x>2700:east_seen=true
		if point.y<8500:check(east_seen,"horizontal eastern leg comes before northern leg")
		check(city.can_stand(point),"path clears mountain edge and props")
		check(not city.player.test_move(Transform2D(0,last),point-last),"actual feet traverse every road path segment")
		last=point
	check(city.can_stand(city.city_point([720,2350])) and not city.can_stand(city.city_point([400,1500])),"turn is passable but mountains cannot be crossed")
	game.toggle_city_map();check(not city.active and game.city_overview.visible,"TAB opens route map and pauses movement")
	check(is_equal_approx(game.city_overview.map_rect.size.x/game.city_overview.map_rect.size.y,.4),"route overview preserves vertical aspect")
	for widget in game.city_overview.facility_widgets:check(not widget.visible,"empty road has no trade buttons")
	game.toggle_city_map()
	city.player.position=city.city_point([630,1400]);city.player.stop()
	check(game.save_system.write_slot(1),"road can be saved")
	check(game.save_system.load_slot(1),"road save loads")
	check(city.area_name=="mountain_road" and city.can_stand(city.player.position),"restored mountain position is valid")
	var invalid=game.save_system.capture();invalid.world.position=[100,10241]
	check(not game.save_system.validate(invalid),"new map coordinate bounds validated")
	await exit_to("wuchang")
	check(city.ambient_nodes.is_empty() and city.npcs.is_empty(),"Wuchang remains NPC-free")
	check(city.player.position.y>5500 and city.can_stand(city.player.position),"arrive safely at Wuchang south gate")
	check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"Wuchang exploration save roundtrip")
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
