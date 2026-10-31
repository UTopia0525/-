extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(area: String,name: String,point: Array) -> void:
	var w=game.exploration;w.player.position=w.safe_player_position(w.city_point(point));w.player.stop();w.camera.snap_to_player()
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+area+"-fortified-"+name+".png")==OK)
func full(area: String) -> void:
	var d=game.exploration.city_data;var size=Vector2i(d.art_size[0],d.art_size[1]);root.size=size;root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;game.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=size;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map
	if area=="changsha":
		var floor=Sprite2D.new();floor.centered=false;floor.texture=load(d.ground_texture);floor.scale=Vector2(size)/floor.texture.get_size();floor.material=preload("res://scripts/changsha_painted_ground.gd").make(d);view.add_child(floor)
		await create_timer(.2).timeout;await RenderingServer.frame_post_draw
		assert(view.get_texture().get_image().save_png("res://assets/maps/changsha/painted/overview-floor.png")==OK)
		var pf=JSON.parse_string(FileAccess.get_file_as_string(d.prefabs_path));pf.merge(d.get("prefabs",{}),true)
		var actors=Node2D.new();actors.y_sort_enabled=true;view.add_child(actors)
		for spec in d.objects:
			var node=load("res://scripts/city_scenery.gd").new();node.configure(spec,pf[spec.prefab],Vector2.ONE);actors.add_child(node)
	else:
		map=load("res://scripts/"+area+"_map.gd").new();map.scale=Vector2.ONE/4;view.add_child(map)
		await create_timer(.25).timeout;await RenderingServer.frame_post_draw
		map.actors.hide();await process_frame;await RenderingServer.frame_post_draw
		assert(view.get_texture().get_image().save_png("res://assets/maps/"+area+"/painted/overview-floor.png")==OK)
		map.actors.show()
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/"+area+"-fortified-full.png")==OK)
	view.queue_free();await process_frame;game.show();root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(1280,720)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
	for area in ["changsha","wuchang","nanjing"]:
		game.exploration.load_area(area);game.exploration.set_active(true)
		var spots={"changsha":[["east-gate",[1220,510]],["water-gate",[320,460]]],"wuchang":[["south-gate",[1100,1475]],["east-gate",[2010,945]]],"nanjing":[["palace",[900,350]],["avenue",[900,875]],["west-gate",[180,830]],["east-gate",[1780,1295]]]}[area]
		for spot in spots:await shot(area,spot[0],spot[1])
		var w=game.exploration
		w.camera.exploration_zoom=.45 if area=="nanjing" else .55
		w.camera.set_focus_height(600 if area=="nanjing" else 300);w.camera.set_map_bounds(w.map_bounds)
		await shot(area,"palace-wide" if area=="nanjing" else "gate-wide",[900,350] if area=="nanjing" else [1100,1475] if area=="wuchang" else [1220,510])
		w.camera.exploration_zoom=.8;w.camera.set_focus_height(36);w.camera.set_map_bounds(w.map_bounds)
		await full(area)
	game.queue_free();await process_frame;print("CITY_FORTS_CAPTURE: PASS");quit()
