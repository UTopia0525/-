extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func drain() -> void:
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
func shot(name: String) -> void:
	game.adventure_ui.toast.hide();await create_timer(.15).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
	game.ordinary_quests.accept("changsha_baskets");drain()
	var npc=game.exploration.ambient_nodes.filter(func(n):return n.get_meta("npc_id")=="vegetable_vendor")[0]
	game.exploration.player.position=game.exploration.safe_player_position(npc.position+Vector2(65,65));game.exploration.camera.snap_to_player()
	await shot("compact-hud-changsha")
	var portal=game.exploration.travel_exits[0];var path=game.exploration.path_to(portal.position,true)
	game.exploration.player.position=path[-1];game.exploration.player.stop();game.exploration.camera.snap_to_player();await physics_frame;await physics_frame
	await shot("compact-hud-locked-road")
	game.start_wuchang();game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([1220,1035]));game.exploration.camera.snap_to_player()
	await shot("compact-hud-wuchang")
	game.reset();await create_timer(.3).timeout
	for v in game.music.players:v.stop();v.stream=null
	for v in game.options.voices:v.stop();v.stream=null
	game.queue_free();await process_frame;quit()
