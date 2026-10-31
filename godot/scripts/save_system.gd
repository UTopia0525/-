extends Node
const HEALTH_RULES = preload("res://scripts/rules.gd")
const LEGACY_HEALTH_CAPS = {"mr_exchange": 220, "qingya_chief": 300, "qingya_sentry": 180, "impostor_ma": 300, "nanjing_nochil": 300, "training_student": 220, "bandit_sentry": 170, "bandit_ringleader": 240, "sz_quay_extortionist": 200, "sz_training_bai": 220, "inn_warrior": 180, "cuiyue_tak": 220, "herb_ruffian": 190, "qingya_maunpyo": 750, "tutorial_pirate": 90, "": 90}
const STAT_MAX = preload("res://scripts/rules.gd").STAT_MAX
## Versioned manual saves; continuations are explicit allowed methods, never objects/code.
const SLOT_COUNT = 10
const ROOT = "user://saves"
const CALLBACKS = {
	"namgung_campaign":["_offer","_march","_arrive","_confront","_fight","_clear","_cleared","_paid","_complete"],
	"ordinary_quests":["_after_dialogue"],
	"main":["_captain_done", "_boarding_done", "_service_done", "start_battle", "show_story_choice"],
	"prologue":["_next", "_drowning", "_delivery", "_after_delivery", "_farewell", "_arrival", "_finish"],
	"chapter_one":["_accept_first_quest"],
	"trade_intro":["_finish_visit"],
	"bandit_story":["_notice_done", "_enrolled", "_battle_one", "_battle_two", "_return_to_city", "_retry", "_settle", "_finish"]}
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
	if game.state=="game_over":return "사망한 진행은 저장할 수 없습니다. 처음 화면으로 돌아가세요."
	if game.adventure_ui.window.visible:return "의뢰 일지·도움말·기록 창을 닫은 뒤 저장하세요."
	if game.player_menu.visible: return "소지품·무공 창을 닫은 뒤 저장하세요."
	if game.state == "title": return "플레이를 시작한 뒤 저장할 수 있습니다."
	if game.state == "chapter_transition": return "메뉴를 닫아 장 표시를 마친 뒤 저장하세요."
	if game.state == "battle": return "교전 중에는 저장할 수 없습니다. 전투를 마친 뒤 저장하세요."
	if game.state == "service" or game.city_service.visible: return "거래 중에는 저장할 수 없습니다. 거래 창을 닫은 뒤 저장하세요."
	if game.state == "story" or game.dialogue_panel.visible or not game.dialogue_lines.is_empty():
		return "대화 중에는 저장할 수 없습니다. 대화를 마친 뒤 저장하세요."
	if not valid_callback(callback_data(game.dialogue_done)) or not valid_callback(callback_data(game.prologue.sequence_done)):
		return "현재 대화가 끝난 뒤 저장할 수 있습니다."
	return ""

