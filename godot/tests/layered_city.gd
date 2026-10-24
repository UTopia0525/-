extends SceneTree
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok: failed = true;push_error("LAYERED_CITY: "+message)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city();await physics_frame;await physics_frame
	var city=game.exploration
	check(city.scenery_nodes.size()==city.city_data.objects.size() and city.scenery_nodes.size()>100,"all props are separate depth-sorted physics objects")
	check(city.background.texture.resource_path.ends_with("layered/ground.png"),"ground has no baked architecture")
	check(city.art_tiles.size()==city.scenery_nodes.size(),"minimap reuses all live architecture")
	for node in city.scenery_nodes:
		check(node.get_parent()==city.decorations and node.position.y==node.visual_rect.end.y,"foot-based Y sort: "+node.name)
		for bounds in node.collision_rects:
			var query:=PhysicsPointQueryParameters2D.new();query.position=bounds.get_center();query.collision_mask=2
			var hits=city.get_world_2d().direct_space_state.intersect_point(query)
			check(hits.any(func(hit):return hit.collider==node),"native object collision: "+node.name)
		if node.get_meta("kind")=="gate":
			var rect: Rect2=node.visual_rect
			var start:=Vector2(rect.get_center().x,rect.end.y+40)
			var motion:=Vector2(0,-rect.size.y*.45-40)
			check(not city.player.test_move(Transform2D(0,start),motion),"open central passage: "+node.name)
			for foot in node.collision_rects:
				check(city.player.test_move(Transform2D(0,foot.get_center()+Vector2(0,80)),Vector2(0,-80)),"solid pillar: "+node.name)
	for npc in city.ambient_nodes:
		check(city.can_stand(npc.position,city.CITIZEN_RADIUS,false),"NPC has safe physical ground: "+npc.name)
		var body:=Rect2(npc.position+city.CITIZEN_BOUNDS.position,city.CITIZEN_BOUNDS.size)
		for bounds in city.scenery_bounds:check(not body.grow(6).intersects(bounds),"NPC image clear of architecture: "+npc.name)
		check(not city.path_to(npc.position,true).is_empty(),"reachable resident: "+npc.name)
	for landmark in city.city_data.landmarks:
		check(city.point_is_walkable(city.city_point(landmark.point)),"clear landmark: "+landmark.name)
	game.reset();check(city.scenery_nodes.is_empty(),"city objects removed on map change")
	await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_LAYERED_CITY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
