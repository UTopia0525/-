extends SceneTree
var game
const Combat=preload("res://scripts/combat_actions.gd")
const Qi=preload("res://scripts/inner_qi.gd")
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("IMPOSTOR_QUEST: "+message)
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
	if id==game.wages_quest.GIVER and game.adventure_ui.window.visible:
		game.adventure_ui.secondary_action()
		if game.adventure_ui.window.visible:game.adventure_ui.primary_action()
func wait_turn() -> void:
	var deadline=Time.get_ticks_msec()+20000
	while game.battle.busy and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(not game.battle.busy,"battle animation finishes")
func roundtrip(slot: int) -> void:
	var state=game.impostor_quest.snapshot()
	check(game.save_system.write_slot(slot),"stable phase save: "+game.save_system.error)
	check(game.save_system.load_slot(slot) and game.impostor_quest.snapshot()==state,"quest phase/outcome restored")
	await process_frame
func simulation(stats: Dictionary,weapon: String,skill: String,e: Dictionary) -> Dictionary:
	var c=Combat.new();var pq=Qi.new();var eq=Qi.new();pq.start(stats.inner);eq.start(e.stats.inner)
	var hp=300;var ehp=int(e.max_hp)
	for turn in range(1,81):
		var intent=c.enemy_plan(e.stats,e.weapon,e.skills,eq.amount,turn)
		var enemy=c.action(intent,e.stats,e.weapon)
		var action=c.action("basic_attack",stats,weapon)
		for id in [skill]:
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
	var q=game.impostor_quest;var w=game.exploration
	check(q.status()=="locked" and q.marker_for(q.GIVER)=="","hidden before teaching")
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("available")
	check(not game.adventure_ui.entries.has(q.ID),"locked quest absent from journal");game.adventure_ui.close_menu()
	q.accept();check(q.phase=="available","direct accept cannot bypass gate")
	await approach(q.GIVER);drain();check(game.adventure_ui.mode!="choice" or not game.adventure_ui.window.visible,"locked giver has normal talk")
	check(actor(q.SUSPECT)==null and actor(q.MESSENGER)==null,"event actors absent")
	game.progress.learned.append("hoeryu");check(not q.eligible(),"skill alone does not bypass story")
	game.progress.learned.erase("hoeryu");game.alliance_visit.grant_visit();game.alliance_visit.mark_training_complete()
	check(not q.eligible(),"teaching marker alone without received art insufficient")
	for id in game.progress.arts.definitions:
		if game.progress.arts.get_skill(id).get("acquisition")!="alliance_instructor":continue
		game.progress.learned.append(id);check(q.eligible(),"each of five arts unlocks quest: "+id);game.progress.learned.erase(id)
	game.progress.learned.append("hoeryu");q.refresh_world()
	check(q.marker_for(q.GIVER)=="!","available after actual teaching conditions")
	game.adventure_ui.open_favor();check(game.adventure_ui.rows.get_child_count()==0,"no faction before first favor gain");game.adventure_ui.close_menu()
	await approach(q.GIVER);drain();game.adventure_ui.secondary_action();drain()
	check(q.phase=="available","can decline")
	await roundtrip(1)
	game.herbalist_quest.accept();drain();game.artisan_quest.accept();drain();game.artisan_quest._farmer_done();game.duel_quest.accept();drain();game.inn_quest.accept();drain()
	var others=[game.herbalist_quest.snapshot(),game.artisan_quest.snapshot(),game.duel_quest.snapshot(),game.inn_quest.snapshot()]
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain()
	check(q.phase=="witness" and actor(q.SUSPECT)==null,"accepted investigation hides suspect")
	await roundtrip(2)
	await approach(q.WITNESS)
	check(game.dialogue_lines==q.data.scenes.witness and game.artisan_quest.phase=="dock","shared witness opens current inquiry without overwriting artisan quest")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	game.advance_dialogue();check(q.phase=="witness" and game.dialogue_lines==q.data.scenes.inspect,"document inspection required after testimony")
	drain();check(q.phase=="verify" and actor(q.SUSPECT)==null,"no suspect before official verification")
	check(game.artisan_quest.snapshot()==others[1],"shared witness preserves other quest progress")
	await roundtrip(3)
	await approach(q.GIVER)
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(actor(q.SUSPECT)==null,"suspect not spawned before final verification line");game.advance_dialogue()
	check(q.phase=="confront" and actor(q.SUSPECT)!=null,"verification reveals suspect")
	var npc=actor(q.SUSPECT);var visual=Rect2(npc.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
	for bounds in w.scenery_bounds:check(not visual.grow(6).intersects(bounds),"suspect clears buildings")
	await roundtrip(4)
	await approach(q.SUSPECT);drain();check(q.in_battle(),"confrontation starts battle")
	check(not game.save_system.write_slot(9),"battle saves blocked")
	game.battle.player_hp=1;game.battle.select_basic_attack();game.battle.use_selected();await wait_turn();drain()
	check(q.phase=="confront" and game.money==0 and game.progress.fame==0,"loss keeps investigation and grants nothing")
	await roundtrip(5)
	# A learned intermediate is not auto-equipped: fight with starting samjae at realm100.
	for key in game.progress.stats:game.progress.stats[key]=20
	await approach(q.SUSPECT);drain();check(game.battle.player_hp==300,"retry full health")
	for i in range(40):
		if game.state!="battle":break
		game.battle.select_samjae();game.battle.use_selected();await wait_turn()
	drain();check(q.phase=="ready" and game.money==0,"victory needs official report")
	check(actor(q.SUSPECT)==null and actor(q.MESSENGER)==null,"arrest removes criminal, messenger waits for payment")
	await roundtrip(6)
	var stats=game.progress.stats.duplicate()
	await approach(q.GIVER)
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(game.money==0 and game.progress.fame==0 and game.progress.favor_for("murim_alliance")==0,"no reward before final official line")
	game.advance_dialogue()
	check(game.money==250 and q.phase=="thanks" and actor(q.MESSENGER)!=null,"pay first then event messenger appears automatically")
	check(game.dialogue_cast.active_actor==q.MESSENGER and game.progress.fame==0 and game.progress.favor_for("murim_alliance")==0,"gratitude starts before fame/favor")
	check(not game.save_system.write_slot(9),"gratitude dialogue saves blocked")
	var portraits=game.dialogue_cast.portrait_choices.values()
	check(portraits.size()==3,"hero official and messenger displayed")
	for portrait in portraits:check(portraits.count(portrait)==1,"distinct portraits during thanks")
	q._paid();check(game.money==250,"pay callback cannot duplicate money")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(game.progress.fame==0 and game.progress.favor_for("murim_alliance")==0,"last gratitude line still pending rewards")
	game.advance_dialogue()
	check(q.phase=="completed" and game.money==250 and game.progress.fame==5 and game.progress.favor_for("murim_alliance")==5,"exact requested reward totals")
	check(game.progress.stats==stats,"no automatic insight or stat reward")
	check(actor(q.MESSENGER)==null and q.marker_for(q.GIVER)=="","event messenger and giver marker removed")
	check(others==[game.herbalist_quest.snapshot(),game.artisan_quest.snapshot(),game.duel_quest.snapshot(),game.inn_quest.snapshot()],"all four concurrent quests untouched")
	q._complete();check(game.progress.fame==5 and game.progress.favor_for("murim_alliance")==5,"duplicate gratitude cannot grant again")
	await roundtrip(7)
	game.adventure_ui.open_favor();check(game.progress.known_factions==["murim_alliance"] and game.adventure_ui.rows.get_child(0).get_child(0).text.contains("5 / 100"),"earned favor visible after reload");game.adventure_ui.close_menu()
	await approach(q.WITNESS);drain();check(game.artisan_quest.phase=="ready","completed inquiry does not block artisan witness")
	var old=game.save_system.capture();old.erase("impostor_quest");old.progress.erase("faction_favor");old.progress.erase("known_factions")
	check(game.save_system.validate(old),"legacy save without quest or favor accepted")
	var file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(8) and q.phase=="available" and game.progress.favor_for("murim_alliance")==0,"legacy defaults zero favor and unaccepted quest")
	var invalid=old.duplicate(true);invalid.progress.faction_favor={"murim_alliance":5.5}
	check(not game.save_system.validate(invalid),"fractional favor rejected")
	invalid.progress.faction_favor=[];check(not game.save_system.validate(invalid),"wrong favor type rejected")
	invalid=old.duplicate(true);invalid.impostor_quest={"phase":"ready"};invalid.alliance_visit.phase="unverified"
	check(not game.save_system.validate(invalid),"quest progress without teaching rejected")
	var cases=0;var combat=Combat.new();var enemy: Dictionary=q.data.encounter
	for id in enemy.skills:check(combat.arts.can_learn(id,enemy.stats),"enemy skill requirements")
	for id in game.progress.arts.definitions:
		var art: Dictionary=game.progress.arts.get_skill(id)
		if art.get("acquisition") not in ["city_instructor","alliance_instructor"]:continue
		var minimum: Dictionary=game.progress.RULES.STARTING_STATS.duplicate()
		for key in art.requirements.stats:minimum[key]=maxi(minimum[key],art.requirements.stats[key])
		var total=0
		for value in minimum.values():total+=int(value)
		minimum.insight+=maxi(0,100-total)
		var weapon: String=game.progress.weapons.DEFAULT_BY_TYPE[art.required_weapon_type]
		for profile in [minimum,{"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}]:
			var result=simulation(profile,weapon,id,enemy)
			if profile.strength==20:check(result.win,"ordinary post-teaching build clears with "+id)
			cases+=1
	game.reset();check(game.progress.favor_for("murim_alliance")==0 and q.status()=="locked","new game resets favor and locks quest")
	await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_IMPOSTOR_QUEST: "+("FAIL" if failed else "PASS")+" · balance cases "+str(cases));quit(1 if failed else 0)
