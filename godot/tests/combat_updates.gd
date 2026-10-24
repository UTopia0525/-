extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.
const Combat = preload("res://scripts/combat_actions.gd")
const Icons = preload("res://scripts/catalog_icons.gd")
const Progress = preload("res://scripts/player_progress.gd")
const Qi = preload("res://scripts/inner_qi.gd")
var combat = Combat.new()
var failed := false
var report: Array = []
var game
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	if not ok:
		failed = true
		push_error("COMBAT_UPDATES: " + text)
func simulate(stats: Dictionary, weapon: String, skill: String, e: Dictionary, defend: bool) -> Dictionary:
	var pq = Qi.new(); pq.start(int(stats.inner))
	var eq = Qi.new(); eq.start(int(e.stats.inner))
	var hp := 300
	var ehp: int = e.max_hp
	var used := {"basic_attack":0,"basic_defense":0,"bandit_chop":0,"bandit_heavy_chop":0}
	for turn in range(1,81):
		var intent := combat.enemy_plan(e.stats,e.weapon,e.skills,eq.amount,turn)
		var opponent := combat.action(intent,e.stats,e.weapon)
		used[intent] += 1
		var a := combat.action("basic_attack",stats,weapon)
		for id in [skill,"samjae"]:
			var candidate := combat.action(id,stats,weapon)
			if not candidate.is_empty() and candidate.cost <= pq.amount and candidate.raw > a.raw: a = candidate
		# Deliberately simple first-play response, not an optimal search.
		if defend and intent not in ["basic_attack","basic_defense"] and combat.damage(a.raw,e.stats.constitution,e.weapon,opponent.guard) < ehp:
			a = combat.action("basic_defense",stats,weapon)
		check(pq.spend(int(a.cost)) and eq.spend(int(opponent.cost)),"both actors can afford the committed actions")
		ehp = maxi(0,ehp-combat.damage(a.raw,e.stats.constitution,e.weapon,opponent.guard))
		if ehp == 0: return {"win":true,"turns":turn,"hp":hp,"enemy_actions":used}
		hp = maxi(0,hp-combat.damage(opponent.raw,stats.constitution,weapon,a.guard))
		if hp == 0: return {"win":false,"turns":turn,"hp":0,"enemy_actions":used}
		pq.recover_turn();eq.recover_turn()
	return {"win":false,"turns":80,"hp":hp}
func wait_turn() -> void:
	var deadline := Time.get_ticks_msec()+7000
	while game.battle.busy and Time.get_ticks_msec()<deadline: await create_timer(.04).timeout
	check(not game.battle.busy,"one committed exchange completes")
func drain() -> void:
	while not game.dialogue_lines.is_empty(): game.advance_dialogue()

