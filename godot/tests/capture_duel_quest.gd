extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(3.6).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/duel-quest-"+name+".png")==OK)
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
	var q=game.duel_quest
	focus(q.GIVER);q.talk_giver();drain();await shot("offer")
	game.adventure_ui.primary_action();drain();focus(q.STUDENT);await shot("student")
	q.handle_interaction(q.STUDENT);drain();game.adventure_ui.primary_action();await shot("battle")
	# Capture stage transitions with a deterministic final exchange, not balance data.
	game.battle.enemy_hp=1;game.battle.select_basic_attack();game.battle.use_selected()
	while game.battle.busy:await create_timer(.04).timeout
	drain();focus(q.GIVER);q.talk_giver();game.advance_dialogue();await shot("teaching");drain()
	game.player_menu.open_menu("martial");game.player_menu.select_item("josik_suwon");await shot("martial-menu")
	game.progress.assign("josik_suwon",3);game.player_menu.close_menu()
	game.start_battle(game.bandit_story.data.encounters[0]);game.battle.select_skill("josik_suwon");await shot("skill")
	game.battle.use_selected()
	while game.battle.busy:await create_timer(.04).timeout
	game.battle.select_skill("josik_suwon");await shot("cooldown")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
