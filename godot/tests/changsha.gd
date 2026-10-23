extends SceneTree

var failed := false
var game

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("CHANGSHA TEST: " + message)

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var started = Time.get_ticks_msec()
	game.start_city()
	print("City load time: %d ms" % (Time.get_ticks_msec() - started))
	await process_frame
	var city = game.exploration
	check(city.map_bounds.size == Vector2(6144, 4096), "large continuous city bounds")
	check(city.active and game.state == "explore", "city starts as free exploration")
	check(city.point_is_walkable(city.player.position), "spawn on street")
	check(city.ambient_nodes.size() == 30 and city.npcs.is_empty(), "ambient residents without quests or dialogue triggers")
	var origin = Vector2i(city.player.position / 20.0)
	for landmark in city.city_data.landmarks:
		var point = city.city_point(landmark.point)
		var destination = Vector2i(point / 20.0)
		check(city.point_is_walkable(point), "walkable landmark: " + landmark.name)
		check(not city.astar.get_point_path(origin, destination).is_empty(), "reachable landmark: " + landmark.name)
	for citizen in city.ambient_nodes:
		check(city.point_is_walkable(citizen.position), "residents stand on ground")
	for point in [[100, 500], [850, 315], [1240, 160], [960, 800]]:
		check(not city.point_is_walkable(city.city_point(point)), "river, roofs, paddies and garden obstacles blocked")
	var before = city.player.position
	Input.action_press("move_right")
	await create_timer(0.25).timeout
	Input.action_release("move_right")
	check(city.player.position.x > before.x + 20, "WASD movement along city boulevard")
	check(String(city.player.sprite.animation).begins_with("walk_"), "walking animation retained")
	var click = InputEventMouseButton.new()
	click.position = city.get_global_transform_with_canvas() * (city.player.position + Vector2(130, 0))
	click.global_position = click.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	before = city.player.position
	root.push_input(click, true)
	await create_timer(0.2).timeout
	check(city.player.position.x > before.x + 10, "click movement works on scrolling city map")
	game.toggle_city_map()
	check(game.city_overview.visible and not city.active, "overview pauses movement")
	check(city.player.click_path.is_empty(), "overview clears pending movement")
	check(game.city_overview.district_labels.size() == 10, "district names on overview")
	var dot = game.city_overview.player_dot.position
	var expected = game.city_overview.MAP_RECT.position + city.player.position / city.map_bounds.size * game.city_overview.MAP_RECT.size - Vector2(5, 5)
	check(dot.distance_to(expected) < 0.1, "correct current-location marker")
	game.toggle_city_map()
	check(not game.city_overview.visible and city.active, "closing overview restores exploration")
	# Walk toward the river boundary using actual CharacterBody collision.
	city.player.position = city.city_point([280, 530])
	city.camera.snap_to_player()
	Input.action_press("move_left")
	await create_timer(0.5).timeout
	Input.action_release("move_left")
	check(city.player.position.x >= 1080, "physics prevents entering river")
	city.player.position = city.city_point([1360, 735])
	city.camera.snap_to_player()
	await create_timer(0.05).timeout
	city.camera.force_update_scroll()
	check(city.camera.get_screen_center_position().x > 4500, "camera follows beyond old small map")
	check(game.location.text.contains("농촌"), "district HUD follows player")
	game.reset()
	check(city.map_bounds.size == Vector2(1280, 720), "reset restores prologue map bounds")
	check(city.ambient_nodes.is_empty() and city.npcs.size() == 5, "city residents removed on reset")
	check(not game.city_overview.visible and game.state == "title", "reset restores title")
	check(is_equal_approx(city.camera.exploration_zoom, 1.5), "reset restores prologue camera zoom")
	# Finish the reset crossfade before releasing audio playback resources.
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_CHANGSHA: " + ("FAIL" if failed else "PASS — paths, landmarks, physics, movement, camera, overview, cleanup"))
	quit(1 if failed else 0)
