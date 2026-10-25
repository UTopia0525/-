extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(3.6).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/impostor-quest-"+name+".png")==OK)
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
	# Fixture for the unconnected teaching story; never opens a runtime bypass.
	game.progress.learned.append("hoeryu");game.alliance_visit.grant_visit();game.alliance_visit.mark_training_complete()
	var q=game.impostor_quest;q.refresh_world()
	focus(q.GIVER);q.handle_interaction(q.GIVER);drain();await shot("offer")
	game.adventure_ui.primary_action();drain();focus(q.WITNESS);q.handle_interaction(q.WITNESS);drain()
	focus(q.GIVER);q.handle_interaction(q.GIVER);drain();focus(q.SUSPECT);await shot("suspect")
	q.handle_interaction(q.SUSPECT);drain();await shot("battle")
	# One finishing blow captures transition; balance is tested independently.
	game.battle.enemy_hp=1;game.battle.select_basic_attack();game.battle.use_selected()
	while game.battle.busy:await create_timer(.04).timeout
	drain();focus(q.GIVER);q.handle_interaction(q.GIVER)
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	game.advance_dialogue();await shot("thanks")
	drain();game.player_menu.open_menu("inventory");await shot("favor")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
