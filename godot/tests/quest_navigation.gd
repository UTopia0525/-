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
	var nav = game.quest_navigation
	var mini = game.minimap
	check(nav.get_goal(city).is_empty(), "no quest is accepted implicitly")
	var actors := 0
	for npc in city.ambient_nodes:
		if npc.get_meta("quest_actor", false): actors += 1
		for road in city.city_data.road_centers:
			check(not Rect2(road[0], road[1], road[2], road[3]).has_point(npc.position / 4), "resident avoids road center")
	check(actors == 11, "all eleven active quest residents placed")
	check(nav.definitions.size() == 13, "twelve side quests and the bandit campaign have destinations")
	for id in nav.definitions:
		for stage in nav.definitions[id].stages:
			check(nav.track(id, stage), "valid quest stage")
			var goal: Dictionary = nav.get_goal(city)
			check(not goal.is_empty(), "stage resolves to a destination")
			for item in nav.definitions[id].stages[stage].goals:
				var point: Vector2 = goal.position
				if item.has("point"): point = city.city_point(item.point)
				check(city.point_is_walkable(point), "walkable target: " + str(item.id))
				check(not city.path_to(point, true).is_empty(), "reachable target: " + str(item.id))
	nav.track("changsha_cloth", "deliver")
	var recipient
	for npc in city.ambient_nodes:
		if npc.get_meta("npc_id") == "city_merchant": recipient = npc
	var saved: Vector2 = recipient.position
	city.player.position = Vector2(3072, 2048)
	city.camera.snap_to_player()
	await process_frame
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1), Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1)]:
		recipient.position = city.player.position + direction * 1800
		mini.refresh()
		check(mini.quest_active and mini.quest_offscreen, "outside destination uses edge arrow")
		check(Rect2(Vector2(11, 11), mini.VIEW_SIZE - Vector2(22, 22)).has_point(mini.quest_marker), "edge arrow stays inside map")
		check(mini.quest_direction.dot(direction.normalized()) > 0.9, "arrow points toward destination")
	recipient.position = city.player.position + Vector2(100, 20)
	mini.refresh()
	check(mini.quest_active and not mini.quest_offscreen, "near destination uses diamond")
	check(mini.quest_marker.distance_to(mini.project_point(recipient.position)) < 0.1, "marker follows live NPC")
	recipient.position = saved
	nav.track("changsha_cloth", "deliver", ["city_merchant"])
	check(nav.get_goal(city).stage_id == "report", "fulfilled goal guides back to report")
	nav.track("changsha_pages", "collect", ["page_1", "page_2"])
	check(nav.get_goal(city).goal_id == "page_3", "only remaining objective is tracked")
	check(not nav.track("invalid", "missing"), "invalid quest rejected")
	nav.clear()
	mini.refresh()
	check(not mini.quest_active and not mini.quest_offscreen, "clear removes stale arrow")
	nav.track("changsha_cloth", "deliver")
	game.reset()
	mini.refresh()
	check(nav.get_goal(city).is_empty() and not mini.quest_active, "reset removes target on other map")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_QUEST_NAVIGATION: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
