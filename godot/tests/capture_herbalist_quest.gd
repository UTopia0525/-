extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(id: String) -> void:
	await create_timer(3.6).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/herbalist-"+id+".png")==OK)
func drain() -> void:
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
func focus(point: Vector2) -> void:
	game.exploration.player.position=game.exploration.safe_player_position(point)
	game.exploration.player.stop();game.exploration.camera.snap_to_player()
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	await create_timer(1).timeout
	var world=game.exploration;var q=game.herbalist_quest
	focus(world.decorations.get_node(q.GIVER).position+Vector2(45,30))
	await shot("offer")
	q.accept();drain();world.load_area("mountain_road");world.set_active(true)
	focus(world.city_point(q.data.clue_point)+Vector2(0,-55))
	await shot("clue")
	q.handle_interaction(q.CLUE);drain()
	focus(world.city_point(q.data.encounter_point)+Vector2(0,80))
	await shot("encounter")
	q.handle_interaction("herb_gatherer")
	await shot("dialogue");drain()
	await shot("battle")
	# Capture the actual return/report layout using a deterministic winning exchange.
	game.battle.enemy_hp=1;game.battle.select_basic_attack();game.battle.use_selected()
	while game.battle.busy:await create_timer(.04).timeout
	drain();world.load_area("wuchang");world.set_active(true)
	focus(world.decorations.get_node(q.GIVER).position+Vector2(45,40))
	await shot("return")
	q.talk_giver();await shot("report")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
