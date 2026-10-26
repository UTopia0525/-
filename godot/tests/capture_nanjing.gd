extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func drain() -> void:
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	game.progress.learned.append("gwanak");game.alliance_story.stage_id="completed";game.alliance_story.received_art="gwanak";game.alliance_visit.phase="training_complete"
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"nanjing","arrival":[870,735]}})
	await shot("nanjing-inn-play")
	var city=SubViewport.new();city.world_2d=World2D.new();city.size=Vector2i(1536,1024);city.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(city)
	var city_map=load("res://scripts/nanjing_map.gd").new();city_map.scale=Vector2.ONE/4;city.add_child(city_map)
	for citizen in game.exploration.ambient_nodes:city_map.actors.add_child(citizen.duplicate())
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(city.get_texture().get_image().save_png("res://screenshots/nanjing-city-life.png")==OK)
	city.queue_free()
	for district in [["market",[885,510]],["craft",[392,430]],["government",[1210,495]],["waterfront",[1320,958]]]:
		game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point(district[1]));game.exploration.player.stop();game.exploration.camera.snap_to_player()
		await shot("nanjing-"+str(district[0])+"-play")
	game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([870,735]));game.exploration.camera.snap_to_player()
	var q=game.nanjing_relief_quest
	q.handle_interaction(q.GIVER);await shot("nanjing-lu-dialogue");drain();game.adventure_ui.primary_action();drain()
	q.phase="yeonseo";q.refresh_world();q.track();q.handle_interaction(q.LADY);await shot("nanjing-yeonseo-dialogue");drain()
	q.phase="ready";q.refresh_world();q._paid();drain();q.handle_interaction(q.INNKEEPER);drain()
	game.adventure_ui.open_favor();await shot("nanjing-namgung-favor");game.adventure_ui.close_menu()
	game.city_overview.open_for(game.exploration);await shot("nanjing-overview");game.city_overview.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/nanjing_map.gd").new();map.scale=Vector2.ONE/4;view.add_child(map)
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/nanjing-full.png")==OK)
	view.queue_free();game.queue_free();await process_frame;quit()
