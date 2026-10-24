extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.35).timeout
	game.adventure_ui.pending_toasts.clear()
	if game.adventure_ui.toast_tween:game.adventure_ui.toast_tween.kill()
	game.adventure_ui.toast.hide();await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func drain() -> void:
	for i in range(50):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
func face(id: String) -> void:
	var w=game.exploration;var npc=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==id)[0]
	w.player.position=w.safe_player_position(npc.position+Vector2(0,60));w.player.stop();w.camera.snap_to_player();await physics_frame
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.options.seen.append("city");game.start_wuchang();var w=game.exploration
	w.player.position=w.city_point([1480,942]);w.player.stop();w.camera.snap_to_player();await shot("alliance-guard-posts")
	await face("alliance_guard_left");game.interact();await shot("alliance-guard-refusal");drain()
	game.alliance_visit.grant_visit() # isolated future-visit fixture; never an in-game unlock
	await face("gwak_jinseok");await shot("alliance-instructor-post");game.interact();await shot("alliance-instructor-dialogue");drain()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"alliance_office","arrival":[256,289]}})
	await face("heo_mungyu");await shot("alliance-steward-post");game.interact();await shot("alliance-steward-dialogue");drain()
	game.alliance_visit.mark_training_complete()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"wuchang","arrival":[1480,945]}});await process_frame;await physics_frame
	await face("alliance_guard_right");game.interact();await shot("alliance-guard-return-refusal");drain()
	game.reset();await create_timer(.2).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
