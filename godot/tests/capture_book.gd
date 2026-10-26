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
	var q=game.book_quest
	for a in game.exploration.ambient_nodes:
		if a.get_meta("npc_id")==q.GIVER:game.exploration.player.position=game.exploration.safe_player_position(a.position+Vector2(0,65))
	game.exploration.camera.snap_to_player();q.phase="ready";q.handle_interaction(q.GIVER)
	for i in range(5):game.advance_dialogue()
	await shot("book-reward")
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	game.player_menu.open_menu("inventory");game.player_menu.select_category("manual");game.player_menu.select_item("swaerang_manual");await shot("book-inventory")
	game.player_menu.apply_selection();game.player_menu.switch_mode("martial");game.player_menu.select_item("swaerang");await shot("book-learned")
	game.reset();game.queue_free();await process_frame;quit()
