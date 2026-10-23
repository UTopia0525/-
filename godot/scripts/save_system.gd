extends Node
## Versioned manual saves; continuations are explicit allowed methods, never objects/code.
const SLOT_COUNT = 10
const ROOT = "user://saves"
const CALLBACKS = {
	"main":["_captain_done", "_boarding_done", "_service_done", "start_battle", "show_story_choice"],
	"prologue":["_next", "_drowning", "_delivery", "_after_delivery", "_farewell", "_arrival", "_finish"],
	"chapter_one":["_accept_first_quest"]}
var game
var error := ""

func callback_data(callback: Callable) -> Dictionary:
	if callback.is_null(): return {}
	for owner_id in CALLBACKS:
		var owner = game if owner_id == "main" else game.get(owner_id)
		if callback.get_object() == owner and str(callback.get_method()) in CALLBACKS[owner_id] and callback.get_bound_arguments_count() == 0:
			return {"owner":owner_id, "method":str(callback.get_method())}
	return {"invalid":true}

func valid_callback(value) -> bool:
	return value is Dictionary and (value.is_empty() or (CALLBACKS.has(value.get("owner")) and value.get("method") in CALLBACKS[value.owner]))

func callback_from(value: Dictionary) -> Callable:
	if value.is_empty(): return Callable()
	return Callable(game if value.owner == "main" else game.get(value.owner), value.method)

func blocked_reason() -> String:
	if game.state == "title": return "플레이를 시작한 뒤 저장할 수 있습니다."
	if game.state == "chapter_transition": return "메뉴를 닫아 장 표시를 마친 뒤 저장하세요."
	if game.state == "battle" and game.battle.busy: return "메뉴를 닫아 공격 연출을 마친 뒤 내 차례에 저장하세요."
	if not valid_callback(callback_data(game.dialogue_done)) or not valid_callback(callback_data(game.prologue.sequence_done)):
		return "현재 대화가 끝난 뒤 저장할 수 있습니다."
	return ""

func capture() -> Dictionary:
	var p = game.prologue
	var w = game.exploration
	var nodes = {"top_hud":game.top_hud, "bottom_hint":game.bottom_hint, "caption":game.story_caption, "exploration":w, "ending":game.ending, "overview":game.city_overview, "visual":game.story_visual}
	var visibility := {}
	for id in nodes: visibility[id] = nodes[id].visible
	return {"schema":2, "saved_at":Time.get_datetime_string_from_system(false, true), "state":game.state,
		"chapter":game.chapter_number, "money":game.money, "talked_captain":game.talked_captain,
		"world":{"area":w.area_name, "position":[w.player.position.x, w.player.position.y], "facing":w.player.facing, "active":w.active},
		"prologue":{"active":p.active, "completed":p.completed, "branch":p.branch, "paid":p.payment_received, "queue":p.pending_scenes.duplicate(), "done":callback_data(p.sequence_done)},
		"chapter_one":game.chapter_one.snapshot().merged({"started":game.chapter_one.intro_started}),
		"navigation":{"quest":game.quest_navigation.quest_id, "stage":game.quest_navigation.stage_id, "completed":game.quest_navigation.completed_goal_ids.duplicate()},
		"dialogue":{"lines":game.dialogue_lines.duplicate(true), "index":game.dialogue_index, "done":callback_data(game.dialogue_done), "cues":game.dialogue_music_cues.duplicate(), "listeners":game.dialogue_cast.portraits.keys()},
		"ui":{"visible":visibility, "location":game.location.text, "objective":game.objective.text, "hint":game.bottom_hint.text, "caption":game.story_caption.text, "ending_hp":game.ending_hp.text},
		"visual":{"mode":game.story_visual.mode, "phase":game.story_visual.phase, "paused":game.story_visual.paused},
		"choice":game.pending_choice, "service":game.city_service.service.duplicate(true), "service_tab":game.city_service.selected_tab, "pending_service":game.pending_service_id,
		"battle":{"weapon_id":game.battle.equipped_weapon_id, "weapon_type":game.battle.equipped_weapon_type, "inner_power":game.battle.qi.inner_power, "qi":game.battle.qi.amount, "player_hp":game.battle.player_hp, "enemy_hp":game.battle.enemy_hp, "turn":game.battle.turn, "selected":game.battle.selected},
		"music":{"track":game.music.current_track, "enabled":game.music.enabled}}

func path(slot: int) -> String: return ROOT + "/slot_%02d.json" % slot

