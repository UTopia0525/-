extends SceneTree
var game
const Combat=preload("res://scripts/combat_actions.gd")
const Qi=preload("res://scripts/inner_qi.gd")
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("INN_QUEST: "+message)
func drain() -> void:
	for i in range(80):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func actor(id: String):
	for npc in game.exploration.ambient_nodes:
		if npc.get_meta("npc_id")==id:return npc
	return null
func approach(id: String) -> void:
	var w=game.exploration;var npc=actor(id)
	check(is_instance_valid(npc),"actor present: "+id)
	if not is_instance_valid(npc):return
	var path=w.path_to(npc.position,true);check(not path.is_empty(),"approach reachable")
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id","")==id,"F chooses intended NPC")
	var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=true
	Input.parse_input_event(e);await process_frame
	e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await process_frame
func wait_turn() -> void:
	var deadline=Time.get_ticks_msec()+20000
	while game.battle.busy and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(not game.battle.busy,"battle animation finishes")
func roundtrip(slot: int) -> void:
	var state=game.inn_quest.snapshot()
	check(game.save_system.write_slot(slot),"stable phase save: "+game.save_system.error)
	check(game.save_system.load_slot(slot) and game.inn_quest.snapshot()==state,"quest phase/outcome restored")
	await process_frame
func simulation(stats: Dictionary,weapon: String,skill: String,e: Dictionary) -> Dictionary:
	var c=Combat.new();var pq=Qi.new();var eq=Qi.new();pq.start(stats.inner);eq.start(e.stats.inner)
	var hp=300;var ehp=int(e.max_hp)
	for turn in range(1,81):
		var intent=c.enemy_plan(e.stats,e.weapon,e.skills,eq.amount,turn)
		var enemy=c.action(intent,e.stats,e.weapon)
		var action=c.action("basic_attack",stats,weapon)
		for id in [skill,"samjae"]:
			var option=c.action(id,stats,weapon)
			if not option.is_empty() and option.cost<=pq.amount and option.raw>action.raw:action=option
		check(pq.spend(action.cost),"player action affordable")
		ehp=maxi(0,ehp-c.damage(action.raw,e.stats.constitution,e.weapon,enemy.guard))
		if ehp==0:return {"win":true,"turns":turn,"hp":hp}
		check(eq.spend(enemy.cost),"enemy action affordable")
		hp=maxi(0,hp-c.damage(enemy.raw,stats.constitution,weapon,action.guard))
		if hp==0:return {"win":false,"turns":turn,"hp":hp}
		pq.recover_turn();eq.recover_turn()
	return {"win":false,"turns":80,"hp":hp}
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var q=game.inn_quest;var w=game.exploration
	check(q.marker_for(q.GIVER)=="!" and actor(q.WORKER)==null,"offer marked, guests absent before acceptance")
	q.mediate();q.challenge();check(q.phase=="available","cannot skip accounts")
	await approach(q.GIVER);drain();game.adventure_ui.secondary_action();drain()
	check(q.phase=="available" and actor(q.WARRIOR)==null,"decline leaves offer")
	game.herbalist_quest.accept();drain();game.artisan_quest.accept();drain();game.duel_quest.accept();drain()
	var others=[game.herbalist_quest.snapshot(),game.artisan_quest.snapshot(),game.duel_quest.snapshot()]
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain()
	check(q.phase=="listening" and w.ambient_nodes.size()==14,"all four regional quests accepted concurrently")
	for id in [q.WORKER,q.WARRIOR]:
		var npc=actor(id);var visual=Rect2(npc.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
		for bounds in w.scenery_bounds:check(not visual.grow(6).intersects(bounds),"guest clears buildings")
		for road in w.city_data.road_centers:check(not Rect2(road[0]*4,road[1]*4,road[2]*4,road[3]*4).has_point(npc.position),"guest off main road")
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("active")
	check(game.adventure_ui.entries.has(q.ID),"accepted quest appears in Q")
	game.adventure_ui.select_quest(q.ID)
	check(game.adventure_ui.body.text.contains("150문"),"journal advertises approved reward")
	game.adventure_ui.close_menu()
	check(not q.goal(w).is_empty(),"current guest guide has a goal")
	await roundtrip(1)
	await approach(q.WARRIOR)
	check(q.heard.is_empty() and not game.save_system.write_slot(9),"account commits only at final line, dialogue save blocked")
	drain();check(q.heard==[q.WARRIOR],"warrior may be heard first")
	q.mediate();check(q.phase=="listening","one account cannot resolve")
	await approach(q.WARRIOR);drain();check(q.heard.size()==1,"repeat account not duplicated")
	await roundtrip(2)
	await approach(q.WORKER);drain()
	check(q.phase=="deciding" and game.adventure_ui.mode=="choice","both accounts unlock choice")
	game.adventure_ui.close_menu();await roundtrip(3)
	var before=game.progress.stats.duplicate();var fame: int=game.progress.fame;var money: int=game.money
	q.choose_resolution();game.adventure_ui.primary_action()
	var portraits=game.dialogue_cast.portrait_choices.values()
	check(portraits.size()==4,"four people shown during mediation")
	for portrait in portraits:check(portraits.count(portrait)==1,"each conversation participant has unique art")
	drain();check(q.phase=="ready" and q.branch=="talk" and game.money==money,"mediation guarantees report without payout")
	check(q.marker_for(q.GIVER)=="?","report marker")
	await roundtrip(4)
	await approach(q.GIVER)
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(game.money==money,"last report line still unpaid");game.advance_dialogue()
	check(q.phase=="completed" and game.money==money+150,"report pays 150 once")
	check(game.progress.stats==before and game.progress.fame==fame,"no stat or fame reward")
	check(actor(q.WORKER)==null and actor(q.WARRIOR)==null and actor(game.duel_quest.STUDENT)!=null,"remove only own event guests")
	check(others==[game.herbalist_quest.snapshot(),game.artisan_quest.snapshot(),game.duel_quest.snapshot()],"other three quest states untouched")
	q._complete();check(game.money==money+150,"duplicate report blocked")
	await roundtrip(5)
	# Rewind for real defeat, retry, and victory using the shared battle engine.
	check(game.save_system.load_slot(3),"rewind decision")
	q.choose_resolution();game.adventure_ui.secondary_action();drain()
	check(q.in_battle() and game.battle.enemy_hp==240 and game.battle.enemy_qi.amount==10,"guest encounter shares qi rules")
	game.battle.player_hp=1;game.battle.select_basic_attack();game.battle.use_selected();await wait_turn();drain()
	check(q.phase=="deciding" and q.defeats==1 and game.money==money,"loss returns choice without penalty")
	await roundtrip(6)
	q.choose_resolution();game.adventure_ui.primary_action();drain()
	check(q.phase=="ready" and q.branch=="talk","mediation remains available after loss")
	check(game.save_system.load_slot(6),"rewind loss for retry")
	for key in game.progress.stats:game.progress.stats[key]=20
	q.choose_resolution();game.adventure_ui.secondary_action();drain()
	check(game.battle.player_hp==300 and game.battle.qi.amount==20,"retry starts in full condition")
	for i in range(30):
		if game.state!="battle":break
		game.battle.select_samjae();game.battle.use_selected();await wait_turn()
	drain();check(q.phase=="ready" and q.branch=="duel","real duel victory enables report")
	await approach(q.GIVER);drain();check(q.phase=="completed" and game.money==money+150,"duel receives same 150 reward")
	var old=game.save_system.capture();old.erase("inn_quest")
	check(game.save_system.validate(old),"legacy save without inn accepted")
	var file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(8) and q.phase=="available","legacy restore defaults available")
	check(not q.valid({"phase":"deciding","heard":[q.WORKER],"branch":"","defeats":0}),"missing account rejected")
	check(not q.valid({"phase":"ready","heard":[q.WORKER,q.WARRIOR],"branch":"","defeats":0}),"ready requires branch")
	check(not q.valid({"phase":"listening","heard":[q.WORKER,q.WORKER],"branch":"","defeats":0}),"duplicate accounts rejected")
	var combat=Combat.new();var enemy: Dictionary=q.data.encounter;var cases=0
	for id in enemy.skills:check(combat.arts.can_learn(id,enemy.stats),"enemy meets skill requirements")
	for id in game.progress.arts.definitions:
		var art: Dictionary=game.progress.arts.get_skill(id)
		if art.get("acquisition")!="city_instructor":continue
		var stats: Dictionary=game.progress.RULES.STARTING_STATS.duplicate()
		for key in art.requirements.stats:stats[key]=maxi(stats[key],art.requirements.stats[key])
		var total=0
		for value in stats.values():total+=int(value)
		stats.insight+=maxi(0,100-total)
		var weapon: String=game.progress.weapons.DEFAULT_BY_TYPE[art.required_weapon_type]
		check(simulation(stats,weapon,id,enemy).win,"minimum learning and realm floor clears: "+id);cases+=1
		check(simulation({"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20},weapon,id,enemy).win,"balanced realm floor clears: "+id);cases+=1
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_INN_QUEST: "+("FAIL" if failed else "PASS")+" · balance cases "+str(cases));quit(1 if failed else 0)
