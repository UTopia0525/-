extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("CART_QUEST: "+msg)
func drain() -> void:
	for i in range(120):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func press_f() -> void:
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=down;Input.parse_input_event(e);await process_frame
func approach(id: String) -> void:
	var w=game.exploration;var point=Vector2.ZERO
	for a in w.ambient_nodes:
		if a.get_meta("npc_id")==id:point=a.position
	for o in w.objectives:
		if o.id==id:point=o.position
	check(point!=Vector2.ZERO,"target exists "+id)
	var path=w.path_to(point,true);check(not path.is_empty(),"walkable F approach "+id)
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id")==id,"F selects "+id);await press_f()
func save_restore() -> void:
	var q=game.cart_quest;var before=q.phase
	check(game.save_system.write_slot(8),"save "+before+game.save_system.error)
	check(game.save_system.load_slot(8),"load "+before+game.save_system.error)
	check(q.phase==before,"restored "+before)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("nanjing");game.exploration.set_active(true)
	var q=game.cart_quest;var silk=game.silk_quest
	check(q.status()=="available" and q.marker_for(q.GIVER)=="!","available without prerequisite")
	await approach(q.CART);drain();check(q.phase=="available","early cart investigation cannot skip acceptance")
	await approach(q.GIVER);drain();game.adventure_ui.secondary_action();drain();check(q.phase=="available","decline preserves availability")
	silk.accept();drain();check(silk.phase=="market","another ordinary quest accepted concurrently")
	game.quest_navigation.track(silk.ID,silk.stage())
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain();check(q.phase=="worker","cart accepted independently")
	game.money=1000;var cash: int=game.money;var stats=game.progress.stats.duplicate();var fame: int=game.progress.fame;var favor=game.progress.faction_favor.duplicate()
	for phase in ["worker","cart","artisan","clerk"]:
		check(q.phase==phase,"ordered "+phase);await save_restore()
		check(game.silk_quest.phase=="market" and game.quest_navigation.quest_id==silk.ID,"concurrent quest and selected tracking preserved")
		if phase=="clerk":break
		if phase=="worker":await approach(q.CART);drain();check(q.phase=="worker","worker testimony required before collecting axle")
		await approach(q.target())
		if phase=="artisan":
			check(game.adventure_ui.mode=="choice","artisan trade/diagnosis chooser")
			game.adventure_ui.secondary_action();drain();check(game.state=="service" and q.phase=="artisan","weapon counter accessible during quest")
			game.city_service.close_counter();await approach(q.ARTISAN);game.adventure_ui.primary_action()
		check(not game.dialogue_lines.is_empty() and q.phase==phase,"scene commits after final line")
		check(not game.save_system.write_slot(9),"dialogue save blocked")
		drain()
	# Both quests require this clerk: explicitly expose either subject.
	game.progress.learned.append("gwanak");game.alliance_story.stage_id="completed";game.alliance_story.received_art="gwanak";game.alliance_visit.phase="training_complete"
	game.nanjing_relief_quest.restore({"phase":"ledger"})
	await approach(q.CLERK);check(game.adventure_ui.mode=="choice","shared clerk exposes both investigations")
	game.adventure_ui.secondary_action();drain();check(game.nanjing_relief_quest.phase=="contact" and q.phase=="clerk","relief subject advances only relief")
	await approach(q.CLERK);drain();check(q.phase=="owner","cart subject still accessible")
	await save_restore();await approach(q.OWNER);drain();check(q.phase=="ready" and q.marker_for(q.GIVER)=="?","settlement unlocks report")
	check(game.money==cash and q.journal_items().size()==1,"no repair expense or early payout")
	game.adventure_ui.open_journal();game.adventure_ui.select_quest(q.ID);check(preload("res://scripts/catalog_icons.gd").texture("cart_axle")!=null,"dedicated axle icon in journal");game.adventure_ui.close_menu()
	await approach(q.GIVER)
	var used={}
	for path in game.dialogue_cast.portrait_choices.values():used[path]=true
	check(used.size()==game.dialogue_cast.portrait_choices.size(),"two workers use distinct portraits in joint report")
	drain();check(q.phase=="completed" and game.money==cash+200,"exact one-time money reward")
	q._complete();q.accept();check(game.money==cash+200,"reward cannot repeat")
	for key in stats:check(int(game.progress.stats[key])==int(stats[key]),"no stat reward")
	check(game.progress.fame==fame and game.progress.faction_favor==favor,"no fame/favor reward")
	await save_restore()
	var prop=game.exploration.scenery_nodes.filter(func(n):return n.name=="capital_12")[0]
	check(prop.sprite.texture.region.position==Vector2(955,180),"unloaded repair-waiting cart survives load")
	check(q.journal_items().is_empty() and q.marker_for(q.GIVER)=="","completed items and marker cleared")
	for id in [q.GIVER,q.WORKER,q.OWNER]:await approach(id);drain()
	await approach(q.ARTISAN);game.adventure_ui.primary_action();drain()
	game.nanjing_relief_quest.restore({"phase":"ledger"})
	await approach(q.CLERK);drain();check(game.nanjing_relief_quest.phase=="contact","completed cart smalltalk cannot block active relief")
	var old=game.save_system.capture();old.erase("cart_quest");check(game.save_system.validate(old),"old saves accepted")
	var bad=game.save_system.capture();bad.cart_quest.phase="invalid";check(not game.save_system.validate(bad),"invalid phase rejected")
	game.reset();check(q.phase=="available","new game reset")
	game.queue_free();await process_frame
	print("CART_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
