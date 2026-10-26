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
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"nanjing","arrival":[810,640]}})
	await shot("nanjing-inn-play")
	var q=game.nanjing_relief_quest
	q.handle_interaction(q.GIVER);await shot("nanjing-lu-dialogue");drain();game.adventure_ui.primary_action();drain()
	q.phase="yeonseo";q.refresh_world();q.track();q.handle_interaction(q.LADY);await shot("nanjing-yeonseo-dialogue");drain()
	q.phase="ready";q.refresh_world();q._paid();drain();q.handle_interaction(q.INNKEEPER);drain()
	game.adventure_ui.open_favor();await shot("nanjing-namgung-favor");game.adventure_ui.close_menu()
	game.city_overview.open_for(game.exploration);await shot("nanjing-overview");game.city_overview.hide()
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/nanjing_map.gd").new();map.scale=Vector2.ONE/3;view.add_child(map)
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/nanjing-full.png")==OK)
	view.queue_free();game.queue_free();await process_frame;quit()
