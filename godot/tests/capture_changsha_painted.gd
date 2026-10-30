extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
	for spot in [["market",[515,440]],["workshops",[640,650]],["harbor",[530,240]],["housing",[430,670]],["martial",[950,650]],["farm",[1330,510]]]:
		var w=game.exploration;w.player.position=w.safe_player_position(w.city_point(spot[1]));w.player.stop();w.camera.snap_to_player()
		await create_timer(.25).timeout;await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://screenshots/changsha-painted-"+spot[0]+".png")==OK)
	root.size=Vector2i(2560,1440);await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/changsha-painted-1440p.png")==OK)
	root.size=Vector2i(1536,1024);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;game.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var data=game.exploration.city_data
	var floor=Sprite2D.new();floor.centered=false;floor.texture=load(data.ground_texture);floor.scale=Vector2(1536,1024)/floor.texture.get_size();floor.material=preload("res://scripts/changsha_painted_ground.gd").make(data);view.add_child(floor)
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://assets/maps/changsha/painted/overview-floor.png")==OK)
	var prefabs=JSON.parse_string(FileAccess.get_file_as_string(data.prefabs_path))
	var actors=Node2D.new();actors.y_sort_enabled=true;view.add_child(actors)
	for spec in data.objects:
		var node=load("res://scripts/city_scenery.gd").new();node.configure(spec,prefabs[spec.prefab],Vector2.ONE);actors.add_child(node)
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/changsha-painted-full.png")==OK)
	view.queue_free();game.queue_free();await process_frame;print("CHANGSHA_PAINTED_CAPTURE: PASS");quit()