func capture() -> Dictionary:
	var p = game.prologue
	var w = game.exploration
	var nodes = {"top_hud":game.top_hud, "bottom_hint":game.bottom_hint, "caption":game.story_caption, "exploration":w, "ending":game.ending, "overview":game.city_overview, "visual":game.story_visual}
	var visibility := {}
	for id in nodes: visibility[id] = nodes[id].visible
	return {"schema":3, "health_revision":1, "blackguild_story":game.blackguild_story.snapshot(), "cuiyue_incident":game.cuiyue_incident.snapshot(), "hangzhou_quests":game.hangzhou_quests.snapshot(), "suzhou_quests":game.suzhou_quests.snapshot(), "namgung_campaign":game.namgung_campaign.snapshot(), "enemy_balance_revision":1, "waterfront_quest":game.waterfront_quest.snapshot(), "levy_quest":game.levy_quest.snapshot(), "book_quest":game.book_quest.snapshot(), "cart_quest":game.cart_quest.snapshot(), "silk_quest":game.silk_quest.snapshot(), "nanjing_relief_quest":game.nanjing_relief_quest.snapshot(), "qingya_quest":game.qingya_quest.snapshot(), "plaque_quest":game.plaque_quest.snapshot(), "grain_quest":game.grain_quest.snapshot(), "wages_quest":game.wages_quest.snapshot(), "alliance_story":game.alliance_story.snapshot(), "impostor_quest":game.impostor_quest.snapshot(), "inn_quest":game.inn_quest.snapshot(), "duel_quest":game.duel_quest.snapshot(), "artisan_quest":game.artisan_quest.snapshot(), "herbalist_quest":game.herbalist_quest.snapshot(), "alliance_visit":game.alliance_visit.snapshot(), "ordinary_quests":game.ordinary_quests.snapshot(), "progress":game.progress.snapshot(), "trade_intro":game.trade_intro.snapshot(), "bandit_story":game.bandit_story.snapshot(), "saved_at":Time.get_datetime_string_from_system(false, true), "state":game.state,
		"chapter":game.chapter_number, "money":game.money, "changsha_reward_revision":1, "talked_captain":game.talked_captain,
		"world":{"layout_version":3 if w.area_name in ["mountain_road","namgung_estate","nanjing"] else 2 if w.area_name=="hangzhou" else 1, "area":w.area_name, "position":[w.player.position.x, w.player.position.y], "facing":w.player.facing, "active":w.active},
		"prologue":{"active":p.active, "completed":p.completed, "branch":p.branch, "paid":p.payment_received, "queue":p.pending_scenes.duplicate(), "done":callback_data(p.sequence_done)},
		"chapter_one":game.chapter_one.snapshot().merged({"started":game.chapter_one.intro_started}),
		"navigation":{"quest":game.quest_navigation.quest_id, "stage":game.quest_navigation.stage_id, "completed":game.quest_navigation.completed_goal_ids.duplicate(),"facility":game.quest_navigation.facility_id},
		"dialogue":{"lines":game.dialogue_lines.duplicate(true), "index":game.dialogue_index, "done":callback_data(game.dialogue_done), "cues":game.dialogue_music_cues.duplicate(), "listeners":game.dialogue_cast.portraits.keys()},
		"ui":{"visible":visibility, "location":game.location.text, "objective":game.objective.text, "hint":game.bottom_hint.text, "caption":game.story_caption.text, "ending_hp":game.ending_hp.text},
		"visual":{"mode":game.story_visual.mode, "phase":game.story_visual.phase, "paused":game.story_visual.paused},
		"choice":game.pending_choice, "service":game.city_service.service.duplicate(true), "service_tab":game.city_service.selected_tab, "pending_service":game.pending_service_id,
		"battle":{"ready_turns":game.battle.ready_turns.duplicate(),"enemy_ready_turns":game.battle.enemy_ready_turns.duplicate(),"encounter_id":game.battle.encounter.get("id", ""), "weapon_id":game.battle.equipped_weapon_id, "weapon_type":game.battle.equipped_weapon_type, "inner_power":game.battle.qi.inner_power, "qi":game.battle.qi.amount, "player_hp":game.battle.player_hp if game.state=="battle" else HEALTH_RULES.max_health(game.progress.stats), "enemy_hp":mini(game.battle.enemy_hp,game.battle.enemy_max_hp), "turn":game.battle.turn, "selected":game.battle.selected, "selected_action":game.battle.selected_action, "enemy_qi":game.battle.enemy_qi.amount, "enemy_intent":game.battle.enemy_intent, "enemy_guard":game.battle.enemy_guard},
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
	var json = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path(slot))) != OK:return {}
	var parsed = json.data
	parsed=_upgrade_prologue_reward(_upgrade_health(_upgrade_enemy_balance(_upgrade_martial_arts(_upgrade_qingya_battle(parsed)))))
	return parsed if validate(parsed) else {}

func _upgrade_prologue_reward(value):
	# Only unpaid, ongoing prologue dialogue changes. Already-earned cash is retained.
	if not value is Dictionary or not value.get("prologue") is Dictionary:return value
	if value.prologue.get("active")!=true or value.prologue.get("paid")!=false:return value
	var upgraded: Dictionary=value.duplicate(true)
	var dialogue=upgraded.get("dialogue",{})
	if dialogue is Dictionary and dialogue.get("lines") is Array:
		for line in dialogue.lines:
			if line is Array and line.size()>1 and line[1] is String:line[1]=line[1].replace("삼천 문","오백 문").replace("3,000문","500문")
	var ui=upgraded.get("ui",{})
	if ui is Dictionary and ui.get("caption") is String:ui.caption=ui.caption.replace("삼천 문","오백 문").replace("3,000문","500문")
	return upgraded

func _upgrade_qingya_battle(value):
	# Retired boss metadata may remain even in a completed exploration save.
	if not value is Dictionary or not value.get("qingya_quest") is Dictionary or not value.get("battle") is Dictionary:return value
	if value.qingya_quest.get("version",1)!=1 or value.battle.get("encounter_id") not in ["qingya_chief","qingya_sentry"]:return value
	if value.battle.encounter_id=="qingya_sentry" and value.get("state")!="battle":return value
	if not is_number(value.battle.get("enemy_hp"),0,460):return value
	var migrated: Dictionary=value.duplicate(true)
	migrated.battle.encounter_id="qingya_chief"
	migrated.battle.enemy_hp=minf(float(migrated.battle.enemy_hp),280.0)
	migrated.battle.enemy_intent="basic_attack"
	migrated.battle.enemy_ready_turns={}
	if migrated.get("state")=="battle" and migrated.get("world") is Dictionary:
		migrated.qingya_quest.phase="fight_chief";migrated.qingya_quest.admitted=true;migrated.qingya_quest.captive_heard=true
		migrated.world.area="qingya_camp";migrated.world.position=[3540,1950];migrated.world.layout_version=1
	return migrated

