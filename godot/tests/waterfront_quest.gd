extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("WATERFRONT_QUEST: "+msg)
func drain() -> void:
	for i in range(160):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func actor(id: String):
	for n in game.exploration.ambient_nodes:
		if n.get_meta("npc_id")==id:return n
	return null
func approach(id: String) -> void:
	var w=game.exploration;var point=Vector2.ZERO
	for n in w.ambient_nodes:
		if n.get_meta("npc_id")==id:point=n.position
	for o in w.objectives:
		if o.id==id:point=o.position
	check(point!=Vector2.ZERO,"target exists "+id)
	var path=w.path_to(point,true);check(not path.is_empty(),"reachable "+id)
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id")==id,"F chooses "+id)
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=down;Input.parse_input_event(e);await process_frame
func save_restore() -> void:
	var before: String=game.waterfront_quest.phase
	check(game.save_system.write_slot(8),"save "+before+game.save_system.error)
	check(game.save_system.load_slot(8),"load "+before+game.save_system.error)
	check(game.waterfront_quest.phase==before,"restored "+before)
func meet() -> void:
	var w=game.exploration;var a=actor(game.waterfront_quest.SUSPECT);check(a!=null,"Nochil exists")
	if a==null:return
	var path=w.path_to(a.position,true);check(not path.is_empty(),"Nochil approachable")
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame;await process_frame;await create_timer(.1).timeout
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("nanjing");game.exploration.set_active(true)
	var q=game.waterfront_quest;var w=game.exploration
	check(q.marker_for(q.GIVER)=="!" and actor(q.SUSPECT)==null,"available without early suspect")
	await approach(q.GRAIN);drain();check(q.phase=="available","early clue cannot skip acceptance")
	await approach(q.GIVER);drain();game.adventure_ui.secondary_action();drain();check(q.phase=="available","decline")
	game.book_quest.accept();drain();game.cart_quest.accept();drain();game.quest_navigation.track(game.cart_quest.ID,game.cart_quest.stage())
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain()
	var cash: int=game.money;var stats=game.progress.stats.duplicate();var fame: int=game.progress.fame;var favor=game.progress.faction_favor.duplicate()
	for phase in ["rope","grain","witness"]:
		check(q.phase==phase,"ordered "+phase);await save_restore()
		check(actor(q.SUSPECT)==null,"Nochil hidden before testimony")
		check(not q.goal(w).is_empty(),"quest points to current clue or witness")
		check(game.book_quest.phase=="instructor" and game.cart_quest.phase=="worker","concurrent progress retained")
		check(game.quest_navigation.quest_id==game.cart_quest.ID,"selected tracking retained")
		await approach(q.target());check(not game.save_system.write_slot(9),"dialogue cannot save");drain()
	check(q.phase=="confront" and actor(q.SUSPECT)!=null,"testimony reveals Nochil")
	await save_restore();var original=FileAccess.get_file_as_string(game.save_system.path(8))
	game.player_menu.open_menu("inventory");await meet();check(q.phase=="confront","modal blocks auto encounter");game.player_menu.close_menu();await process_frame;await process_frame
	check(q.phase=="demand" and not game.dialogue_lines.is_empty() and not game.adventure_ui.window.visible,"approach starts confrontation with no retreat chooser")
	drain();check(q.phase=="battle" and game.state=="battle" and game.battle.encounter.id=="nanjing_nochil","dialogue directly starts battle")
	check(not game.save_system.write_slot(9),"battle cannot save")
	# Actual enemy action, shared death handler and preserved manual save.
	game.battle.player_hp=1;game.battle.select_skill("basic_defense");game.battle.use_selected()
	var deadline=Time.get_ticks_msec()+12000
	while game.state=="battle" and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(game.state=="game_over" and game.money==cash and q.phase=="battle","loss kills without outcome/reward")
	check(not game.save_system.write_slot(9) and FileAccess.get_file_as_string(game.save_system.path(8))==original,"death preserves save")
	await create_timer(1.5).timeout;game.death_screen.return_to_title();check(game.state=="title","death returns title")
	check(game.save_system.load_slot(8),"reload pre-encounter save")
	# A normal peak build using the intermediate saber wins an actual fight.
	game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
	game.progress.owned_weapons.append("thickback_saber");game.progress.learned.append("paak");game.progress.assign("paak",3);game.battle.equip_weapon_item("thickback_saber")
	await meet();drain();check(game.state=="battle","reloaded approach starts once")
	for turn in range(12):
		if game.state!="battle":break
		game.battle.select_skill("paak" if game.battle.qi.amount>=22 else "basic_attack");game.battle.use_selected()
		var end=Time.get_ticks_msec()+12000
		while game.battle.busy and game.state=="battle" and Time.get_ticks_msec()<end:await create_timer(.03).timeout
		check(Time.get_ticks_msec()<end,"exchange completes")
	check(q.phase=="aftermath" and game.state=="explore","victory routes to subdued Nochil dialogue")
	check(game.dialogue_lines.any(func(line):return "허리를 다친" in str(line)),"poverty emerges only after victory")
	check(game.money==cash,"no battle payout")
	drain();check(q.phase=="handover" and game.state=="story","handover transition")
	await create_timer(1.0).timeout;drain()
	check(q.phase=="ready" and actor(q.SUSPECT)==null and q.marker_for(q.GIVER)=="?","handover removes Nochil and unlocks report")
	await save_restore();await approach(q.GIVER);drain()
	check(q.phase=="completed" and game.money==cash+250,"exact one-time 250 reward")
	q._complete();check(game.money==cash+250,"no repeated reward")
	check(game.progress.fame==fame and game.progress.faction_favor==favor,"no fame/favor")
	check(game.progress.stats.insight==20,"no quest insight reward")
	await save_restore();w.load_area("wuchang");w.load_area("nanjing");check(actor(q.SUSPECT)==null,"no respawn after revisit")
	for id in [q.GIVER,q.WITNESS,q.ROPE]:await approach(id);drain()
	for id in ["waterfront_rope","waterfront_grain"]:check(preload("res://scripts/catalog_icons.gd").texture(id)!=null,"new icon "+id)
	var old=game.save_system.capture();old.erase("waterfront_quest");check(game.save_system.validate(old),"old saves accepted")
	var bad=game.save_system.capture();bad.waterfront_quest.phase="invalid";check(not game.save_system.validate(bad),"invalid phase rejected")
	game.reset();check(q.phase=="available","new game clears quest")
	game.queue_free();await process_frame;print("WATERFRONT_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
