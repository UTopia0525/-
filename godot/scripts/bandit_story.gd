extends Node
const STAT_MAX = preload("res://scripts/rules.gd").STAT_MAX
## Chapter-one campaign: one automatic notice, two fights, one settlement.
const QUEST_ID = "changsha_bandit_campaign"
const STAGES = ["dormant", "notice", "offered", "enrollment", "preparing", "briefing", "battle_one", "after_first", "battle_two", "after_second", "report", "settlement", "completed", "retreat"]
var game
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/changsha_bandit_story.json"))
var stage := "dormant"
var reward_granted := false
var previous_navigation: Dictionary = {}

func reset() -> void:
	stage = "dormant"
	reward_granted = false
	previous_navigation.clear()

func eligible() -> bool:
	if not game.chapter_one.intro_complete or game.chapter_number != 1: return false
	var total := 0
	for value in game.progress.stats.values(): total += int(value)
	var new_arts := 0
	for id in game.progress.learned:
		if id not in data.trigger.exclude_arts: new_arts += 1
	return total >= int(data.trigger.minimum_stat_total) and new_arts >= int(data.trigger.minimum_new_arts)

func maybe_start() -> void:
	if stage != "dormant" or not eligible(): return
	if game.adventure_ui.window.visible or game.get_tree().paused or game.state != "explore" or game.exploration.area_name != "changsha" or not game.exploration.active: return
	if not game.dialogue_lines.is_empty() or game.city_overview.visible or game.city_service.visible or game.settings_menu.window.visible: return
	previous_navigation = {"quest":game.quest_navigation.quest_id, "stage":game.quest_navigation.stage_id, "completed":game.quest_navigation.completed_goal_ids.duplicate()}
	play("notice", _notice_done)

func play(id: String, done: Callable) -> void:
	stage = id
	if id in ["after_first", "after_second", "retreat"]: game.story_visual.present("bandit_road")
	else: game.story_visual.hide()
	game.state = "story"
	game.top_hud.hide()
	game.exploration.set_active(false)
	game.story_caption.text = data.working_title
	game.story_caption.show()
	game.bottom_hint.text = "F  다음 대사 · ESC  설정과 저장"
	game.bottom_hint.show()
	game.say(data.scenes[id], done)

func explore(next_stage: String) -> void:
	stage = next_stage
	game.story_visual.hide()
	game.state = "explore"
	game.story_caption.hide()
	game.top_hud.show()
	game.bottom_hint.show()
	game.bottom_hint.text = preload("res://scripts/ui.gd").EXPLORATION_HINT
	game.exploration.show()
	game.exploration.set_active(true)
	game.exploration.camera.snap_to_player()
	game.music.play_track("dock")
	var target: String = {"offered":"enlist", "preparing":"muster", "report":"report"}.get(stage, "")
	if not target.is_empty(): game.quest_navigation.update_quest(QUEST_ID, target)

func _notice_done() -> void: explore("offered")
func _enrolled() -> void: explore("preparing")

func handle_interaction(id: String) -> bool:
	if id not in ["bandit_officer", "bandit_muster"]: return false
	if id == "bandit_officer":
		match stage:
			"offered": play("enrollment", _enrolled)
			"report": play("settlement", _settle)
			"completed": game.say(data.scenes.completed)
			"dormant": game.say(data.scenes.idle)
			_: game.say(data.scenes.preparing)
	else:
		if stage == "preparing": play("briefing", _battle_one)
		elif stage in ["report", "completed"]: game.say(data.scenes.await_report)
		else: game.say([["bandit_messenger", "토벌 지원은 관아 앞 정 포두께 먼저 말씀하십시오."]])
	return true

func _battle_one() -> void:
	stage = "battle_one"
	game.story_caption.hide()
	game.start_battle(data.encounters[0])

func _battle_two() -> void:
	stage = "battle_two"
	game.story_caption.hide()
	game.start_battle(data.encounters[1])

func in_battle() -> bool: return stage in ["battle_one", "battle_two"]

func after_victory() -> void:
	game.battle.hide()
	game.exploration.show()
	game.exploration.set_active(false)
	game.music.play_track("ambush")
	if stage == "battle_one": play("after_first", _battle_two)
	elif stage == "battle_two": play("after_second", _return_to_city)

func after_defeat() -> void:
	game.battle.hide()
	game.exploration.show()
	game.exploration.set_active(false)
	game.music.play_track("title")
	play("retreat", _retry)

func _return_to_city() -> void:
	game.exploration.player.position = game.exploration.city_point([1195, 515])
	game.exploration.player.stop()
	explore("report")

func _retry() -> void:
	game.exploration.player.position = game.exploration.city_point([1195, 515])
	game.exploration.player.stop()
	explore("preparing")

func _settle() -> void:
	if reward_granted:
		_finish()
		return
	game.money += int(data.reward.money)
	var before: int = int(game.progress.stats.insight)
	game.progress.stats.insight = mini(STAT_MAX, before + int(data.reward.insight))
	game.progress.fame += int(data.reward.fame)
	game.adventure_ui.notify("토벌 보고 완료 · %d문 · 오성+%d · 명성+%d" % [int(data.reward.money),int(game.progress.stats.insight)-before,int(data.reward.fame)],"quest")
	reward_granted = true
	stage = "completed"
	game.state = "story"
	game.story_caption.text = "토벌 완료 · 보수%d문 · 오성+%d · 명성+%d" % [data.reward.money, int(game.progress.stats.insight) - before, data.reward.fame]
	game.story_caption.show()
	game.say(data.scenes.recognition, _finish)

func _finish() -> void:
	explore("completed")
	if game.quest_navigation.quest_id==QUEST_ID:game.quest_navigation.clear()
	game.trade_intro.sync_navigation()

func snapshot() -> Dictionary:
	return {"stage":stage, "reward_granted":reward_granted, "previous_navigation":previous_navigation.duplicate(true)}

func valid(value) -> bool:
	if not value is Dictionary or value.get("stage") not in STAGES or not value.get("reward_granted") is bool: return false
	if value.reward_granted != (value.stage == "completed"): return false
	var previous = value.get("previous_navigation")
	if not previous is Dictionary: return false
	if previous.is_empty(): return true
	if not previous.get("quest") is String or not previous.get("stage") is String or not previous.get("completed") is Array: return false
	if previous.quest != "" and (not game.quest_navigation.definitions.has(previous.quest) or not game.quest_navigation.definitions[previous.quest].stages.has(previous.stage) or previous.quest == QUEST_ID): return false
	for id in previous.completed:
		if not id is String: return false
	return true

func restore(value: Dictionary) -> void:
	stage = value.stage
	reward_granted = value.reward_granted
	previous_navigation = value.previous_navigation.duplicate(true)

func encounter() -> Dictionary:
	if stage == "battle_one": return data.encounters[0]
	if stage == "battle_two": return data.encounters[1]
	return {}
