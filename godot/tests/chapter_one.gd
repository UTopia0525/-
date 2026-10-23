extends SceneTree
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	if not ok:
		failed = true
		push_error("CHAPTER_ONE: " + text)
func drain() -> void:
	var limit := 0
	while not game.dialogue_lines.is_empty() and limit < 300:
		game.advance_dialogue()
		limit += 1
	check(limit < 300, "dialogue terminates")
func legacy_save() -> void:
	var file = FileAccess.open(game.prologue.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1, "chapter_00_complete":true, "branch":"treasure", "payment_received":true, "money":3000}))
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	legacy_save()
	game.prologue.resume()
	check(game.money == 3000 and game.prologue.completed, "legacy checkpoint preserves branch and money")
	check(game.chapter_one.intro_started and not game.exploration.active and game.state == "story", "legacy save enters greeting without free exploration")
	check(game.dialogue_cast.portraits.has("cloth_merchant") and game.dialogue_cast.portraits.has("hero"), "greeting portraits")
	check(game.chapter_one.accepted_quests.is_empty(), "quest is not received before conversation ends")
	drain()
	check(game.chapter_one.accepted_quests.get("changsha_cloth") == {"status":"active", "stage":"deliver"}, "first quest accepted after greeting")
	check(game.quest_navigation.quest_id == "changsha_cloth", "first quest destination tracked")
	check(game.state == "chapter_transition" and game.chapter_one.banner.visible and not game.exploration.active, "chapter card precedes control handoff")
	var labels = game.chapter_one.banner.find_children("*", "Label", true, false)
	check(labels.size() == 1 and labels[0].text == "1장", "no invented chapter subtitle")
	game.chapter_one.begin()
	check(game.dialogue_lines.is_empty(), "begin is idempotent")
	await create_timer(2.6).timeout
	check(game.state == "explore" and game.exploration.active and not game.chapter_one.banner.visible, "card fades then movement resumes")
	var before: int = game.money
	game.reset()
	game.prologue.resume()
	check(game.state == "explore" and game.chapter_one.intro_complete and game.dialogue_lines.is_empty(), "v2 resume does not replay greeting")
	check(not game.chapter_one.banner.visible and game.chapter_one.banner_shown, "card does not replay on load")
	check(game.money == before and game.quest_navigation.quest_id == "changsha_cloth", "load restores money and received quest")
	# Reset during the card must cancel its deferred return to exploration.
	legacy_save()
	game.prologue.resume()
	drain()
	game.reset()
	await create_timer(2.6).timeout
	check(game.state == "title" and not game.exploration.active and not game.chapter_one.banner.visible, "reset cancels transition callback")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_CHAPTER_ONE: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
