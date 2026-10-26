extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","battle"])
	game.start_wuchang();game.qingya_quest.phase="fight_chief";game.start_battle(game.qingya_quest.data.encounters[1])
	game.battle.player_hp=0;game.battle._update_hp(true);game._on_defeat()
	await create_timer(.5).timeout;await shot("death-fall")
	while not game.death_screen.ready_to_return:await process_frame
	await shot("death-screen")
	game.death_screen.return_to_title();await create_timer(.2).timeout;await shot("death-title")
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
