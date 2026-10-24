extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func drain() -> void:
	while not game.dialogue_lines.is_empty():game.advance_dialogue()
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city();game.money=1000
	for npc in game.exploration.ambient_nodes:
		if npc.name=="vegetable_vendor":game.exploration.player.position=npc.position+Vector2(35,0)
	game.exploration.camera.snap_to_player();await shot("adventure-quest-offer-marker")
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("available");game.adventure_ui.select_quest("changsha_baskets");await shot("adventure-journal-available");game.adventure_ui.close_menu()
	game.ordinary_quests.accept("changsha_baskets");drain();game.ordinary_quests.handle_interaction("general_merchant");drain()
	await shot("adventure-quest-report-marker")
	game.adventure_ui.open_journal();game.adventure_ui.select_quest("changsha_baskets");await shot("adventure-journal-active");game.adventure_ui.close_menu()
	game.toggle_city_map();await shot("adventure-facilities");game.toggle_city_map()
	for service in game.exploration.city_data.services:
		if service.id=="city_artisan":game.state="service";game.city_service.open_counter(service)
	game.city_service.select_item("blue_steel_sword");await shot("adventure-weapon-comparison");game.city_service.close_counter()
	for service in game.exploration.city_data.services:
		if service.id=="city_instructor":game.state="service";game.city_service.open_counter(service)
	game.city_service.select_item("cheongpung");await shot("adventure-art-requirements");game.city_service.close_counter()
	game.settings_menu.open_menu();game.adventure_ui.open_options();await shot("adventure-options");game.adventure_ui.close_menu();game.settings_menu.close_menu()
	game.adventure_ui.open_help();game.adventure_ui.help_topic(1);await shot("adventure-help");game.adventure_ui.close_menu()
	game.start_battle();game.battle.select_basic_attack();game.battle.use_selected()
	while game.battle.busy:await create_timer(.03).timeout
	game.adventure_ui.open_log();await shot("adventure-combat-log");game.adventure_ui.close_menu()
	game.battle.enemy_hp=1;game.battle.select_basic_attack();game.battle.use_selected()
	while game.battle.busy:await create_timer(.03).timeout
	await shot("adventure-combat-result")
	game.adventure_ui.close_menu();game.reset();await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
