extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_battle(game.bandit_story.data.encounters[1])
	var b=game.battle
	for type in ["sword","saber","spear","none"]:
		b.equip_weapon(type)
		await create_timer(.1).timeout
		await shot("battle-ready-"+type)
	b.equip_weapon("sword")
	b.enemy_qi.restore(8,32);b.turn=4;b._prepare_enemy();b._update_hp()
	b.select_samjae();b.use_selected()
	await create_timer(.20).timeout
	await shot("battle-player-attack")
	await create_timer(.29).timeout
	await shot("battle-enemy-hit-trail")
	await create_timer(.73).timeout
	await shot("battle-enemy-attack")
	await create_timer(.38).timeout
	await shot("battle-player-hit-trail")
	game.reset();await create_timer(1).timeout
	for voice in game.music.players: voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
