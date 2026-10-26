extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("LEVY_QUEST: "+msg)
func drain() -> void:
	for i in range(150):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func actor(id: String):
	for n in game.exploration.ambient_nodes:
		if n.get_meta("npc_id")==id:return n
	return null
func approach(id: String) -> void:
	var w=game.exploration;var a=actor(id);check(a!=null,"actor exists "+id)
	if a==null:return
	var path=w.path_to(a.position,true);check(not path.is_empty(),"reachable "+id)
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id")==id,"F target "+id)
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=down;Input.parse_input_event(e);await process_frame
func save_restore() -> void:
	var before: String=game.levy_quest.phase
	check(game.save_system.write_slot(8),"save "+before+game.save_system.error)
	check(game.save_system.load_slot(8),"load "+before+game.save_system.error)
	check(game.levy_quest.phase==before,"phase restored "+before)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("nanjing");game.exploration.set_active(true)
	var q=game.levy_quest;var w=game.exploration;var guard_start: Vector2=actor(q.GUARD).position
	check(q.status()=="available" and q.marker_for(q.GIVER)=="!","no prerequisites and giver marker")
	check(actor(q.SUSPECT)!=null,"suspect exists before acceptance")
	await approach(q.SUSPECT);drain();check(q.phase=="available","early talk cannot skip")
	await approach(q.GIVER);drain();game.adventure_ui.secondary_action();drain();check(q.phase=="available","decline")
	game.silk_quest.restore({"phase":"vendor"});game.quest_navigation.track(game.silk_quest.ID,game.silk_quest.stage())
	game.book_quest.accept();drain();game.cart_quest.accept();drain()
	await approach(q.GIVER);check(game.adventure_ui.mode=="choice","shared vendor chooser")
	game.adventure_ui.primary_action();drain();game.adventure_ui.primary_action();drain();check(q.phase=="clerk","levy accepted")
	await save_restore()
	await approach(q.GIVER);game.adventure_ui.secondary_action();drain();check(game.silk_quest.phase=="neighbor" and q.phase=="clerk","silk advances independently")
	var cash: int=game.money;var stats=game.progress.stats.duplicate();var fame: int=game.progress.fame;var favor=game.progress.faction_favor.duplicate()
	check(preload("res://scripts/catalog_icons.gd").texture("levy_receipt")!=null,"receipt icon")
	for phase in ["clerk","description","suspect","report_guard"]:
		check(q.phase==phase,"ordered phase "+phase);await save_restore()
		check(game.quest_navigation.quest_id==game.silk_quest.ID,"tracking not overwritten")
		check(game.cart_quest.phase=="worker" and game.book_quest.phase=="instructor","other quests retained")
		await approach(q.target());check(not game.save_system.write_slot(9),"dialogue save blocked")
		drain()
		if phase=="report_guard":
			check(q.phase=="arrest" and game.state=="story","arrest time cut")
			check(not game.save_system.write_slot(9),"cut save blocked")
			await create_timer(.9).timeout
			check(actor(q.GUARD).position.distance_to(guard_start)>500,"constable at arrest scene")
			var used={}
			for path in game.dialogue_cast.portrait_choices.values():used[path]=true
			check(used.size()==game.dialogue_cast.portrait_choices.size(),"distinct dialogue portraits")
			drain()
	check(q.phase=="ready" and q.marker_for(q.GIVER)=="?","report ready")
	check(actor(q.SUSPECT)==null and q.table_blocks.is_empty(),"suspect and colliding desk removed after arrest")
	check(actor(q.GUARD).position.distance_to(guard_start)<1,"constable returns")
	check(game.money==cash,"no money charged or paid early")
	await save_restore();await approach(q.GIVER);drain()
	check(q.phase=="completed" and game.money==cash+200,"exact reward once")
	q._complete();check(game.money==cash+200,"cannot duplicate reward")
	for key in stats:check(int(game.progress.stats[key])==int(stats[key]),"no stat reward")
	check(game.progress.fame==fame and game.progress.faction_favor==favor,"no fame/favor")
	await save_restore();check(actor(q.SUSPECT)==null,"arrest survives save")
	game.silk_quest.restore({"phase":"vendor"});await approach(q.GIVER);drain();check(game.silk_quest.phase=="neighbor","completed levy does not block active silk")
	w.load_area("wuchang");check(w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==q.SUSPECT).is_empty(),"no actor in other city")
	game.quest_navigation.track(q.ID,q.stage());check(not q.goal(w).is_empty(),"cross-region navigation")
	w.load_area("nanjing");check(actor(q.SUSPECT)==null,"no respawn after map revisit")
	var old=game.save_system.capture();old.erase("levy_quest");check(game.save_system.validate(old),"old saves supported")
	var bad=game.save_system.capture();bad.levy_quest.phase="invalid";check(not game.save_system.validate(bad),"invalid phase rejected")
	game.reset();check(q.phase=="available","reset")
	game.queue_free();await process_frame;print("LEVY_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
