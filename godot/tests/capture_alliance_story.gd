extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(3.6).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/alliance-story-"+name+".png")==OK)
func drain() -> void:
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
func focus(id: String) -> void:
	var w=game.exploration
	for npc in w.ambient_nodes:
		if npc.get_meta("npc_id")!=id:continue
		var path=w.path_to(npc.position,true);assert(not path.is_empty())
		w.player.position=path[-1];w.player.stop();w.camera.snap_to_player();return
func travel(area: String,point: Array) -> void:
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":area,"arrival":point}})
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
	# Fixture starts after the already-tested campaign report; no runtime bypass.
	game.bandit_story.stage="completed";game.bandit_story.reward_granted=true;game.money=500;game.progress.fame=5
	for key in game.progress.stats:game.progress.stats[key]=20
	var q=game.alliance_story;q.maybe_start();await shot("invitation");drain()
	travel("wuchang",[1480,990]);focus("alliance_guard_left");q.handle_interaction("alliance_guard_left");await shot("identity")
	while not q.vouching:game.advance_dialogue()
	await shot("guarantee");drain()
	travel("alliance_office",[256,289]);focus("heo_mungyu");q.handle_interaction("heo_mungyu");await shot("steward");drain()
	travel("wuchang",[1370,690]);focus("gwak_jinseok");q.handle_interaction("gwak_jinseok");drain()
	game.adventure_ui.select_teaching("gwanak");await shot("selection")
	game.adventure_ui.primary_action();await shot("confirmation");game.adventure_ui.primary_action();await shot("teaching");drain()
	game.player_menu.open_menu("martial");game.player_menu.select_item("gwanak");await shot("learned");game.player_menu.close_menu()
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
