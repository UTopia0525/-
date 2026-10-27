extends SceneTree
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		push_error("PROLOGUE: " + label)
func drain() -> void:
	var count := 0
	while not game.dialogue_lines.is_empty() and count < 300:
		game.advance_dialogue()
		count += 1
	check(count < 300, "dialogue sequence terminates")
func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	game._input(event)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for branch in ["treasure", "rescue"]:
		game.start_story()
		drain()
		check(game.money == 0, "new prologue does not inherit previous payment")
		game.exploration.player.position = Vector2(640, 395)
		key(KEY_E)
		check(game.dialogue_lines.is_empty(), "E no longer interacts")
		key(KEY_F)
		check(not game.dialogue_lines.is_empty(), "F interacts")
		drain()
		check(game.talked_captain, "full captain greeting")
		game.exploration.player.position = Vector2(810, 410)
		key(KEY_F)
		drain()
		check(game.exploration.area_name == "deck", "boarding after full dialogue")
		game.exploration.player.position = Vector2(715, 365)
		key(KEY_F)
		drain()
		check(game.state == "battle", "full deck script starts tutorial")
		# Combat itself is exercised by smoke.gd; emit its victory outcome here.
		game.battle.cancel()
		game._on_victory(219)
		drain()
		check(game.state == "choice" and not game.exploration.active, "sinking locks movement at decision")
		check(game.prologue.branch.is_empty() and game.choice_confirm.disabled, "no default moral choice")
		check(game.story_visual.picture.visible and game.story_visual.picture.texture.resource_path.ends_with("sinking-escort-ship.png"), "decision shows sinking ship artwork")
		check(game.story_visual.paused and not game.story_visual.note.visible and not game.story_caption.visible, "decision keeps scene still without duplicate captions")
		for label in game.choice_screen.find_children("*", "Label", true, false):
			check(not label.text.contains("보수") and not label.text.contains("3,000") and not label.text.contains("구한다 ·"), "choice descriptions never disclose outcomes")
		key(KEY_F)
		check(game.state == "choice", "F cannot accidentally confirm")
		key(KEY_1 if branch == "treasure" else KEY_2)
		key(KEY_F)
		check(game.prologue.branch.is_empty(), "selected choice also resists F")
		key(KEY_ENTER)
		check(game.prologue.branch == branch, "explicit confirmation commits correct branch")
		var saw_port := false
		var saw_payment := false
		var limit := 0
		while not game.dialogue_lines.is_empty() and limit < 300:
			if game.exploration.area_name == "changsha":
				saw_port = true
				check(game.exploration.player.position.distance_to(game.exploration.city_point([280, 500])) < 0.1, "final conversation at Changsha port")
				check(not game.exploration.active, "arrival dialogue locks movement")
			if game.prologue.payment_received: saw_payment = true
			else: check(game.money == 0, "money is not paid on choice or before delivery confirmation")
			game.advance_dialogue()
			limit += 1
		if game.state == "chapter_transition": await create_timer(2.6).timeout
		check(game.chapter_one.intro_complete and game.chapter_one.banner_shown, "chapter one introduction completes")
		check(game.quest_navigation.quest_id == "changsha_cloth", "first chain quest tracked")
		check(limit < 300 and saw_port, "branch reaches port")
		check(game.prologue.completed and game.state == "explore" and game.exploration.active, "chapter ends in free exploration")
		check(game.money == (3000 if branch == "treasure" else 0), "branch-specific money")
		check(saw_payment == (branch == "treasure"), "payment only after treasure delivery")
		var before: int = game.money
		game.prologue.choose(branch)
		game.advance_dialogue()
		game._on_victory(219)
		check(game.money == before and game.state == "explore", "repeated calls cannot repay or restart chapter")
		game.reset()
		game.prologue.resume()
		check(game.prologue.completed and game.prologue.branch == branch and game.money == before, "checkpoint restores branch and cash without repaying")
		check(game.exploration.active and game.exploration.area_name == "changsha", "resume at free port")
	# Reset while a choice is pending cancels all callbacks and does not alter checkpoint.
	game.start_story()
	drain()
	game.prologue.after_victory()
	drain()
	game.reset()
	check(game.state == "title" and not game.choice_screen.visible and not game.story_visual.visible, "reset cleans choice and visuals")
	check(game.prologue.branch.is_empty() and game.money == 0 and game.dialogue_done.is_null(), "reset clears unfinished state")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_PROLOGUE: " + ("FAIL" if failed else "PASS — both branches, F input, payment, port arrival, checkpoint, reset"))
	quit(1 if failed else 0)
