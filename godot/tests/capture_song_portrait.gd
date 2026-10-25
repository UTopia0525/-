extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String,existing: String) -> void:
	await create_timer(2).timeout;await RenderingServer.frame_post_draw
	var frame=root.get_texture().get_image()
	assert(frame.save_png("res://screenshots/song-portrait-"+name+".png")==OK)
	assert(frame.save_png("res://screenshots/"+existing+".png")==OK)
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
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
	game.bandit_story.stage="completed";game.bandit_story.reward_granted=true;game.money=500;game.progress.fame=5
	var story=game.alliance_story;story.maybe_start();await shot("invitation","alliance-story-invitation");drain()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"wuchang","arrival":[1480,990]}})
	focus("alliance_guard_left");story.handle_interaction("alliance_guard_left")
	while not story.vouching:game.advance_dialogue()
	await shot("guarantee","alliance-story-guarantee");drain()
	# Separate completed-teaching fixture isolates the existing gratitude scene.
	game.progress.learned.append("hoeryu");story.stage_id="completed";story.received_art="hoeryu";game.alliance_visit.phase="closed"
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"wuchang","arrival":[1850,1240]}})
	var q=game.impostor_quest;q.phase="thanks";q.refresh_world();focus(q.GIVER);game.money=250;q._thank_you()
	await shot("thanks","impostor-quest-thanks");drain()
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
