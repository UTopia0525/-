extends SceneTree

var game
var failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("CAMERA TEST: " + message)

func place_player(point: Vector2) -> void:
	game.exploration.player.position = point
	game.exploration.player.stop()
	game.exploration.camera.snap_to_player()
	await process_frame
	game.exploration.camera.force_update_scroll()

func body_on_screen() -> Vector2:
	var focus: Vector2 = game.exploration.player.position + game.exploration.camera.position
	return game.exploration.get_global_transform_with_canvas() * focus

func check_map_visible(bounds: Rect2) -> void:
	var camera: Camera2D = game.exploration.camera
	var center = camera.get_screen_center_position()
	var half = root.get_visible_rect().size / camera.zoom / 2.0
	check(center.x-half.x >= bounds.position.x-0.1, "left edge stays inside map")
	check(center.y-half.y >= bounds.position.y-0.1, "top edge stays inside map")
	check(center.x+half.x <= bounds.end.x+0.1, "right edge stays inside map")
	check(center.y+half.y <= bounds.end.y+0.1, "bottom edge stays inside map")

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_story()
	game.advance_dialogue()
	game.exploration.set_active(false)
	var camera: Camera2D = game.exploration.camera
	var center = root.get_visible_rect().size / 2.0
	var hud_origin = game.location.get_global_transform_with_canvas().origin
	await place_player(Vector2(640, 396))
	check(body_on_screen().distance_to(center) < 0.1, "player body is centered inside map")
	var before = game.exploration.background.get_global_transform_with_canvas().origin
	await place_player(Vector2(700, 416))
	check(body_on_screen().distance_to(center) < 0.1, "camera follows movement")
	var after = game.exploration.background.get_global_transform_with_canvas().origin
	check(before.distance_to(after) > 50, "background scrolls")
	check(game.location.get_global_transform_with_canvas().origin.is_equal_approx(hud_origin), "HUD remains in screen space")
	check_map_visible(Rect2(0, 0, 1280, 720))

	await place_player(Vector2(110, 400))
	var edge_center = camera.get_screen_center_position()
	var edge_body = body_on_screen()
	await place_player(Vector2(160, 400))
	check(camera.get_screen_center_position().is_equal_approx(edge_center), "camera holds at left edge")
	check(body_on_screen().x > edge_body.x+50, "player moves across fixed edge view")
	await place_player(Vector2(160, 430))
	check(absf(camera.get_screen_center_position().x-edge_center.x) < 0.1, "left edge only locks horizontal axis")
	check(camera.get_screen_center_position().y > edge_center.y+20, "vertical following continues at side edge")
	for point in [Vector2(10, 10), Vector2(1270, 10), Vector2(10, 710), Vector2(1270, 710)]:
		await place_player(point)
		check_map_visible(Rect2(0, 0, 1280, 720))

	# Future maps can supply larger bounds without changing follow behavior.
	camera.set_map_bounds(Rect2(0, 0, 2560, 1440))
	await place_player(Vector2(1500, 1000))
	check(body_on_screen().distance_to(center) < 0.1, "larger map follows outside old screen")
	check_map_visible(Rect2(0, 0, 2560, 1440))
	camera.set_map_bounds(Rect2(0, 0, 320, 180))
	await place_player(Vector2(160, 126))
	check_map_visible(Rect2(0, 0, 320, 180))
	check(camera.zoom.x >= 4.0, "small map fits without empty borders")

	game.exploration.load_area("deck")
	game.exploration.set_active(false)
	await process_frame
	camera.force_update_scroll()
	check(camera.enabled, "map transition enables camera")
	check(camera.get_screen_center_position().x < 1000, "map transition snaps to new spawn")
	check_map_visible(game.exploration.map_bounds)
	game.start_battle()
	await process_frame
	check(not camera.enabled, "battle does not use exploration camera")
	var use_origin = game.battle.use_button.get_global_transform_with_canvas().origin
	check(use_origin.distance_to(Vector2(474, 644)) < 0.1, "battle controls stay in screen space")
	camera._fit_view()
	check(not camera.enabled, "resize does not reactivate camera during battle")
	game.reset()
	await process_frame
	check(camera.enabled, "return to exploration restores camera")
	check(game.location.get_global_transform_with_canvas().origin.is_equal_approx(hud_origin), "HUD does not jump on return")
	# Let the last music crossfade finish before shutting down the test tree.
	await create_timer(1.0).timeout
	# Allow the audio mixing thread to release its last loop before test exit.
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_CAMERA: " + ("FAIL" if failed else "PASS — centered follow, edge clamps, fixed UI, map sizes, transitions, battle"))
	quit(1 if failed else 0)
