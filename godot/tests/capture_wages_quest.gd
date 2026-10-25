extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(3.6).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/wages-quest-"+name+".png")==OK)
func drain() -> void:
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
func focus(id: String) -> void:
	var w=game.exploration
	for npc in w.ambient_nodes:
		if npc.get_meta("npc_id")!=id:continue
		var path=w.path_to(npc.position,true);assert(not path.is_empty())
		w.player.position=path[-1];w.player.stop();w.camera.snap_to_player();return
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();await create_timer(.2).timeout
	var q=game.wages_quest
	focus(q.CLERK);await shot("clerk")
	focus(q.GIVER);q.handle_interaction(q.GIVER);drain();await shot("offer")
	game.adventure_ui.primary_action();drain()
	var w=game.exploration;var entry=w.objectives.filter(func(e):return e.id==q.BOARD)[0]
	w.player.position=w.safe_player_position(entry.position+Vector2(0,55));w.player.stop();w.camera.snap_to_player();await shot("work-board")
	q.handle_interaction(q.BOARD);await shot("inspection");drain()
	focus(q.CLERK);q.handle_interaction(q.CLERK);await shot("ledger");drain();await shot("correction")
	game.adventure_ui.primary_action();drain();focus(q.GIVER);q.handle_interaction(q.GIVER);await shot("report");drain()
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("completed");game.adventure_ui.select_quest(q.ID);await shot("completed")
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
