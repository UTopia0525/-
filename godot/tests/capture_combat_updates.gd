extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city();game.money=3000
	game.player_menu.open_menu("inventory")
	await shot("icons-inventory")
	game.player_menu.switch_mode("martial");game.player_menu.select_item("samjae")
	await shot("icons-martial")
	game.player_menu.close_menu()
	for service in game.exploration.city_data.services:
		if service.id=="city_artisan":
			game.state="service";game.city_service.open_counter(service)
	await shot("icons-workshop")
	game.city_service.dismiss()
	game.start_battle(game.bandit_story.data.encounters[1])
	game.battle.select_skill("samjae")
	await shot("combat-intent")
	game.battle.turn=4;game.battle.enemy_qi.restore(8,32);game.battle._prepare_enemy();game.battle._update_hp()
	game.battle.select_skill("basic_defense")
	await shot("combat-heavy-intent")
	game.reset();await create_timer(1.0).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
