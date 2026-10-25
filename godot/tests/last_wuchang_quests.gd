extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("LAST_QUESTS: "+message)
func drain() -> void:
	for i in range(80):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func press_f() -> void:
	var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=true
	Input.parse_input_event(e);await process_frame
	e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await process_frame
func actor(id: String):
	for npc in game.exploration.ambient_nodes:
		if npc.get_meta("npc_id")==id:return npc
	return null
func approach(id: String) -> void:
	var world=game.exploration;var npc=actor(id)
	if id.begins_with(game.plaque_quest.PREFIX):
		for entry in world.objectives:
			if entry.id==id:npc=entry.node
	check(is_instance_valid(npc),"existing NPC present: "+id)
	if not is_instance_valid(npc):return
	var path=world.path_to(npc.position,true)
	check(not path.is_empty(),"walkable approach: "+id)
	if path.is_empty():return
	world.player.position=path[-1];world.player.stop();await physics_frame;await physics_frame
	check(world.nearest().get("id","")==id,"F selects intended NPC: "+id)
	await press_f()
func roundtrip(slot: int) -> void:
	var p=game.plaque_quest.snapshot();var g=game.grain_quest.snapshot()
	check(game.save_system.write_slot(slot),"save stable quests: "+game.save_system.error)
	check(game.save_system.load_slot(slot),"load stable quests");await process_frame
	check(game.plaque_quest.snapshot()==p and game.grain_quest.snapshot()==g,"both quest states restored")
	check(game.exploration.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==game.plaque_quest.MANAGER).size()==1,"one permanent caretaker")