func run() -> void:
	var p = Progress.new()
	for id in combat.arts.definitions.keys()+p.weapons.definitions.keys()+p.elixirs.keys()+["basic_attack","basic_defense","약재 포장용 옷감","돌려줄 약사발","무관의 수련봉 자루"]:
		check(Icons.texture(str(id)) != null,"catalogue icon exists: "+str(id))
	check(combat.damage(70,25,"refined_sword")==34 and combat.damage(70,25,"refined_sword",20)==27 and combat.damage(70,25,"refined_sword",70)==10,"round once; passive and one active guard multiply")
	var old := p.snapshot();old.loadout=["samjae","",""]
	check(p.valid(old),"three-slot legacy save validates")
	p.restore(old);check(p.loadout==["basic_attack","samjae","",""],"legacy art positions survive after fixed basic is prepended")
	p.reset();check(p.assign("",0) and p.assign("",1),"both basic actions are removable")
	var encounters: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/changsha_bandit_story.json")).encounters
	for e in encounters:
		for id in e.skills: check(combat.arts.can_learn(id,e.stats),"enemy meets its own skill requirements")
	for id in p.arts.definitions:
		if id == "samjae" or p.arts.get_skill(id).get("acquisition") != "city_instructor": continue
		var skill: Dictionary = p.arts.get_skill(id)
		var stats: Dictionary = p.RULES.STARTING_STATS.duplicate()
		for key in skill.requirements.stats: stats[key] = maxi(int(stats[key]),int(skill.requirements.stats[key]))
		var total := 0
		for value in stats.values(): total += int(value)
		stats.insight += maxi(0,100-total)
		check(p.arts.can_learn(id,stats),"fixture satisfies learning requirements "+id)
		var weapon: String = p.weapons.DEFAULT_BY_TYPE[skill.required_weapon_type]
		var equipment: Array = [weapon]
		for candidate in p.weapons.definitions:
			if p.weapons.weapon_type(candidate) == skill.required_weapon_type and candidate not in equipment: equipment.append(candidate)
		for equipped in equipment:
			for defend in [false,true]:
				for e in encounters:
					var r := simulate(stats,equipped,id,e,defend)
					r.merge({"skill":id,"weapon":equipped,"enemy":e.id,"reactive_defense":defend,"stats":stats})
					report.append(r)
					check(r.win and r.hp >= 100,"first-clear minimum-growth build retains a safety margin: "+id+" / "+e.id)
	# Weakest physical growth floor: even basic attacks alone should be forgiving.
	var low: Dictionary = p.RULES.STARTING_STATS.duplicate();low.insight=60
	for e in encounters:
		var r := simulate(low,"plain_iron_sword","",e,false)
		report.append(r.merged({"skill":"basic-only floor","enemy":e.id}))
		check(r.win,"basic-only growth floor remains clearable")
	var file := FileAccess.open("user://combat_balance_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	game = load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_battle(encounters[1])
	var b = game.battle
	check(b.enemy_qi.amount==8 and b.enemy_intent=="basic_attack" and b.intent_label.text.contains("적이 공격을 하려고 한다"),"enemy starts at inner power and telegraphs before input")
	b.select_skill("basic_defense");b.use_selected();b.use_selected();await wait_turn()
	check(b.turn==2 and b.player_hp==294 and b.enemy_qi.amount==16 and b.enemy_intent=="basic_attack","defense, enemy recovery and costly next intent")
	var intent: String = b.enemy_intent;var amount: int = b.enemy_qi.amount
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 10) and game.save_system.load_slot(10),"save/load enemy combat state")
	check(b.enemy_qi.amount==amount and b.enemy_intent==intent and b.selected_action=="basic_defense","save preserves locked enemy intent, qi and defense selection")
	var invalid: Dictionary = game.save_system.capture();invalid.battle.enemy_qi=0;invalid.battle.enemy_intent="bandit_heavy_chop"
	check(not game.save_system.validate(invalid),"cannot load an unaffordable locked enemy technique")
	b.select_basic_attack();b.use_selected();await wait_turn()
	check(b.turn==3 and b.enemy_qi.amount==24 and b.enemy_intent=="basic_defense","enemy banks qi until it can afford its art")
	b.select_skill("samjae");b.use_selected();await wait_turn()
	check(b.turn==4 and b.enemy_qi.amount==32 and b.enemy_intent=="bandit_heavy_chop","enemy defense costs0 and recovers inner once")
	b.cancel();b.set_loadout(["gwanpung","","",""]);b.equip_weapon("none");b.begin()
	check(not b.skill_buttons[0].disabled and b.skill_buttons[0].text.contains("임시 기본공격"),"incompatible loadout gets contextual free action")
	b.select_slot(0);check(b.selected_action=="basic_attack","fallback is selectable without forcing a permanent slot")
	b.cancel();b.set_encounter({});b.set_loadout(["basic_attack","basic_defense","samjae",""]);b.begin();b.player_hp=1
	b.select_basic_attack();b.use_selected();await wait_turn()
	check(not b.running and not b.use_button.disabled and b.use_button.text=="다시 도전","tutorial defeat provides retry instead of a dead end")
	b.use_selected();check(b.running and b.player_hp==300 and b.qi.amount==10,"tutorial retry restores normal starting resources")
	b.cancel();b.set_encounter({"stats":b.Rules.STARTING_STATS.duplicate(),"constitution":10,"weapon":"plain_iron_sword","skills":["samjae"],"max_hp":500})
	b.set_loadout(["basic_attack","basic_defense","samjae",""]);b.begin()
	b.select_basic_attack();b.use_selected();await wait_turn()
	check(b.enemy_hp==482 and b.enemy_guard==20,"enemy sword guard begins after its first attack")
	b.select_basic_attack();b.use_selected();await wait_turn()
	check(b.enemy_hp==468 and b.enemy_guard==20,"enemy sword guard protects the next player attack")
	b.select_basic_attack();b.use_selected();await wait_turn()
	check(b.enemy_hp==463 and b.enemy_guard==0,"enemy basic defense replaces rather than adds to sword guard")
	game.reset();game.start_city()
	check(game.save_system.validate(game.save_system.capture()),"new game after a boss resets stale enemy intent for saves")
	game.progress.stats = {"strength":12,"agility":14,"constitution":12,"inner":14,"insight":55}
	game.progress.learned.append("cheongpung")
	game.progress.owned_weapons.append("refined_sword")
	game.progress.loadout = ["basic_attack","basic_defense","samjae","cheongpung"]
	game.battle.equip_weapon_item("refined_sword")
	game.chapter_number=1;game.chapter_one.intro_started=true;game.chapter_one.intro_complete=true;game.chapter_one.banner_shown=true
	var story = game.bandit_story
	story.maybe_start();drain()
	story.handle_interaction("bandit_officer");drain()
	story.handle_interaction("bandit_muster");drain()
	for fight in range(2):
		check(game.state=="battle" and b.player_hp==300,"first-play campaign starts each battle fully restored")
		var attempts := 0
		while game.state=="battle" and attempts<30:
			var a := combat.action("basic_attack",game.progress.stats,"refined_sword")
			for id in ["samjae","cheongpung"]:
				var candidate := combat.action(id,game.progress.stats,"refined_sword")
				if candidate.cost<=b.qi.amount and candidate.raw>a.raw: a=candidate
			b.select_skill(a.id);b.use_selected();await wait_turn();attempts+=1
		check(story.stage in ["after_first","after_second"] and b.player_hp>0,"normal-growth campaign victory without replay or retreat")
		drain()
	check(story.stage=="report","two first-attempt victories reach report")
	story.handle_interaction("bandit_officer");drain()
	check(story.stage=="completed" and story.reward_granted and game.money==500,"first-play campaign pays once without a reload")
	game.reset();await create_timer(1.0).timeout
	for voice in game.music.players: voice.stop();voice.stream=null
	await create_timer(.25).timeout
	game.queue_free();await process_frame
	print("GODOT_COMBAT_UPDATES: "+("FAIL" if failed else "PASS")+" / balance cases="+str(report.size()))
	quit(1 if failed else 0)
