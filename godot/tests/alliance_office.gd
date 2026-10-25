extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func press_f() -> void:
	var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=true;Input.parse_input_event(e);await process_frame
	e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=false;Input.parse_input_event(e);await physics_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_wuchang();await physics_frame
	game.alliance_visit.grant_visit() # authorized-visit fixture; invitation is connected later
	var w=game.exploration
	var progress=game.progress.snapshot();var money=game.money
	var portal=w.travel_exits.filter(func(e):return e.travel.area=="alliance_office")[0]
	assert(w.can_stand(portal.position));assert(not w.path_to(portal.position).is_empty())
	w.player.position=portal.position;w.player.stop();await physics_frame;await create_timer(.06).timeout;await press_f()
	assert(w.area_name=="alliance_office");assert(w.player.display_height==140);assert(w.ambient_nodes.size()==1);assert(w.can_stand(w.player.position))
	assert(w.scenery_nodes.size()==11)
	for furniture in w.scenery_nodes:
		assert(not furniture.collision_rects.is_empty());assert(not w.can_stand(furniture.collision_rects[0].get_center()))
	assert(not w.path_to(w.city_point([256,180])).is_empty());assert(not w.path_to(w.travel_exits[0].position).is_empty())
	game.toggle_city_map();assert(game.city_overview.visible);game.toggle_city_map()
	assert(game.save_system.write_slot(1));assert(game.save_system.load_slot(1));await physics_frame
	assert(w.area_name=="alliance_office" and w.can_stand(w.player.position))
	if "--capture" in OS.get_cmdline_user_args():
		root.size=Vector2i(1280,720);w.player.position=w.city_point([256,222]);w.camera.snap_to_player()
		await create_timer(.3).timeout;await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://screenshots/alliance-office-interior.png")==OK)
		game.toggle_city_map();await create_timer(.3).timeout;await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://screenshots/alliance-office-map.png")==OK);game.toggle_city_map()
	w.player.position=w.travel_exits[0].position;w.player.stop();await physics_frame;await create_timer(.06).timeout;await press_f()
	assert(w.area_name=="wuchang" and w.can_stand(w.player.position));assert(w.ambient_nodes.size()==12)
	assert(game.money==money);assert(JSON.parse_string(JSON.stringify(game.progress.snapshot()))==JSON.parse_string(JSON.stringify(progress)))
	print("ALLIANCE OFFICE PASS: F round trip, furniture collision, pathfinding, map, save/load, unchanged progress")
	game.free();quit()
