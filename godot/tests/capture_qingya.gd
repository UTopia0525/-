extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func full(area: String,ruined: bool,name: String) -> void:
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/qingya_map.gd").new(area,ruined);map.scale=Vector2.ONE/3;view.add_child(map)
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
	view.queue_free();await process_frame
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"qingya_hamlet","arrival":[900,590]}})
	game.adventure_ui.toast.hide();await shot("qingya-hamlet-play")
	game.qingya_quest.handle_interaction("qy_ren_shoutian");await shot("qingya-quest-intro")
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	game.adventure_ui.close_menu()
	await full("qingya_hamlet",false,"qingya-hamlet-full")
	await full("qingya_camp",false,"qingya-camp-full")
	await full("qingya_hamlet",true,"qingya-hamlet-ruined")
	game.reset();await create_timer(.2).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
