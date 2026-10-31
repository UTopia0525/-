extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(area: String,name: String,point: Array) -> void:
	var w=game.exploration;w.player.position=w.safe_player_position(w.city_point(point));w.player.stop();w.camera.snap_to_player()
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+area+"-country-"+name+".png")==OK)
func full(area: String) -> void:
	var d=game.exploration.city_data;var size=Vector2i(d.art_size[0],d.art_size[1]);root.size=size;root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;game.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=size;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/nanjing_map.gd").new();map.scale=Vector2.ONE/4;view.add_child(map)
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	map.actors.hide();await process_frame;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://assets/maps/nanjing/painted/overview-floor.png")==OK)
	map.actors.show()
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/"+area+"-country-full.png")==OK)
	view.queue_free();await process_frame;game.show();root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(1280,720)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
	game.exploration.load_area("nanjing");game.exploration.set_active(true)
	for spot in [["north-farms",[1070,205]],["east-farms",[1708,650]],["west-farm",[120,825]],["north-wall",[900,330]]]:await shot("nanjing",spot[0],spot[1])
	var w=game.exploration
	w.camera.exploration_zoom=.45;w.camera.set_focus_height(600);w.camera.set_map_bounds(w.map_bounds)
	await shot("nanjing","north-wide",[1065,230])
	w.camera.exploration_zoom=.8;w.camera.set_focus_height(36);w.camera.set_map_bounds(w.map_bounds)
	await full("nanjing")
	game.queue_free();await process_frame;print("NANJING_COUNTRY_CAPTURE: PASS");quit()