func write_slot(slot: int) -> bool:
	error = blocked_reason()
	if not error.is_empty(): return false
	if slot < 1 or slot > SLOT_COUNT:
		error = "잘못된 저장 칸입니다."
		return false
	var data = capture()
	if not validate(data):
		error = "현재 상태를 저장할 수 없습니다."
		return false
	DirAccess.make_dir_recursive_absolute(ROOT)
	var destination = path(slot)
	var temp = destination + ".tmp"
	var backup = destination + ".bak"
	var file = FileAccess.open(temp, FileAccess.WRITE)
	if not file:
		error = "저장 파일을 만들지 못했습니다."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var status = file.get_error()
	file.close()
	if status != OK:
		error = "파일 쓰기에 실패했습니다. 기존 저장은 유지됩니다."
		return false
	if FileAccess.file_exists(destination):
		if FileAccess.file_exists(backup): DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(destination, backup) != OK:
			error = "기존 저장을 보호하기 위해 저장을 중단했습니다."
			return false
	if DirAccess.rename_absolute(temp, destination) != OK:
		if FileAccess.file_exists(backup): DirAccess.rename_absolute(backup, destination)
		error = "저장을 완료하지 못했습니다."
		return false
	return true

func read_slot(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT: return {}
	if not FileAccess.file_exists(path(slot)): return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path(slot)))
	return parsed if validate(parsed) else {}

func validate(d) -> bool:
	if not d is Dictionary: return false
	if d.get("schema") != 1 and d.get("schema") != 2: return false
	for field in ["world", "prologue", "chapter_one", "navigation", "dialogue", "ui", "visual", "service", "battle", "music"]:
		if not d.get(field) is Dictionary: return false
	if d.get("state") not in ["explore", "story", "choice", "service", "battle", "end"]: return false
	if not d.get("saved_at") is String or not is_number(d.get("money"), 0, 1000000000) or not is_number(d.get("chapter"), 0, 1): return false
	if not d.get("talked_captain") is bool or d.get("choice") not in ["", "treasure", "rescue"]: return false
	if d.world.get("area") not in ["dock", "deck", "changsha"]: return false
	var pos = d.world.get("position")
	if not pos is Array or pos.size() != 2: return false
	var limit = Vector2(6144, 4096) if d.world.area == "changsha" else Vector2(1280, 720)
	if not is_number(pos[0], 0, limit.x) or not is_number(pos[1], 0, limit.y): return false
	if d.world.get("facing") not in ["up", "down", "left", "right"] or not d.world.get("active") is bool: return false
	var p = d.prologue
	for key in ["active", "completed", "paid"]:
		if not p.get(key) is bool: return false
	if p.get("branch") not in ["", "treasure", "rescue"] or not valid_callback(p.get("done")): return false
	if not p.get("queue") is Array: return false
	for id in p.queue:
		if not game.prologue.scenes.has(id): return false
	var c = d.chapter_one
	for key in ["started", "intro_complete", "banner_shown"]:
		if not c.get(key) is bool: return false
	if not c.get("accepted_quests") is Dictionary: return false
	for id in c.accepted_quests:
		if id != "changsha_cloth" or c.accepted_quests[id] != {"status":"active", "stage":"deliver"}: return false
	var n = d.navigation
	if not n.get("quest") is String or not n.get("completed") is Array: return false
	if n.quest != "" and (not game.quest_navigation.definitions.has(n.quest) or not game.quest_navigation.definitions[n.quest].stages.has(n.get("stage"))): return false
	for id in n.completed:
		if not id is String: return false
	var dialogue = d.dialogue
	if not dialogue.get("lines") is Array or not valid_callback(dialogue.get("done")) or not dialogue.get("cues") is Dictionary or not dialogue.get("listeners") is Array: return false
	if not is_number(dialogue.get("index"), 0, maxi(0, dialogue.lines.size() - 1)) and not dialogue.lines.is_empty(): return false
	for line in dialogue.lines:
		if not line is Array or line.size() < 2 or not game.PORTRAITS.ACTORS.has(line[0]) or not line[1] is String: return false
	for id in dialogue.listeners:
		if not game.PORTRAITS.ACTORS.has(id): return false
	for value in dialogue.cues.values():
		if not game.music.TRACKS.has(value): return false
	for key in ["location", "objective", "hint", "caption", "ending_hp"]:
		if not d.ui.get(key) is String: return false
	if not d.ui.get("visible") is Dictionary: return false
	for key in ["top_hud", "bottom_hint", "caption", "exploration", "ending", "overview", "visual"]:
		if not d.ui.visible.get(key) is bool: return false
	if d.visual.get("mode") not in ["", "wreck", "river", "shore", "delivery"] or not is_number(d.visual.get("phase"), 0, 1000000000) or not d.visual.get("paused") is bool: return false
	if not d.get("pending_service") is String or not is_number(d.get("service_tab"), 0, 1): return false
	if not d.service.is_empty() and d.service.get("id") not in ["city_merchant", "city_artisan", "city_instructor"]: return false
	if d.state == "service" and d.service.is_empty(): return false
	if not is_number(d.battle.get("player_hp"), 0, 300) or not is_number(d.battle.get("enemy_hp"), 0, 150) or not is_number(d.battle.get("turn"), 1, 10000) or not d.battle.get("selected") is bool: return false
	if d.battle.has("weapon_id"):
		if not d.battle.weapon_id is String or not game.battle.weapons.exists(d.battle.weapon_id): return false
		if d.battle.has("weapon_type") and game.battle.weapons.weapon_type(d.battle.weapon_id) != d.battle.weapon_type: return false
	if d.battle.has("weapon_type") and not game.battle.martial_arts.WEAPON_NAMES.has(d.battle.weapon_type): return false
	if d.schema == 2:
		if not is_number(d.battle.get("inner_power"), 0, 100) or not is_number(d.battle.get("qi"), 0, 500): return false
	return game.music.TRACKS.has(d.music.get("track")) and d.music.get("enabled") is bool