func _upgrade_martial_arts(value):
	if not value is Dictionary:return value
	var upgraded: Dictionary=value.duplicate(true)
	if upgraded.has("progress"):upgraded.progress=game.progress.arts.upgrade_progress(upgraded.progress)
	if upgraded.get("battle") is Dictionary and upgraded.battle.has("selected_action"):
		var id=upgraded.battle.selected_action
		if id is String:upgraded.battle.selected_action=game.progress.arts.RETIRED.get(id,id)
	return upgraded

func _upgrade_enemy_balance(value):
	if not value is Dictionary or value.has("enemy_balance_revision") or not value.get("battle") is Dictionary:return value
	var old_caps={"":150,"bandit_sentry":180,"bandit_ringleader":240,"herb_ruffian":320,"training_student":180,"inn_warrior":240,"impostor_ma":350,"qingya_chief":280,"nanjing_nochil":420}
	var id=value.battle.get("encounter_id","")
	if id not in old_caps or not is_number(value.battle.get("enemy_hp"),0,old_caps[id]):return value
	var definition=game.battle.tutorial_enemy
	for entry in game.encounters():
		if entry.id==id:definition=entry;break
	var upgraded: Dictionary=value.duplicate(true);upgraded.enemy_balance_revision=1
	upgraded.battle.enemy_hp=mini(int(upgraded.battle.enemy_hp),int(LEGACY_HEALTH_CAPS.get(id,definition.max_hp)))
	# Old cached intentions may reference removed enemy arts or the previous weapon.
	if upgraded.battle.get("enemy_intent","") in ["bandit_chop","bandit_heavy_chop","soemok"]:
		upgraded.battle.enemy_intent="basic_attack"
	return upgraded

func _upgrade_health(value):
	if not value is Dictionary or value.has("health_revision") or not value.get("battle") is Dictionary:return value
	var progress=value.get("progress",{})
	if not progress is Dictionary:return value
	var stats=progress.get("stats",HEALTH_RULES.STARTING_STATS)
	if not stats is Dictionary:return value
	for key in HEALTH_RULES.STARTING_STATS:
		if not is_number(stats.get(key),0,STAT_MAX):return value
	var id=value.battle.get("encounter_id","")
	if id not in LEGACY_HEALTH_CAPS:return value
	var old_enemy=int(LEGACY_HEALTH_CAPS[id])
	if not is_number(value.battle.get("player_hp"),0,300) or not is_number(value.battle.get("enemy_hp"),0,old_enemy):return value
	var definition=game.battle.tutorial_enemy
	for entry in game.encounters():
		if entry.id==id:definition=entry;break
	var upgraded: Dictionary=value.duplicate(true)
	upgraded.health_revision=1
	var player_cap=HEALTH_RULES.max_health(stats);var enemy_cap=HEALTH_RULES.max_health(definition.stats)
	if value.get("state")=="battle":
		# Preserve remaining percentage in old combat saves; zero stays zero.
		upgraded.battle.player_hp=ceili(float(value.battle.player_hp)*player_cap/300.0)
		upgraded.battle.enemy_hp=ceili(float(value.battle.enemy_hp)*enemy_cap/old_enemy)
	else:
		upgraded.battle.player_hp=player_cap
		upgraded.battle.enemy_hp=mini(int(value.battle.enemy_hp),enemy_cap)
	return upgraded