func choose_grain_farmer() -> void:
	if game.adventure_ui.window.visible:game.adventure_ui.primary_action()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var p=game.plaque_quest;var g=game.grain_quest;var w=game.exploration
	check(w.ambient_nodes.size()==13,"ten civilians and three alliance members")
	var original=game.progress.snapshot()
	await approach(p.MANAGER);drain();check(p.phase=="available","manager cannot autoaccept")
	await approach(p.GIVER);drain();game.adventure_ui.secondary_action();drain();check(p.phase=="available","plaque decline")
	await approach(g.GIVER);drain();game.adventure_ui.secondary_action();drain();check(g.phase=="available","grain decline")
	await approach(p.GIVER);drain();game.adventure_ui.primary_action();drain()
	check(p.phase=="manager" and w.objectives.filter(func(e):return str(e.id).begins_with(p.PREFIX)).is_empty(),"no searchable timber before permission")
	await approach(g.GIVER);drain();game.adventure_ui.primary_action();drain()
	check(g.phase=="receipt" and actor(g.COLLECTOR)!=null,"grain accepted concurrently and collector appears")
	await approach(g.COLLECTOR);drain();g._cleared();check(g.phase=="receipt","cannot confront before official proof")
	await roundtrip(1)
	await approach(p.MANAGER)
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(p.phase=="manager","permission commits after final line");game.advance_dialogue()
	check(p.phase=="search" and w.objectives.filter(func(e):return str(e.id).begins_with(p.PREFIX)).size()==3,"permission reveals three props")
	for entry in w.objectives:
		if str(entry.id).begins_with(p.PREFIX):check(not w.can_stand(entry.position+Vector2(0,-7)),"timber has collision")
	await approach(p.PREFIX+"beam");drain();check(p.checked==["beam"] and p.phase=="search","wrong prop can be checked without completion")
	await roundtrip(2)
	await approach(p.PREFIX+"planks");drain();await approach(p.PREFIX+"door")
	check(game.dialogue_cast.portrait_choices.size()==2,"recovery dialogue has hero and manager")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(p.phase=="search" and "door" not in p.checked,"plaque recovery waits for final line");game.advance_dialogue()
	check(p.phase=="ready" and p.marker_for(p.GIVER)=="?" and game.money==0,"plaque report required")
	await roundtrip(3)
	await approach(p.GIVER)
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(game.money==0,"no early plaque reward");game.advance_dialogue()
	check(p.phase=="completed" and game.money==100 and JSON.parse_string(JSON.stringify(game.progress.snapshot()))==JSON.parse_string(JSON.stringify(original)),"plaque pays100 only")
	check(p.nodes.any(func(n):return is_instance_valid(n) and n.get_parent().get_meta("scenery_id","")=="home_2"),"nameplate attached to present house")
	p._complete();check(game.money==100,"no duplicate plaque reward")
	await roundtrip(4)
	# All other ordinary quests can remain active while the tax issue is investigated.
	game.herbalist_quest.accept();drain();game.artisan_quest.accept();drain();game.wages_quest.accept();drain();game.duel_quest.accept();drain();game.inn_quest.accept();drain()
	game.alliance_visit.phase="closed";game.progress.learned.append("hoeryu");game.impostor_quest.accept();drain()
	var other=[game.herbalist_quest.snapshot(),game.artisan_quest.snapshot(),game.wages_quest.snapshot(),game.duel_quest.snapshot(),game.inn_quest.snapshot(),game.impostor_quest.snapshot()]
	await approach(g.GIVER);choose_grain_farmer()
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(g.phase=="receipt","receipt commits after final line");game.advance_dialogue()
	check(g.phase=="shipping","receipt leads to shipping clerk")
	await approach(g.OFFICER);drain();check(g.phase=="shipping","cannot skip shipping record")
	# Clerk offers both active cases without replacing either state.
	game.wages_quest.phase="ledger";game.wages_quest.signature="";game.wages_quest.refresh_world()
	await approach(g.CLERK);check(game.adventure_ui.window.visible,"shared clerk topics")
	game.adventure_ui.secondary_action();drain();check(game.wages_quest.phase=="decide" and g.phase=="shipping","wages dialogue remains available")
	game.adventure_ui.close_menu();await approach(g.CLERK);game.adventure_ui.primary_action();drain()
	check(g.phase=="official" and game.wages_quest.phase=="decide","shipping proof does not finish tax or overwrite wages")
	await roundtrip(5)
	var home=actor(g.OFFICER).position
	await approach(g.OFFICER);check(game.adventure_ui.window.visible,"shared officer topics")
	game.adventure_ui.secondary_action();drain()
	check(game.impostor_quest.phase=="witness" and g.phase=="official","impostor conversation remains accessible independently")
	await approach(g.OFFICER);game.adventure_ui.primary_action()
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(g.phase=="official" and actor(g.OFFICER).position==home,"official stays before confirmation");game.advance_dialogue()
	check(g.phase=="confront" and actor(g.OFFICER).position==home,"official normal post retained until hearing")
	await roundtrip(6)
	await approach(g.COLLECTOR)
	check(g.hearing_active and actor(g.OFFICER).position!=home,"official physically attends field hearing")
	var portraits=game.dialogue_cast.portrait_choices.values();check(portraits.size()==3,"three distinct speakers in hearing")
	for portrait in portraits:check(portraits.count(portrait)==1,"no duplicate portrait in hearing")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(g.phase=="confront" and game.money==100,"hearing final line still unpaid");game.advance_dialogue()
	check(g.phase=="ready" and actor(g.COLLECTOR)==null and actor(g.OFFICER).position==home,"collector leaves and original officer returns once")
	check(w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==g.OFFICER).size()==1,"no duplicated officer")
	await roundtrip(7)
	var progress=game.progress.snapshot()
	await approach(g.GIVER);choose_grain_farmer()
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(game.money==100 and not game.save_system.write_slot(9),"report waits final line and dialogue save blocked");game.advance_dialogue()
	check(g.phase=="completed" and game.money==300 and game.progress.snapshot()==progress,"grain pays200 and no stat/favor/fame change")
	g._complete();check(game.money==300,"no duplicate tax reward")
	check(game.herbalist_quest.snapshot()==other[0] and game.artisan_quest.snapshot()==other[1] and game.duel_quest.snapshot()==other[3] and game.inn_quest.snapshot()==other[4],"other quests unchanged by both new completions")
	await roundtrip(8)
	var old=game.save_system.capture();old.erase("plaque_quest");old.erase("grain_quest")
	check(game.save_system.validate(old),"legacy save without both quests accepted")
	var file=FileAccess.open(game.save_system.path(9),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(9) and p.phase=="available" and g.phase=="available","legacy defaults unaccepted")
	check(not p.valid({"phase":"ready","checked":[]}),"cannot report without recovered plaque")
	check(not g.valid({"phase":"bad"}),"unknown tax phase rejected")
	game.reset();game.start_wuchang();game.alliance_visit.phase="closed";game.progress.learned.append("hoeryu")
	var errands=[game.herbalist_quest,game.artisan_quest,game.wages_quest,game.duel_quest,game.inn_quest,game.impostor_quest,p,g]
	for quest in errands:quest.accept();drain()
	check(errands.all(func(q):return q.status()=="active"),"all eight ordinary quests can be active together")
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_LAST_QUESTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
