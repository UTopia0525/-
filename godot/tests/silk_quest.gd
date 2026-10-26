extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("SILK_QUEST: "+msg)
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
	var q=game.silk_quest;var before=q.phase
	check(game.save_system.write_slot(8),"save "+before+game.save_system.error)
	check(game.save_system.load_slot(8),"load "+before+game.save_system.error)
	check(q.phase==before,"restored "+before)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("nanjing");game.exploration.set_active(true)
	var q=game.silk_quest;var relief=game.nanjing_relief_quest
	check(q.status()=="available" and q.marker_for(q.GIVER)=="!" and relief.status()=="locked","silk has no alliance prerequisite")
	await approach(q.CHEST);drain();check(q.phase=="available","chest locked before acceptance")
	await approach(q.GIVER);drain();check(game.adventure_ui.mode=="choice","explicit acceptance required");game.adventure_ui.secondary_action();drain();check(q.phase=="available","decline remains available")
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain()
	check(q.phase=="market","accepted")
	game.quest_navigation.track(game.herbalist_quest.ID,"offer")
	var cash: int=game.money;var stats=game.progress.stats.duplicate();var fame: int=game.progress.fame;var favor=game.progress.faction_favor.duplicate()
	for phase in ["market","vendor","neighbor","chest","ready"]:
		check(q.phase==phase,"ordered phase "+phase);await save_restore()
		check(game.quest_navigation.quest_id==game.herbalist_quest.ID,"other selected quest preserved")
		check(not game.quest_navigation.get_goal(game.exploration).is_empty(),"old quest routes out from Nanjing")
		if phase=="ready":break
		if phase in ["market","vendor","neighbor"]:
			await approach(q.CHEST);drain();check(q.phase==phase,"cannot loot chest without completed permission")
		await approach(q.target());check(not game.dialogue_lines.is_empty(),"F opens scene "+phase)
		check(q.phase==phase and not game.save_system.write_slot(9),"commit only at dialogue end; saves blocked")
		drain()
	check(game.money==cash and q.marker_for(q.GIVER)=="?","no expense/early pay; report question mark")
	game.adventure_ui.open_journal();game.adventure_ui.select_quest(q.ID);check(q.journal_items().size()==2,"sample and offcuts in journal");game.adventure_ui.close_menu()
	for id in ["silk_sample","silk_offcuts"]:check(preload("res://scripts/catalog_icons.gd").texture(id)!=null,"dedicated icon "+id)
	await approach(q.GIVER);drain();check(q.phase=="approval" and game.story_caption.visible,"short time cut after delivery")
	check(not game.save_system.write_slot(9) and game.money==cash,"no save or payout during time cut")
	await create_timer(1.0).timeout;check(not game.dialogue_lines.is_empty() and not game.story_caption.visible,"automatic client approval dialogue")
	drain();check(q.phase=="completed" and game.money==cash+150,"exact once reward")
	q._complete();q.accept();check(game.money==cash+150 and q.phase=="completed","cannot repeat reward/accept")
	for stat in stats:check(int(game.progress.stats[stat])==int(stats[stat]),"no stat reward "+stat)
	check(game.progress.fame==fame and game.progress.faction_favor==favor,"no fame/favor rewards")
	await save_restore();check(q.marker_for(q.GIVER)=="" and q.journal_items().is_empty(),"completed clears markers/items")
	for id in [q.GIVER,q.VENDOR,q.NEIGHBOR]:await approach(id);drain();check(q.phase=="completed","post-completion smalltalk")
	var old=game.save_system.capture();old.erase("silk_quest");check(game.save_system.validate(old),"old saves accepted")
	var bad=game.save_system.capture();bad.silk_quest.phase="invalid";check(not game.save_system.validate(bad),"invalid phase rejected")
	q.phase="ready";q._begin_approval();game.reset();await create_timer(1.0).timeout
	check(q.phase=="available" and game.dialogue_lines.is_empty() and not game.story_caption.visible,"new game cancels a pending approval transition")
	game.queue_free();await process_frame
	print("SILK_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
