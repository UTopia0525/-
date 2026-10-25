extends SceneTree
## Exercise real dispatch with logical-only and Korean physical F events.
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("F_INTERACTION: "+message)
func press(physical: int=0,logical: int=KEY_F,echo: bool=false) -> void:
	var event=InputEventKey.new();event.keycode=logical;event.physical_keycode=physical;event.pressed=true;event.echo=echo
	Input.parse_input_event(event);await process_frame
	event=event.duplicate();event.pressed=false;event.echo=false;Input.parse_input_event(event);await process_frame
func drain() -> void:
	for i in range(160):
		if game.dialogue_lines.is_empty():return
		await press()
	check(false,"logical-only F advances dialogue")
func approach(point: Vector2,id: String) -> void:
	var w=game.exploration;var path=w.path_to(point,true)
	check(not path.is_empty(),"reachable target: "+id)
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id","")==id,"F prompt selects target: "+id)
func actor(id: String):
	for npc in game.exploration.ambient_nodes:
		if npc.get_meta("npc_id")==id:return npc
	return null
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"])
	game.start_story()
	await drain();check(game.exploration.active,"opening permits movement")
	game.exploration.player.position=Vector2(640,395);await physics_frame;await physics_frame
	check(game.exploration.nearest().get("id")=="captain","captain prompt")
	await press(0,KEY_E);check(game.dialogue_lines.is_empty(),"E remains inactive")
	await press();check(not game.dialogue_lines.is_empty(),"logical-only F starts captain dialogue")
	var before: int=game.dialogue_index
	await press(0,KEY_F,true);check(game.dialogue_index==before,"held F repeat cannot skip lines")
	await drain();check(game.talked_captain,"logical-only F completes captain dialogue")
	game.start_city();await physics_frame;await physics_frame
	await approach(actor("city_merchant").position,"city_merchant")
	game.settings_menu.open_menu();await press();check(game.dialogue_lines.is_empty(),"F cannot interact behind settings");game.settings_menu.close_menu()
	await press();check(not game.dialogue_lines.is_empty(),"logical-only F starts city service conversation")
	await drain();check(game.city_service.visible,"logical-only F opens real shop")
	await press();check(game.city_service.visible and game.dialogue_lines.is_empty(),"F does not interact behind shop")
	game.city_service.close_counter()
	var portal=game.exploration.travel_exits[0]
	await approach(portal.position,portal.id);await press()
	check(game.exploration.area_name=="mountain_road","logical-only F travels from Changsha")
	for entry in game.exploration.travel_exits:
		if entry.id=="travel:wuchang":portal=entry;break
	await approach(portal.position,portal.id);await press()
	check(game.exploration.area_name=="wuchang","logical-only F reaches Wuchang")
	await approach(actor(game.plaque_quest.GIVER).position,game.plaque_quest.GIVER)
	await press(KEY_F,0x3139);check(not game.dialogue_lines.is_empty(),"physical F with Korean logical code still works")
	await drain();check(game.adventure_ui.mode=="choice" and game.adventure_ui.window.visible,"quest requires explicit acceptance")
	await press();check(game.plaque_quest.phase=="available" and game.adventure_ui.window.visible,"F cannot accept a quest choice accidentally")
	game.adventure_ui.secondary_action();await drain()
	game.adventure_ui.open_shell("log");await press(KEY_F,0x3139)
	check(not game.adventure_ui.window.visible and not paused,"Korean physical F closes combat log")
	game.reset();await create_timer(.3).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_F_INTERACTION: "+("FAIL" if failed else "PASS — logical/physical/Korean F, dialogue, cities, portals, modal guards"));quit(1 if failed else 0)
