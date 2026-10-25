extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(3.6).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/artisan-quest-"+name+".png")==OK)
func drain() -> void:
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
func focus(id: String) -> void:
	var world=game.exploration
	for npc in world.ambient_nodes:
		if npc.get_meta("npc_id")!=id:continue
		var path=world.path_to(npc.position,true);assert(not path.is_empty())
		world.player.position=path[-1];world.player.stop();world.camera.snap_to_player();return
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang()
	var q=game.artisan_quest
	focus(q.GIVER);q.talk_giver();drain();await shot("offer")
	game.adventure_ui.primary_action();drain()
	focus(q.FARMER);q.handle_interaction(q.FARMER)
	while game.dialogue_index<6:game.advance_dialogue()
	await shot("farmer");drain()
	focus(q.DOCK);q.handle_interaction(q.DOCK)
	while game.dialogue_index<4:game.advance_dialogue()
	await shot("dock");drain()
	focus(q.GIVER);await shot("ready")
	q.talk_giver();game.advance_dialogue();await shot("report");drain()
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("completed");game.adventure_ui.select_quest(q.ID)
	await shot("completed");game.adventure_ui.close_menu()
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
