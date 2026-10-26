extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("nanjing")
	var q=game.silk_quest
	for a in game.exploration.ambient_nodes:
		if a.get_meta("npc_id")==q.GIVER:game.exploration.player.position=game.exploration.safe_player_position(a.position+Vector2(0,65))
	game.exploration.camera.snap_to_player();q.handle_interaction(q.GIVER);await shot("silk-intro")
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	game.adventure_ui.close_menu();q.phase="chest";q.refresh_world();game.quest_navigation.track(q.ID,q.stage())
	for o in game.exploration.objectives:
		if o.id==q.CHEST:game.exploration.player.position=game.exploration.safe_player_position(o.position+Vector2(0,65))
	game.exploration.camera.snap_to_player();game.exploration.set_active(true);await shot("silk-chest")
	q.phase="ready";q.refresh_world();game.adventure_ui.open_journal();game.adventure_ui.select_quest(q.ID);await shot("silk-journal-items")
	game.adventure_ui.close_menu();q._begin_approval();await shot("silk-time-cut");game.reset();game.queue_free();await process_frame;quit()
