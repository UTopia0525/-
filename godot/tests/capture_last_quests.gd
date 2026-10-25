extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(3.6).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/last-quests-"+name+".png")==OK)
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
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var p=game.plaque_quest;var g=game.grain_quest
	p.accept();drain();focus(p.MANAGER);p.handle_interaction(p.MANAGER);drain();await shot("timber")
	var door=game.exploration.objectives.filter(func(e):return e.id==p.PREFIX+"door")[0]
	game.exploration.player.position=game.exploration.safe_player_position(door.position+Vector2(0,55));game.exploration.player.stop();game.exploration.camera.snap_to_player()
	p.handle_interaction(p.PREFIX+"door");await shot("plaque-found");drain();focus(p.GIVER);p.handle_interaction(p.GIVER);drain();await shot("plaque-home")
	g.accept();drain();g.talk_giver();drain();g.handle_interaction(g.CLERK);drain();g.handle_interaction(g.OFFICER);game.adventure_ui.primary_action();drain()
	focus(g.COLLECTOR);g.handle_interaction(g.COLLECTOR);await shot("grain-hearing");drain()
	focus(g.GIVER);g.handle_interaction(g.GIVER);drain();game.adventure_ui.open_journal();game.adventure_ui.set_filter("completed");game.adventure_ui.select_quest(g.ID);await shot("grain-completed")
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
