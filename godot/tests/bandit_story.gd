extends SceneTree
var failed := false
var game
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("BANDIT_STORY: " + message)
func drain() -> void:
	var limit := 100
	while not game.dialogue_lines.is_empty() and limit > 0:
		game.advance_dialogue()
		limit -= 1
	check(limit > 0, "dialogue has a finite end")
func approach(id: String) -> void:
	for actor in game.exploration.ambient_nodes:
		if actor.get_meta("npc_id") == id:
			game.exploration.player.position = actor.position + Vector2(36, 12)
			check(game.exploration.point_is_walkable(actor.position), "story NPC stands on walkable ground: " + id)
			check(game.exploration.nearest().id == id, "story NPC available through F: " + id)
			game.interact()
			return
	check(false, "missing story NPC")
func fight_to_end() -> void:
	var limit := 15
	while game.state == "battle" and limit > 0:
		game.battle.select_samjae()
		game.battle.use_selected()
		var deadline = Time.get_ticks_msec() + 15000
		while game.battle.busy and Time.get_ticks_msec() < deadline: await create_timer(0.04).timeout
		check(not game.battle.busy, "action completes")
		limit -= 1
	check(limit > 0, "battle resolves")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_city()
	var story = game.bandit_story
	game.progress.stats = {"strength":20, "agility":20, "constitution":20, "inner":20, "insight":20}
	game.progress.learned.append("cheongpung")
	check(not story.eligible(), "city preview does not bypass chapter zero")
	game.chapter_number = 1
	game.chapter_one.intro_started = true
	game.chapter_one.intro_complete = true
	game.chapter_one.banner_shown = true
	game.chapter_one.accepted_quests.changsha_cloth = {"status":"active", "stage":"deliver"}
	game.quest_navigation.track("changsha_cloth", "deliver")
	game.progress.learned = ["samjae"]
	check(not story.eligible(), "starting Samjae alone does not count as new learning")
	game.progress.learned.append("cheongpung")
	game.progress.stats.strength = 19
	check(not story.eligible(), "99 total does not meet realm threshold")
	game.progress.stats.strength = 20
	check(story.eligible(), "exact 100 and a new art qualify")
	game.settings_menu.open_menu()
	story.maybe_start()
	check(story.stage == "dormant", "settings does not get interrupted")
	game.settings_menu.close_menu()
	story.maybe_start()
	check(story.stage == "notice" and game.state == "story" and not game.exploration.active, "notice automatically starts and stops movement")
	check(game.save_system.write_slot(1), "save during automatic notice")
	game.advance_dialogue()
	check(game.save_system.load_slot(1) and story.stage == "notice" and game.dialogue_index == 0, "reload dialogue without replaying trigger")
	drain()
	check(story.stage == "offered" and game.quest_navigation.quest_id == story.QUEST_ID, "notice leaves government destination")
	approach("bandit_officer")
	drain()
	check(story.stage == "preparing" and game.quest_navigation.stage_id == "muster", "support enrollment leads to muster")
	check(game.save_system.write_slot(2) and game.save_system.load_slot(2), "save preparation stage")
	approach("bandit_muster")
	drain()
	check(story.stage == "battle_one" and game.battle.enemy_max_hp == 180 and game.battle.qi.amount == 20, "first encounter configured")
	check(game.save_system.write_slot(3), "save enemy above old 150 hp limit")
	check(game.save_system.load_slot(3) and game.battle.enemy_hp == 180 and game.battle.encounter.id == "bandit_sentry", "restore proper enemy and battlefield")
	await fight_to_end()
	check(story.stage == "after_first", "first victory routes to campaign dialogue")
	check(game.save_system.write_slot(9) and game.save_system.load_slot(9) and game.story_visual.mode == "bandit_road" and game.story_visual.visible, "save dialogue between battles with mountain staging")
	drain()
	check(story.stage == "battle_two" and game.battle.player_hp == 300 and game.battle.qi.amount == 20, "second fight resets HP and qi")
	check(game.save_system.write_slot(4) and game.save_system.load_slot(4) and game.battle.enemy_max_hp == 240, "second enemy save restores max hp")
	# Simulate a losing exchange; retreat must not grant rewards or deadlock.
	game.battle.player_hp = 1
	game.battle.select_basic_attack()
	game.battle.use_selected()
	var deadline = Time.get_ticks_msec() + 15000
	while game.battle.busy and Time.get_ticks_msec() < deadline: await create_timer(0.04).timeout
	check(story.stage == "retreat" and not story.reward_granted and game.money == 0, "defeat retreats without settlement")
	check(game.save_system.write_slot(5) and game.save_system.load_slot(5), "retreat with surviving >150hp enemy is saveable")
	drain()
	check(story.stage == "preparing" and game.state == "explore", "defeat permits equipment and retry")
	approach("bandit_muster")
	drain()
	await fight_to_end()
	drain()
	await fight_to_end()
	check(story.stage == "after_second", "two victories lead to debrief")
	drain()
	check(story.stage == "report" and game.money == 0 and game.progress.fame == 0, "victory alone does not pay")
	check(game.save_system.write_slot(6) and game.save_system.load_slot(6), "save before report")
	approach("bandit_officer")
	# Stop before payment to verify exact-once completion after reload.
	while game.dialogue_index < game.dialogue_lines.size() - 1: game.advance_dialogue()
	check(game.save_system.write_slot(7) and game.save_system.load_slot(7), "save last prepayment line")
	game.advance_dialogue()
	check(story.reward_granted and game.money == 500 and game.progress.fame == 5 and game.progress.stats.insight == 25, "pay 500, insight5, fame5 once")
	check(game.save_system.write_slot(8) and game.save_system.load_slot(8), "save after payment while recognition dialogue remains")
	drain()
	check(story.stage == "completed" and game.quest_navigation.quest_id == "changsha_cloth", "restore previous side quest navigation")
	approach("bandit_officer")
	drain()
	story.maybe_start()
	check(game.money == 500 and game.progress.fame == 5 and story.stage == "completed", "revisit and trigger check cannot repeat reward")
	check(game.save_system.load_slot(7), "rewind to prepayment for cap boundary")
	game.progress.stats.insight = 99
	game.advance_dialogue()
	check(game.progress.stats.insight == 100 and game.story_caption.text.contains("오성+1"), "report respects insight cap and shows actual increase")
	drain()
	game.reset()
	check(story.stage == "dormant" and game.progress.fame == 0, "new game clears campaign and fame")
	check(story.data.scenes.notice.size() == 6 and story.data.scenes.after_first.size() == 8 and story.data.scenes.settlement.size() == 9, "reset and reload never erase reusable dialogue scenes")
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_BANDIT_STORY: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
