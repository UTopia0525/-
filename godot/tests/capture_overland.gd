extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append("city");game.start_city();var world=game.exploration
	world.player.position=world.travel_exits[0].position;world.camera.snap_to_player();await shot("overland-changsha-exit")
	game.toggle_city_map();await shot("portal-changsha-farmland-map");game.toggle_city_map()
	game.interact();await process_frame
	await shot("overland-road-west")
	world.player.position=world.city_point([720,1175]);world.player.stop();world.camera.snap_to_player();await shot("overland-east-turn")
	world.player.position=world.city_point([630,700]);world.player.stop();world.camera.snap_to_player();await shot("overland-mountain-pass")
	await create_timer(3.6).timeout
	game.toggle_city_map();await shot("overland-overview");game.toggle_city_map()
	world.player.position=world.travel_exits[1].position;world.player.stop();world.camera.snap_to_player();await shot("portal-road-north")
	game.interact();await process_frame;await shot("overland-wuchang-arrival")
	world.player.position=world.travel_exits[0].position+Vector2(65,-10);world.player.stop();world.camera.snap_to_player();await create_timer(3.6).timeout;await shot("portal-wuchang-south")
	game.toggle_city_map();await shot("portal-wuchang-farmland-map");game.toggle_city_map()
	var viewport=SubViewport.new();viewport.world_2d=World2D.new();viewport.size=Vector2i(1024,1280);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var map=load("res://scripts/mountain_road_map.gd").new();map.scale=Vector2.ONE*.25;viewport.add_child(map)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://screenshots/overland-full-map.png")==OK)
	viewport.queue_free();game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
