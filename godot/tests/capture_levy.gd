extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("nanjing")
	var q=game.levy_quest;var w=game.exploration
	q.phase="suspect";q.refresh_world();game.quest_navigation.track(q.ID,q.stage())
	for a in w.ambient_nodes:
		if a.get_meta("npc_id")==q.SUSPECT:w.player.position=w.safe_player_position(a.position+Vector2(0,100))
	w.camera.snap_to_player();await shot("levy-market")
	game.adventure_ui.open_journal();game.adventure_ui.select_quest(q.ID);await shot("levy-journal");game.adventure_ui.close_menu()
	q.phase="arrest";q._reload_market(true);game.say(q.data.scenes.arrest,q._arrest_done);await shot("levy-arrest")
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	await shot("levy-cleared");game.reset();game.queue_free();await process_frame;quit()
