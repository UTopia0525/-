extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("WAGES_QUEST: "+message)
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
	if id==game.wages_quest.BOARD:
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
	var phase: String=game.wages_quest.phase
	var residents=game.exploration.ambient_nodes.map(func(n):return n.get_meta("npc_id"));residents.sort()
	check(game.save_system.write_slot(slot),"save stable phase "+phase+": "+game.save_system.error)
	check(game.save_system.load_slot(slot),"load phase "+phase)
	await process_frame
	check(game.wages_quest.phase==phase,"saved progress restored")
	var restored=game.exploration.ambient_nodes.map(func(n):return n.get_meta("npc_id"));restored.sort()
	check(restored==residents,"no duplicate residents after reload")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var q=game.wages_quest;var w=game.exploration
	check(w.ambient_nodes.size()==12 and actor(q.CLERK)!=null,"new clerk permanently installed")
	check(game.dialogue_cast.texture_for(game.PORTRAITS.ACTORS[q.CLERK]).resource_path==game.dialogue_cast.basic_portraits.male_common_b.path,"uses existing general portrait")
	check(q.marker_for(q.GIVER)=="!","quest giver marked")
	await approach(q.CLERK);drain();check(q.phase=="available","clerk cannot autoaccept quest")
	await approach(q.GIVER);drain();game.adventure_ui.secondary_action();drain();check(q.phase=="available","can decline")
	await roundtrip(1)
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain()
	check(q.phase=="inspect","explicit acceptance")
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("active");check(game.adventure_ui.entries.has(q.ID),"Q active entry")
	game.adventure_ui.select_quest(q.ID);check(game.adventure_ui.body.text.contains("100문") and game.adventure_ui.body.text.contains("오성+5"),"journal shows correct reward");game.adventure_ui.close_menu()
	await approach(q.CLERK);drain();check(q.phase=="inspect","early clerk visit cannot skip board")
	var board=w.objectives.filter(func(e):return e.id==q.BOARD)[0].node
	check(not w.can_stand(board.position+Vector2(0,-7)),"board feet have navigation collision")
	for npc in [actor(q.CLERK),actor(q.GIVER)]:
		var bounds=Rect2(npc.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
		check(not bounds.intersects(q.board_visual),"board does not overlap residents")
		for scenery in w.scenery_bounds:check(not bounds.grow(6).intersects(scenery),"residents clear building silhouettes")
	w.player.position=board.position+Vector2(0,60);w.player.stop();Input.action_press("move_up")
	for i in range(18):await physics_frame
	Input.action_release("move_up");await physics_frame
	check(w.player.position.y>=board.position.y+8,"physical collision stops keyboard walking through board")
	await approach(q.BOARD)
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(q.phase=="inspect" and not game.save_system.write_slot(9),"board commits at last line and dialogue save blocked");game.advance_dialogue()
	check(q.phase=="ledger","inspection unlocks ledger")
	await roundtrip(2)
	await approach(q.CLERK);drain();check(q.phase=="decide" and game.adventure_ui.mode=="choice","ledger unlocks reasoning choice")
	var stats=game.progress.stats.duplicate();var money: int=game.money
	game.adventure_ui.secondary_action();drain()
	check(q.phase=="decide" and game.adventure_ui.mode=="choice" and game.progress.stats==stats and game.money==money,"wrong answer explains then retries without penalty")
	game.adventure_ui.close_menu();await roundtrip(3)
	await approach(q.CLERK);game.adventure_ui.primary_action()
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(q.phase=="decide","resolution commits at final line");game.advance_dialogue()
	check(q.phase=="ready" and q.marker_for(q.GIVER)=="?" and game.money==money,"report required before rewards")
	await roundtrip(4)
	# All local errands run concurrently, including two other topics on the same giver.
	game.herbalist_quest.accept();drain();game.artisan_quest.accept();drain();game.artisan_quest._farmer_done();game.duel_quest.accept();drain();game.inn_quest.accept();drain()
	game.alliance_visit.phase="closed";game.progress.learned.append("hoeryu");game.impostor_quest.accept();drain()
	var others=[game.herbalist_quest.snapshot(),game.artisan_quest.snapshot(),game.duel_quest.snapshot(),game.inn_quest.snapshot(),game.impostor_quest.snapshot()]
	await approach(q.GIVER);check(game.adventure_ui.window.visible,"shared giver offers topic menu");game.adventure_ui.primary_action()
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(game.money==money and game.progress.stats==stats,"no premature report reward");game.advance_dialogue()
	check(q.phase=="completed" and game.money==money+100 and game.progress.stats.insight==stats.insight+5,"requested 100 money and 5 insight")
	var after=game.progress.stats.duplicate();after.insight=stats.insight
	check(after==stats and game.progress.fame==0 and game.progress.favor_for("murim_alliance")==0,"other stats fame favor unchanged")
	check(others==[game.herbalist_quest.snapshot(),game.artisan_quest.snapshot(),game.duel_quest.snapshot(),game.inn_quest.snapshot(),game.impostor_quest.snapshot()],"other five quests untouched")
	check(actor(q.CLERK)!=null and q.marker_for(q.GIVER)=="","permanent clerk remains after completion, marker removed")
	q._complete();check(game.money==money+100 and game.progress.stats.insight==stats.insight+5,"duplicate reward blocked")
	await roundtrip(5)
	await approach(q.GIVER);game.adventure_ui.secondary_action();check(game.adventure_ui.window.visible,"two pending other topics available")
	game.adventure_ui.primary_action();drain();check(game.impostor_quest.phase=="verify" and game.artisan_quest.phase=="dock","completed wages smalltalk cannot block impostor witness")
	await approach(q.GIVER);game.adventure_ui.secondary_action();drain();check(game.artisan_quest.phase=="ready","artisan witness still available")
	await approach(q.GIVER);drain();check(game.money==money+100,"post conversation cannot duplicate reward")
	check(game.save_system.load_slot(4),"rewind before report for cap")
	game.progress.stats.insight=98;await approach(q.GIVER);drain()
	check(game.progress.stats.insight==100 and game.money==money+100,"insight respects100 cap")
	await roundtrip(6)
	check(w.objectives.filter(func(e):return e.id==q.BOARD).size()==1 and w.blockers.count(q.board_foot)==1 and w.regional_map.blockers.count(q.board_foot)==1,"reload creates one board and one footprint")
	var old=game.save_system.capture();old.erase("wages_quest");check(game.save_system.validate(old),"legacy save accepted")
	var file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(8) and q.phase=="available" and actor(q.CLERK)!=null,"legacy defaults quest unaccepted, clerk present")
	var bad=old.duplicate(true);bad.wages_quest={"phase":"unknown"};check(not game.save_system.validate(bad),"unknown quest stage rejected")
	game.reset();check(q.phase=="available","new game resets quest")
	await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_WAGES_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
