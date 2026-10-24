extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.3).timeout
	game.adventure_ui.pending_toasts.clear()
	if game.adventure_ui.toast_tween:game.adventure_ui.toast_tween.kill()
	game.adventure_ui.toast.hide()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.options.seen.append("city");game.start_city()
	for stat in game.progress.stats:game.progress.stats[stat]=20
	for id in ["hoeryu","paak","gwanak","banseok","jungun"]:game.progress.learned.append(id)
	game.progress.loadout=["basic_attack","hoeryu","gwanak","jungun"]
	game.player_menu.open_menu("martial");game.player_menu.select_item("gwanak");await shot("alliance-arts-k-menu");game.player_menu.close_menu()
	game.start_battle();game.battle.qi.amount=100;game.battle.select_skill("hoeryu");await shot("alliance-arts-battle")
	game.reset();await create_timer(.2).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
