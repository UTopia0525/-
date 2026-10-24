extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("WUCHANG: "+message)
func run() -> void:
	var scene=load("res://scenes/wuchang.tscn").instantiate();root.add_child(scene);await physics_frame;await physics_frame
	var city=scene.city
	check(city.get_world_2d()!=scene.atlas_view.get_world_2d(),"map thumbnail has isolated physics world")
	check(city.data.npcs.is_empty(),"NPC placement waits for layout approval")
	check(city.data.spawn[1]>1400,"arrival is the southern land route")
	check(city.scenery_nodes.size()==city.data.objects.size(),"every visible object has independent instance")
	check(city.data.districts.size()==10,"standard city districts plus southern countryside")
	check(city.can_stand(scene.player.position),"southern spawn is clear")
	for landmark in city.data.landmarks:
		var target=city.point(landmark.point)
		check(city.can_stand(target),"clear landmark: "+landmark.name)
		var path=city.path_to(scene.player.position,target)
		check(not path.is_empty(),"southern entrance can reach: "+landmark.name)
		for point in path:check(city.can_stand(point),"walkable path to "+landmark.name)
	for prop in city.scenery_nodes:
		check(prop.position.y==prop.visual_rect.end.y,"foot-sorted prop: "+str(prop.name))
		check(not prop.collision_rects.is_empty(),"physical prop: "+str(prop.name))
		if prop.get_meta("kind")=="gate":
			var foot=prop.position
			check(city.can_stand(foot-Vector2(0,10)),"open gate center: "+str(prop.name))
			check(not city.can_stand(prop.collision_rects[0].get_center()),"gate pillar blocks: "+str(prop.name))
	var hall=city.actors.get_node("alliance_main_hall")
	check(hall.visual_rect.size.y>=1100,"main hall has two-storey monumental height")
	check(city.rect(city.data.alliance_bounds).size==Vector2(4000,3280),"rural extension preserves the full existing alliance compound")
	scene.player.position=city.actors.get_node("south_gate").position+Vector2(0,60)
	var before=scene.player.position
	Input.action_press("move_up");for i in range(20):await physics_frame
	Input.action_release("move_up");await physics_frame
	check(scene.player.position.y<before.y-90,"south gate is traversable with actual player physics")
	scene.toggle_map();check(not scene.player.movement_enabled,"overview pauses movement")
	scene.toggle_map();check(scene.player.movement_enabled,"closing overview restores movement")
	check(scene.mini.size==Vector2(256,192),"minimap stays within its panel")
	scene.queue_free();await process_frame
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	var progress_before=game.progress.snapshot()
	game.start_wuchang();await process_frame
	check(game.exploration.area_name=="wuchang" and game.state=="explore","title opens playable Wuchang")
	check(game.exploration.travel_exits.any(func(exit):return exit.travel.area=="mountain_road"),"Wuchang title entry connects to southern road")
	check(game.progress.snapshot()==progress_before,"fresh Wuchang exploration starts with normal possessions")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_WUCHANG: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
