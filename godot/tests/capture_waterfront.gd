extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("nanjing")
	var q=game.waterfront_quest;var w=game.exploration
	q.phase="rope";q.refresh_world();game.quest_navigation.track(q.ID,q.stage());w.player.position=w.safe_player_position(w.city_point(q.data.rope_point)+Vector2(80,45));w.camera.snap_to_player();await shot("waterfront-rope")
	q.phase="confront";q.refresh_world();w.set_active(false)
	for a in w.ambient_nodes:
		if a.get_meta("npc_id")==q.SUSPECT:w.player.position=w.safe_player_position(a.position+Vector2(0,110))
	w.camera.snap_to_player();q._confront();await shot("waterfront-confront")
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	await shot("waterfront-battle");q.after_victory()
	for i in range(4):game.advance_dialogue()
	await shot("waterfront-aftermath")
	game.reset();game.queue_free();await process_frame;quit()