func validate(d) -> bool:
	d=_upgrade_enemy_balance(_upgrade_martial_arts(_upgrade_qingya_battle(d)))
	if not d is Dictionary: return false
	if d.has("enemy_balance_revision") and not game.progress.whole(d.enemy_balance_revision,1,1):return false
	if d.has("changsha_reward_revision") and not game.progress.whole(d.changsha_reward_revision,0,1):return false
	if d.get("schema") != 1 and d.get("schema") != 2 and d.get("schema") != 3: return false
	if d.schema == 3 and not game.progress.valid(d.get("progress")): return false
	if d.has("suzhou_quests") and not game.suzhou_quests.valid(d.suzhou_quests):return false
	if d.has("hangzhou_quests") and not game.hangzhou_quests.valid(d.hangzhou_quests):return false
	if d.has("blackguild_story"):
		if not game.blackguild_story.valid(d.blackguild_story):return false
		if d.blackguild_story.phase!="available" and d.get("cuiyue_incident",{}).get("phase")!="completed":return false
	if d.has("cuiyue_incident"):
		if not game.cuiyue_incident.valid(d.cuiyue_incident):return false
		if d.cuiyue_incident.phase!="dormant":
			if d.get("nanjing_relief_quest",{}).get("phase")!="completed":return false
			for id in game.cuiyue_incident.data.prerequisites:
				if d.get("hangzhou_quests",{}).get(id,{}).get("phase")!="completed":return false
		if d.cuiyue_incident.phase=="completed" and "haomun" not in d.get("progress",{}).get("known_factions",[]):return false
	if d.has("ordinary_quests") and not game.ordinary_quests.valid(d.ordinary_quests):return false
	if d.has("trade_intro") and not game.trade_intro.valid(d.trade_intro): return false
	if d.has("bandit_story") and not game.bandit_story.valid(d.bandit_story): return false
	if d.has("alliance_story"):
		if not game.alliance_story.valid(d.alliance_story):return false
		if d.alliance_story.stage=="completed":
			if d.schema!=3 or d.alliance_story.received_art not in d.progress.learned:return false
			if d.get("alliance_visit",{}).get("phase") not in ["training_complete","closed"]:return false
		if d.alliance_story.stage in ["steward","instructor"] and d.get("alliance_visit",{}).get("phase")!="visiting":return false
	if d.has("alliance_visit") and not game.alliance_visit.valid(d.alliance_visit):return false
	if d.has("waterfront_quest") and not game.waterfront_quest.valid(d.waterfront_quest):return false
	if d.has("levy_quest") and not game.levy_quest.valid(d.levy_quest):return false
	if d.has("book_quest") and not game.book_quest.valid(d.book_quest):return false
	if d.has("cart_quest") and not game.cart_quest.valid(d.cart_quest):return false
	if d.has("silk_quest") and not game.silk_quest.valid(d.silk_quest):return false
	if d.has("nanjing_relief_quest"):
		if not game.nanjing_relief_quest.valid(d.nanjing_relief_quest):return false
		if d.nanjing_relief_quest.phase!="available":
			if d.get("alliance_story",{}).get("stage")!="completed":return false
			if d.get("alliance_visit",{}).get("phase") not in ["training_complete","closed"]:return false
			if d.get("alliance_story",{}).get("received_art","") not in d.get("progress",{}).get("learned",[]):return false
	if d.has("namgung_campaign"):
		if not game.namgung_campaign.valid(d.namgung_campaign):return false
		if d.namgung_campaign.phase!="available" and (not d.get("qingya_quest",{}).get("regret_seen",false) or d.get("waterfront_quest",{}).get("phase")!="completed" or d.get("progress",{}).get("faction_favor",{}).get("namgung",0)<10):return false
	if d.has("qingya_quest") and not game.qingya_quest.valid(d.qingya_quest):return false
	if d.has("herbalist_quest") and not game.herbalist_quest.valid(d.herbalist_quest):return false
	if d.has("plaque_quest") and not game.plaque_quest.valid(d.plaque_quest):return false
	if d.has("grain_quest") and not game.grain_quest.valid(d.grain_quest):return false
	if d.has("wages_quest") and not game.wages_quest.valid(d.wages_quest):return false
	if d.has("artisan_quest") and not game.artisan_quest.valid(d.artisan_quest):return false
	if d.has("duel_quest") and not game.duel_quest.valid(d.duel_quest):return false
	if d.has("impostor_quest") and not game.impostor_quest.valid(d.impostor_quest):return false
	if d.get("impostor_quest",{}).get("phase","available")!="available":
		if d.schema!=3:return false
		if d.get("alliance_visit",{}).get("phase") not in ["training_complete","closed"]:return false
		var taught=false
		for id in d.progress.learned:
			if game.progress.arts.get_skill(id).get("acquisition")=="alliance_instructor":taught=true
		if not taught:return false
	if d.has("inn_quest") and not game.inn_quest.valid(d.inn_quest):return false
	if d.has("duel_quest") and d.duel_quest.phase=="completed" and d.schema==3 and "josik_suwon" not in d.progress.learned:return false
	for field in ["world", "prologue", "chapter_one", "navigation", "dialogue", "ui", "visual", "service", "battle", "music"]:
		if not d.get(field) is Dictionary: return false
	if d.get("state") not in ["explore", "story", "choice", "service", "battle", "end"]: return false
	if not d.get("saved_at") is String or not is_number(d.get("money"), 0, 1000000000) or not is_number(d.get("chapter"), 0, 1): return false
	if not d.get("talked_captain") is bool or d.get("choice") not in ["", "treasure", "rescue"]: return false
	if d.world.get("area") not in ["dock", "deck", "changsha", "mountain_road", "wuchang", "alliance_office", "qingya_hamlet", "qingya_camp", "nanjing", "namgung_estate","suzhou","nanjing_suzhou_road","murong_estate","suzhou_hangzhou_canal","hangzhou","cuiyue_hall","blackguild_warehouse","blackguild_hall"]: return false
	var layout_version=d.world.get("layout_version",1)
	if not is_number(layout_version,1,3) or float(layout_version) not in [1.0,2.0,3.0]:return false
	var pos = d.world.get("position")
	if not pos is Array or pos.size() != 2: return false
	var limit: Vector2={"blackguild_hall":Vector2(3072,2048),"blackguild_warehouse":Vector2(3072,2048),"cuiyue_hall":Vector2(3072,2048),"hangzhou":Vector2(5888,5632) if layout_version>=2 else Vector2(5632,4096),"suzhou_hangzhou_canal":Vector2(3072,2048),"murong_estate":Vector2(4608,3072),"suzhou":Vector2(4608,3072),"nanjing_suzhou_road":Vector2(3840,2560),"changsha":Vector2(6144,4096),"mountain_road":(Vector2(2560,3200) if layout_version==3 else Vector2(4096,5120 if layout_version==2 else 10240)),"wuchang":Vector2(8192,7680),"alliance_office":Vector2(2048,1440),"qingya_hamlet":Vector2(4608,3072),"qingya_camp":Vector2(4608,3072),"namgung_estate":Vector2(4608,3300) if layout_version==3 else Vector2(6912,4608) if layout_version==2 else Vector2(4608,3072),"nanjing":Vector2(7424,5632) if layout_version>=3 else Vector2(6144,4096) if layout_version==2 else Vector2(4608,3072)}.get(d.world.area,Vector2(1280,720))
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
		if id not in game.trade_intro.IDS: return false
		var record = c.accepted_quests[id]
		if not record is Dictionary or record.size() != 2: return false
		var stage: String = "collect" if id == "changsha_dishes" else "deliver"
		if record != {"status":"active", "stage":stage} and record != {"status":"completed", "stage":"done"}: return false
	var n = d.navigation
	if n.get("facility","") not in ["","city_merchant","city_artisan","city_instructor"]:return false
	if not n.get("quest") is String or not n.get("completed") is Array: return false
	if n.quest != "" and (not game.quest_navigation.definitions.has(n.quest) or not game.quest_navigation.definitions[n.quest].stages.has(n.get("stage"))): return false
	for id in n.completed:
		if not id is String: return false
	var dialogue = d.dialogue
	if not dialogue.get("lines") is Array or not valid_callback(dialogue.get("done")) or not dialogue.get("cues") is Dictionary or not dialogue.get("listeners") is Array: return false
	if not is_number(dialogue.get("index"), 0, maxi(0, dialogue.lines.size() - 1)) and not dialogue.lines.is_empty(): return false
	for line in dialogue.lines:
		if not line is Array or line.size() < 2 or not game.PORTRAITS.ACTORS.has(line[0]) or not line[1] is String: return false
		if line.size() > 4: return false
		if line.size() > 2 and not line[2] is String and not game.dialogue_cast.valid_staging(line[2]): return false
		if line.size() > 3 and not game.dialogue_cast.valid_staging(line[3]): return false
	for id in dialogue.listeners:
		if not game.PORTRAITS.ACTORS.has(id): return false
	for value in dialogue.cues.values():
		if not game.music.TRACKS.has(value): return false
	for key in ["location", "objective", "hint", "caption", "ending_hp"]:
		if not d.ui.get(key) is String: return false
	if not d.ui.get("visible") is Dictionary: return false
	for key in ["top_hud", "bottom_hint", "caption", "exploration", "ending", "overview", "visual"]:
		if not d.ui.visible.get(key) is bool: return false
	if d.visual.get("mode") not in ["", "wreck", "river", "shore", "delivery", "bandit_road"] or not is_number(d.visual.get("phase"), 0, 1000000000) or not d.visual.get("paused") is bool: return false
	if not d.get("pending_service") is String or not is_number(d.get("service_tab"), 0, 1): return false
	if not d.service.is_empty() and d.service.get("id") not in ["city_merchant", "city_artisan", "city_instructor"]: return false
	if d.state == "service" and d.service.is_empty(): return false
	var enemy_maximum: int = HEALTH_RULES.max_health(game.battle.tutorial_enemy.stats)
	var encounter_id = d.battle.get("encounter_id", "")
	for q in game.suzhou_quests.quests:
		if not q.data.has("encounter"):continue
		var fighting=d.get("suzhou_quests",{}).get(q.ID,{}).get("phase","")=="battle"
		if fighting!=(d.state=="battle" and encounter_id==q.data.encounter.id):return false
	if encounter_id not in ["", "bandit_sentry", "bandit_ringleader", "herb_ruffian", "training_student", "inn_warrior", "impostor_ma", "qingya_sentry", "qingya_chief", "nanjing_nochil", "qingya_maunpyo", "sz_quay_extortionist", "sz_training_bai", "mr_exchange", "cuiyue_tak", "blackguild_enforcer"]: return false
	if (d.get("blackguild_story",{}).get("phase")=="battle")!=(d.state=="battle" and encounter_id=="blackguild_enforcer"):return false
	if (d.get("cuiyue_incident",{}).get("phase")=="battle")!=(d.state=="battle" and encounter_id=="cuiyue_tak"):return false
	for definition in game.encounters():
		if definition.id == encounter_id: enemy_maximum = HEALTH_RULES.max_health(definition.stats)
	if d.state=="battle" and encounter_id=="herb_ruffian" and d.get("herbalist_quest",{}).get("phase")!="rescue":return false
	if d.get("duel_quest",{}).get("phase")=="battle" and (d.state!="battle" or encounter_id!="training_student"):return false
	if d.state=="battle" and encounter_id=="training_student" and d.get("duel_quest",{}).get("phase")!="battle":return false
	if d.get("inn_quest",{}).get("phase")=="battle" and (d.state!="battle" or encounter_id!="inn_warrior"):return false
	if d.state=="battle" and encounter_id=="inn_warrior" and d.get("inn_quest",{}).get("phase")!="battle":return false
	if d.get("impostor_quest",{}).get("phase")=="battle" and (d.state!="battle" or encounter_id!="impostor_ma"):return false
	if d.state=="battle" and encounter_id=="impostor_ma" and d.get("impostor_quest",{}).get("phase")!="battle":return false
	if d.get("waterfront_quest",{}).get("phase")=="battle" and (d.state!="battle" or encounter_id!="nanjing_nochil"):return false
	if d.state=="battle" and encounter_id=="nanjing_nochil" and d.get("waterfront_quest",{}).get("phase")!="battle":return false
	if d.get("namgung_campaign",{}).get("phase")=="battle" and (d.state!="battle" or encounter_id!="qingya_maunpyo"):return false
	if d.state=="battle" and encounter_id=="qingya_maunpyo" and d.get("namgung_campaign",{}).get("phase")!="battle":return false
	var qphase=d.get("qingya_quest",{}).get("phase","")
	if qphase in ["fight_sentry","fight_chief"] and (d.state!="battle" or encounter_id!=("qingya_sentry" if qphase=="fight_sentry" else "qingya_chief")):return false
	if d.state=="battle" and encounter_id in ["qingya_sentry","qingya_chief"] and qphase!=("fight_sentry" if encounter_id=="qingya_sentry" else "fight_chief"):return false
	if d.has("bandit_story") and d.bandit_story.stage in ["battle_one", "battle_two"]:
		if d.state != "battle" or encounter_id != game.bandit_story.data.encounters[0 if d.bandit_story.stage == "battle_one" else 1].id: return false
	if d.has("health_revision") and not is_number(d.health_revision,1,1):return false
	var player_maximum=HEALTH_RULES.max_health(d.get("progress",{}).get("stats",HEALTH_RULES.STARTING_STATS))
	if not is_number(d.battle.get("player_hp"), 0, player_maximum) or not is_number(d.battle.get("enemy_hp"), 0, enemy_maximum) or not is_number(d.battle.get("turn"), 1, 10000) or not d.battle.get("selected") is bool: return false
	for key in ["ready_turns","enemy_ready_turns"]:
		var cooldowns=d.battle.get(key,{})
		if not cooldowns is Dictionary:return false
		for id in cooldowns:
			if not id is String or not game.progress.arts.definitions.has(id):return false
			var duration: int=int(game.progress.arts.get_skill(id).get("cooldown_turns",0))
			if duration<=0 or not game.progress.whole(cooldowns[id],0,int(d.battle.turn)+duration+1):return false
	if d.battle.has("selected_action"):
		if d.battle.selected_action not in ["", "basic_attack", "basic_defense"] and not game.battle.martial_arts.definitions.has(d.battle.selected_action): return false
		if d.schema == 3 and d.state == "battle" and d.battle.selected_action not in ["", "basic_attack", "basic_defense"] and d.battle.selected_action not in d.progress.loadout: return false
		if d.battle.selected != (d.battle.selected_action != ""): return false
	if d.battle.has("weapon_id"):
		if not d.battle.weapon_id is String or not game.battle.weapons.exists(d.battle.weapon_id): return false
		if d.battle.has("weapon_type") and game.battle.weapons.weapon_type(d.battle.weapon_id) != d.battle.weapon_type: return false
	if d.battle.has("weapon_type") and not game.battle.martial_arts.WEAPON_NAMES.has(d.battle.weapon_type): return false
	if d.schema >= 2:
		if not is_number(d.battle.get("inner_power"), 0, STAT_MAX) or not is_number(d.battle.get("qi"), 0, 500): return false
	if d.battle.has("enemy_guard"):
		if not game.progress.whole(d.battle.enemy_guard,0,20): return false
		if int(d.battle.enemy_guard) not in [0,20]: return false
	if d.battle.has("enemy_qi") or d.battle.has("enemy_intent"):
		if not game.progress.whole(d.battle.get("enemy_qi"),0,500): return false
		var allowed: Array = ["basic_attack","basic_defense"]+game.battle.tutorial_enemy.skills
		for definition in game.encounters():
			if definition.id == encounter_id: allowed = ["basic_attack","basic_defense"] + definition.skills
		if d.battle.get("enemy_intent") not in allowed: return false
		var stats: Dictionary = game.battle.tutorial_enemy.stats
		var enemy_weapon: String = str(game.battle.tutorial_enemy.weapon)
		for definition in game.encounters():
			if definition.id == encounter_id:
				stats = definition.stats
				enemy_weapon = definition.weapon
		var enemy_action: Dictionary = game.battle.combat.action(d.battle.enemy_intent,stats,enemy_weapon)
		if enemy_action.is_empty() or (d.state == "battle" and enemy_action.cost > d.battle.enemy_qi): return false
		if d.state=="battle" and game.battle.combat.cooldown_remaining(d.battle.enemy_intent,int(d.battle.turn),d.battle.get("enemy_ready_turns",{}))>0:return false
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
	var adjustment=reward_adjustment(d)
	game.money = int(d.money)+adjustment
	if d.schema == 3: game.progress.restore(d.progress)
	game.battle.player_stats = game.progress.stats.duplicate()
	game.battle.player_max_hp = HEALTH_RULES.max_health(game.progress.stats)
	game.battle.player_hp = game.battle.player_max_hp
	game.battle.set_loadout(game.progress.loadout)
	if d.has("bandit_story"): game.bandit_story.restore(d.bandit_story)
	if d.has("alliance_visit"):game.alliance_visit.restore(d.alliance_visit)
	var encounter: Dictionary = {}
	for definition in game.encounters():
		if definition.id == d.battle.get("encounter_id", ""): encounter = definition
	game.battle.set_encounter(encounter)
	if d.battle.has("weapon_id"): game.battle.equip_weapon_item(d.battle.weapon_id)
	else: game.battle.equip_weapon(d.battle.get("weapon_type", "sword"))
	game.talked_captain = d.talked_captain
	var story=d.get("alliance_story",{})
	if story.is_empty():
		story={"stage":"steward" if game.alliance_visit.phase=="visiting" else "dormant","received_art":""}
		if game.alliance_visit.phase in ["training_complete","closed"]:
			for id in game.alliance_story.ARTS:
				if id in game.progress.learned:story={"stage":"completed","received_art":id};break
	game.alliance_story.restore(story)
	game.waterfront_quest.restore(d.get("waterfront_quest",{"phase":"available"}))
	game.levy_quest.restore(d.get("levy_quest",{"phase":"available"}))
	game.book_quest.restore(d.get("book_quest",{"phase":"available"}))
	game.cart_quest.restore(d.get("cart_quest",{"phase":"available"}))
	game.silk_quest.restore(d.get("silk_quest",{"phase":"available"}))
	game.nanjing_relief_quest.restore(d.get("nanjing_relief_quest",{"phase":"available"}))
	game.namgung_campaign.restore(d.get("namgung_campaign",{"phase":"available"}))
	if d.has("qingya_quest"):game.qingya_quest.restore(d.qingya_quest)
	game.herbalist_quest.restore(d.get("herbalist_quest",{"phase":"available"}))
	game.plaque_quest.restore(d.get("plaque_quest",{"phase":"available","checked":[]}))
	game.suzhou_quests.restore(d.get("suzhou_quests",{}))
	game.hangzhou_quests.restore(d.get("hangzhou_quests",{}))
	game.cuiyue_incident.restore(d.get("cuiyue_incident",{}))
	game.blackguild_story.restore(d.get("blackguild_story",{}))
	game.grain_quest.restore(d.get("grain_quest",{"phase":"available"}))
	game.wages_quest.restore(d.get("wages_quest",{"phase":"available"}))
	game.artisan_quest.restore(d.get("artisan_quest",{"phase":"available"}))
	game.duel_quest.restore(d.get("duel_quest",{"phase":"available","result":""}))
	game.impostor_quest.restore(d.get("impostor_quest",{"phase":"available"}))
	game.inn_quest.restore(d.get("inn_quest",{"phase":"available","heard":[],"branch":"","defeats":0}))
	game.herbalist_quest.battle_active=d.state=="battle" and d.battle.get("encounter_id","")=="herb_ruffian"
	game.exploration.load_area(d.world.area)
	game.exploration.player.position = Vector2(d.world.position[0], d.world.position[1])
	if d.world.area=="hangzhou" and int(d.world.get("layout_version",1))<2:
		# The city is unchanged relative to itself; only the northern approach is new.
		game.exploration.player.position.y+=1280.0
	if d.world.area=="nanjing" and int(d.world.get("layout_version",1))<3:
		if int(d.world.get("layout_version",1))<2:
			game.exploration.player.position=game.exploration.city_point(game.exploration.city_data.spawn)
		else:game.exploration.player.position+=Vector2(640,1200)
	if d.world.area=="mountain_road":
		var previous_layout=int(d.world.get("layout_version",1))
		if previous_layout==1:game.exploration.player.position.y*=.5
		if previous_layout<3:game.exploration.player.position*=.625
	if d.world.area=="namgung_estate":
		var previous_layout=int(d.world.get("layout_version",1))
		if previous_layout<2:game.exploration.player.position*=1.5
		if previous_layout<3:game.exploration.player.position*=Vector2(1536.0/2304.0,1100.0/1536.0)
	if d.world.area in ["changsha","mountain_road","wuchang","alliance_office","qingya_hamlet","qingya_camp","nanjing","namgung_estate","suzhou","nanjing_suzhou_road","murong_estate","suzhou_hangzhou_canal","hangzhou","cuiyue_hall","blackguild_warehouse","blackguild_hall"]:
		game.exploration.player.position = game.exploration.safe_player_position(game.exploration.player.position)
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
	game.trade_intro.restore(d.get("trade_intro", {"completed":[]}))
	game.ordinary_quests.restore(d.get("ordinary_quests",{"records":{},"pending":{}}))
	game.quest_navigation.facility_id=d.navigation.get("facility","")
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
		var inner_power: int = int(d.battle.inner_power) if d.schema >= 2 else int(game.battle.Rules.STARTING_STATS.inner)
		game.battle.begin(inner_power)
		# Legacy saves predate costs: regenerate once per elapsed player turn.
		var amount: int = int(d.battle.qi) if d.schema >= 2 else mini(500, inner_power * int(d.battle.turn))
		game.battle.qi.restore(inner_power, amount)
		game.battle.player_hp = int(d.battle.player_hp)
		game.battle.enemy_hp = int(d.battle.enemy_hp)
		game.battle.turn = int(d.battle.turn)
		game.battle.ready_turns=d.battle.get("ready_turns",{}).duplicate()
		game.battle.enemy_ready_turns=d.battle.get("enemy_ready_turns",{}).duplicate()
		if d.battle.has("enemy_qi"):
			game.battle.enemy_qi.restore(int(game.battle.enemy_stats.inner),int(d.battle.enemy_qi))
			game.battle.enemy_intent = d.battle.enemy_intent
			game.battle.enemy_guard = int(d.battle.get("enemy_guard",0))
			game.battle._update_intent()
		else:
			# Older turns predate enemy resource accounting; give one starting allocation.
			game.battle._prepare_enemy()
		game.battle._update_slots()
		game.battle._update_hp()
		game.battle.turn_label.text = "내 차례 · %d번째 교전" % game.battle.turn
		if d.battle.selected:
			if d.battle.get("selected_action", "samjae") == "basic_attack": game.battle.select_basic_attack()
			else: game.battle.select_skill(str(d.battle.get("selected_action", "samjae")))
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
	if adjustment>0:game.adventure_ui.notify("장사 의뢰 보수 조정 차액 · +%d문" % adjustment,"coin")
	return true

