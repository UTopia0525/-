extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.1).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func hover(button: Button) -> void:
	var event:=InputEventMouseMotion.new();event.position=button.get_global_rect().get_center();event.global_position=event.position
	root.push_input(event,true);await process_frame;await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	await shot("ink-title")
	game.start_story()
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
	game.say(game.prologue.lines("captain"));game.dialogue_index=4;game._show_line()
	await shot("ink-dialogue")
	game.start_battle()
	game.battle.enemy_intent="bandit_heavy_chop";game.battle._update_intent()
	game.battle.select_samjae();await hover(game.battle.skill_buttons[2])
	await shot("ink-battle-hover")
	game.reset();game.start_city();game.money=3000
	game.player_menu.open_menu("inventory");await process_frame
	await hover(game.player_menu.rows.get_child(1));await shot("ink-inventory-hover")
	game.player_menu.switch_mode("martial");await process_frame
	await hover(game.player_menu.rows.get_child(2));await shot("ink-martial-hover")
	game.player_menu.close_menu()
	for definition in game.exploration.city_data.services:
		if definition.id=="city_artisan":game.state="service";game.city_service.open_counter(definition)
	await process_frame;await hover(game.city_service.rows.get_child(0));await shot("ink-shop-hover")
	game.reset();await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
