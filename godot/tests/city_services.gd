extends SceneTree
var failed := false
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_city()
	await process_frame
	var city = game.exploration
	var standards = JSON.parse_string(FileAccess.get_file_as_string("res://data/city_standards.json"))
	for required in standards.required_districts:
		var found := false
		for district in city.city_data.districts:
			if district.category == required.category: found = true
		check(found, "required district: " + required.name)
	check(city.city_data.services.size() == 3, "three service counters")
	for definition in city.city_data.services:
		var actor
		for npc in city.ambient_nodes:
			if npc.get_meta("npc_id") == definition.npc_id: actor = npc
		check(actor != null, "service NPC exists")
		city.player.position = actor.position + Vector2(36, 12)
		check(city.nearest().id == definition.id, "nearby service can be selected")
		var category: String = {"market": "market", "workshop": "workshops", "training": "martial_hall"}[definition.kind]
		var in_district := false
		for district in city.city_data.districts:
			if district.category == category and city._city_rect(district.bounds).has_point(actor.position): in_district = true
		check(in_district, "service stands in corresponding district")
		game.interact()
		check(not game.dialogue_lines.is_empty() and not city.active, "greeting pauses movement")
		check(game.dialogue_cast.portraits.size() == 2, "hero and NPC portraits appear")
		game.advance_dialogue()
		check(game.city_service.visible and game.state == "service" and not city.active, "greeting opens modal service counter")
		for index in range(2):
			game.city_service.tabs[index].pressed.emit()
			check(game.city_service.selected_tab == index, "counter tabs selectable")
		check(definition.items.is_empty(), "no invented goods or prices")
		var key = InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.pressed = true
		game._input(key)
		check(not game.city_service.visible and city.active and game.state == "explore", "escape closes counter and restores movement")
	# Reset from an open counter must discard the overlay and interaction state.
	game.interact()
	game.advance_dialogue()
	game.reset()
	check(not game.city_service.visible and game.state == "title", "reset cleans counter")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_CITY_SERVICES: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