func reward_adjustment(data: Dictionary) -> int:
	if int(data.get("changsha_reward_revision",0))>=1:return 0
	var adjustment:=0
	var records: Dictionary=data.get("ordinary_quests",{}).get("records",{})
	for id in ["changsha_pages","changsha_waterway"]:
		if records.get(id,{}).get("status")=="completed":adjustment+=50
	return adjustment

# Presentation metadata only: do not expose quest objectives or branch spoilers.
func area_name(id: String) -> String:
	return {"blackguild_hall":"흑도방 본당","blackguild_warehouse":"운하 창고","cuiyue_hall":"항주 · 취월루", "dock":"청류진 나루", "deck":"호송선", "changsha":"장사", "mountain_road":"장사–무창 산길", "wuchang":"무창", "alliance_office":"총무당", "qingya_hamlet":"삼거리 산촌", "qingya_camp":"청애채", "nanjing":"남경", "namgung_estate":"남궁세가", "murong_estate":"모용세가", "hangzhou":"항주", "suzhou_hangzhou_canal":"강남 운하길", "suzhou":"소주", "nanjing_suzhou_road":"남경–소주 산길"}.get(id, "이름 없는 길")

func saved_time(data: Dictionary, file_path: String) -> String:
	var value = data.get("saved_at", "")
	var stamp: String = value if value is String else ""
	if stamp.length() >= 19 and stamp.substr(0, 4).is_valid_int():
		return stamp.left(19).replace("T", " ")
	var local_epoch = FileAccess.get_modified_time(file_path) + int(Time.get_time_zone_from_system().bias) * 60
	return Time.get_datetime_string_from_unix_time(local_epoch).replace("T", " ")

func title_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for slot in range(1, SLOT_COUNT + 1):
		var data = read_slot(slot)
		if not data.is_empty():
			entries.append({"slot":slot, "kind":"manual", "time":saved_time(data, path(slot)), "place":area_name(data.world.area)})
	var checkpoint = game.prologue.read_checkpoint()
	if not checkpoint.is_empty():
		entries.append({"slot":0, "kind":"auto", "time":saved_time(checkpoint, game.prologue.SAVE_PATH), "place":"장사"})
	entries.sort_custom(func(a, b):
		if a.time == b.time:return a.slot > b.slot
		return a.time > b.time)
	return entries

func load_title_entry(entry: Dictionary) -> bool:
	if entry.get("kind") == "manual": return load_slot(int(entry.get("slot", 0)))
	if entry.get("kind") == "auto" and not game.prologue.read_checkpoint().is_empty():
		game.prologue.resume()
		return true
	error = "저장 파일을 읽을 수 없습니다. 다른 저장을 골라 주세요."
	return false
