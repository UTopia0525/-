extends Node
## Owns the chapter branch and payment; exploration, UI and combat remain in main.
const DATA_PATH = "res://data/prologue_dialogues.json"
const SAVE_PATH = "user://chapter_00.json"
var game
var scenes: Dictionary
var active := false
var completed := false
var branch := ""
var payment_received := false
var pending_scenes: Array = []
var sequence_done: Callable

func _ready() -> void:
	scenes = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))

func cancel() -> void:
	active = false
	completed = false
	branch = ""
	payment_received = false
	pending_scenes.clear()
	sequence_done = Callable()

func begin() -> void:
	cancel()
	active = true

func lines(id: String) -> Array:
	return scenes[id].lines.duplicate(true)

func sequence(ids: Array, done: Callable) -> void:
	pending_scenes = ids.duplicate()
	sequence_done = done
	_next()

func _next() -> void:
	if not active:
		return
	if pending_scenes.is_empty():
		var callback = sequence_done
		sequence_done = Callable()
		if callback.is_valid(): callback.call()
		return
	var id: String = pending_scenes.pop_front()
	game.story_caption.text = scenes[id].title
	game.story_caption.show()
	game.say(lines(id), _next)

func after_victory() -> void:
	game.battle.hide()
	game.state = "story"
	game.exploration.show()
	game.exploration.set_active(false)
	game.exploration.camera.enabled = true
	game.top_hud.hide()
	game.bottom_hint.text = "F  다음 대사     ·     M  음악     ·     F1  타이틀"
	game.bottom_hint.show()
	game.music.play_track("ambush")
	game.story_visual.present("wreck")
	sequence(["victory"], _drowning)

func _drowning() -> void:
	game.story_visual.present("river")
	sequence(["drowning"], game.show_story_choice)

func choose(value: String) -> void:
	if not active or not branch.is_empty() or value not in ["treasure", "rescue"]:
		return
	branch = value
	game.choice_screen.hide()
	game.state = "story"
	game.story_visual.present("shore")
	game.music.play_track("title")
	sequence([branch + "_escape", branch + "_shelter", "dissolution", branch + "_documents"], _delivery)

func _delivery() -> void:
	game.enter_city(true)
	game.top_hud.hide()
	game.state = "story"
	game.exploration.set_active(false)
	sequence([branch + "_delivery"], _after_delivery)

func _after_delivery() -> void:
	if branch == "treasure":
		if not payment_received:
			payment_received = true
			game.money += 3000
		sequence(["treasure_paid"], _farewell)
	else:
		_farewell()

func _farewell() -> void:
	game.story_visual.hide()
	sequence(["treasure_night" if branch == "treasure" else "rescue_farewell"], _arrival)

func _arrival() -> void:
	game.story_visual.hide()
	game.state = "story"
	game.exploration.set_active(false)
	sequence(["arrival", branch + "_arrival", "free_roam"], _finish)

func _finish() -> void:
	if completed: return
	completed = true
	active = false
	game.story_caption.hide()
	game.top_hud.show()
	game.state = "explore"
	game.exploration.set_active(true)
	game.objective.text = "장사 항구에서 시내로 들어가 일거리 찾기"
	save_checkpoint()

func save_checkpoint() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version":1, "chapter_00_complete":true, "branch":branch, "payment_received":payment_received, "money":game.money}))
		game.continue_button.disabled = false
	else:
		game.objective.text = "저장하지 못했습니다. 현재 진행은 계속할 수 있습니다."
		push_warning("Could not save chapter checkpoint")

func read_checkpoint() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH): return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary: return {}
	if data.get("version") != 1 or data.get("chapter_00_complete") != true: return {}
	if data.get("branch") not in ["treasure", "rescue"]: return {}
	var expected = 3000 if data.branch == "treasure" else 0
	if data.get("money") != expected or data.get("payment_received") != (data.branch == "treasure"): return {}
	return data

func resume() -> void:
	var data = read_checkpoint()
	if data.is_empty(): return
	game.reset()
	completed = true
	branch = data.branch
	payment_received = data.payment_received
	game.money = int(data.money)
	game.enter_city(true)