func is_number(value, lower: float, upper: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(value) and value >= lower and value <= upper

func load_slot(slot: int) -> bool:
	var d = read_slot(slot)
	if d.is_empty():
		error = "불러올 수 없는 저장입니다. 현재 진행은 유지됩니다."
		return false
	game.reset()
	game.state = d.state
	game.chapter_number = int(d.chapter)
	game.money = int(d.money)
	if d.battle.has("weapon_id"): game.battle.equip_weapon_item(d.battle.weapon_id)
	else: game.battle.equip_weapon(d.battle.get("weapon_type", "sword"))
	game.talked_captain = d.talked_captain
	game.exploration.load_area(d.world.area)
	game.exploration.player.position = Vector2(d.world.position[0], d.world.position[1])
	game.exploration.player.facing = d.world.facing
	game.exploration.player.stop()
	game.exploration.camera.snap_to_player()
	game.exploration.set_active(d.world.active)
	var p = game.prologue
	p.active = d.prologue.active
	p.completed = d.prologue.completed
	p.branch = d.prologue.branch
	p.payment_received = d.prologue.paid
	p.pending_scenes = d.prologue.queue.duplicate()
	p.sequence_done = callback_from(d.prologue.done)
	var c = game.chapter_one
	c.intro_started = d.chapter_one.started
	c.intro_complete = d.chapter_one.intro_complete
	c.banner_shown = d.chapter_one.banner_shown
	c.accepted_quests = d.chapter_one.accepted_quests.duplicate(true)
	if d.navigation.quest != "": game.quest_navigation.track(d.navigation.quest, d.navigation.stage, d.navigation.completed)
	game.pending_service_id = d.pending_service
	if not d.dialogue.lines.is_empty():
		game.say(d.dialogue.lines, callback_from(d.dialogue.done), d.dialogue.listeners)
		game.dialogue_index = int(d.dialogue.index)
		game.dialogue_music_cues.clear()
		for key in d.dialogue.cues: game.dialogue_music_cues[int(key)] = d.dialogue.cues[key]
		game._show_line()
	if d.ui.visible.visual:
		game.story_visual.present(d.visual.mode)
		game.story_visual.phase = d.visual.phase
		game.story_visual.paused = d.visual.paused
	if d.state == "choice":
		game.show_story_choice()
		if d.choice != "": game.select_story_choice(d.choice)
	if d.state == "service":
		for definition in game.exploration.city_data.services:
			if definition.id == d.service.id: game.city_service.open_counter(definition)
		game.city_service.select_tab(int(d.service_tab))
	if d.state == "battle":
		var inner_power: int = int(d.battle.inner_power) if d.schema == 2 else int(game.battle.Rules.STARTING_STATS.inner)
		game.battle.begin(inner_power)
		# Legacy saves predate costs: regenerate once per elapsed player turn.
		var amount: int = int(d.battle.qi) if d.schema == 2 else mini(500, inner_power * int(d.battle.turn))
		game.battle.qi.restore(inner_power, amount)
		game.battle.player_hp = int(d.battle.player_hp)
		game.battle.enemy_hp = int(d.battle.enemy_hp)
		game.battle.turn = int(d.battle.turn)
		game.battle._update_hp()
		game.battle.turn_label.text = "내 차례 · %d번째 교전" % game.battle.turn
		if d.battle.selected: game.battle.select_samjae()
		game.exploration.camera.enabled = false
	game.location.text = d.ui.location
	game.objective.text = d.ui.objective
	game.bottom_hint.text = d.ui.hint
	game.story_caption.text = d.ui.caption
	game.ending_hp.text = d.ui.ending_hp
	game.title_screen.hide()
	game.top_hud.visible = d.ui.visible.top_hud
	game.bottom_hint.visible = d.ui.visible.bottom_hint
	game.story_caption.visible = d.ui.visible.caption
	game.exploration.visible = d.ui.visible.exploration
	game.ending.visible = d.ui.visible.ending
	if d.ui.visible.overview:
		game.city_overview.open_for(game.exploration, game.quest_navigation.get_goal(game.exploration))
	game.music.play_track(d.music.track)
	game.music.set_enabled(d.music.enabled)
	return true
