extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("DUEL_QUEST: "+message)
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
	var state=game.duel_quest.snapshot()
	check(game.save_system.write_slot(slot),"stable phase save: "+game.save_system.error)
	check(game.save_system.load_slot(slot) and game.duel_quest.snapshot()==state,"quest phase/outcome restored")
	await process_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var q=game.duel_quest;var w=game.exploration
	check(actor(q.STUDENT)==null and q.marker_for(q.GIVER)=="!","student hidden before acceptance, giver marked")
	await approach(q.GIVER);game.adventure_ui.secondary_action();drain()
	check(game.state=="service" and game.city_service.service.actor_id==q.GIVER,"teacher shop retained")
	for button in game.city_service.rows.get_children():
		if button is Button:check(not "조식수원공" in button.text,"reward art not sold")
	game.city_service.close_counter()
	await approach(q.GIVER);game.adventure_ui.primary_action();drain();game.adventure_ui.secondary_action();drain()
	check(q.phase=="available" and actor(q.STUDENT)==null,"decline does not spawn student")
	await roundtrip(1)
	game.herbalist_quest.accept();drain();game.artisan_quest.accept();drain()
	var other_herb=game.herbalist_quest.snapshot();var other_artisan=game.artisan_quest.snapshot()
	await approach(q.GIVER);game.adventure_ui.primary_action();drain();game.adventure_ui.primary_action();drain()
	check(q.phase=="accepted" and w.ambient_nodes.size()==12,"explicit acceptance adds one existing-pool student")
	var npc=actor(q.STUDENT);var visual=Rect2(npc.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
	for bounds in w.scenery_bounds:check(not visual.grow(6).intersects(bounds),"student clears full scenery silhouette")
	check(game.quest_navigation.get_goal(w).position==npc.position,"guide follows actual safe student location")
	await roundtrip(2)
	await approach(q.STUDENT);drain();game.adventure_ui.secondary_action();drain()
	check(q.phase=="accepted" and game.state=="explore","can postpone duel for equipment preparation")
	await roundtrip(3)
	await approach(q.STUDENT)
	var paths=game.dialogue_cast.portrait_choices.values()
	check(paths.size()==2 and paths[0]!=paths[1],"student and player portraits distinct")
	drain();game.adventure_ui.primary_action()
	check(q.in_battle() and game.battle.enemy_hp==180 and game.battle.enemy_qi.amount==8,"nonlethal training encounter configured")
	check(not game.save_system.write_slot(9),"battle save remains blocked")
	for i in range(20):
		if game.state!="battle":break
		game.battle.select_samjae();game.battle.use_selected();await wait_turn()
	drain()
	check(q.phase=="ready" and q.result=="win" and game.money==0 and "josik_suwon" not in game.progress.learned,"win enables report without premature grant")
	check(q.marker_for(q.GIVER)=="?","report question mark")
	await roundtrip(4)
	var before=game.progress.stats.duplicate();var fame: int=game.progress.fame
	await approach(q.GIVER);game.adventure_ui.primary_action()
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check("josik_suwon" not in game.progress.learned and not game.save_system.write_slot(9),"last teaching line still ungranted and unsaveable")
	game.advance_dialogue()
	check(q.phase=="completed" and game.progress.learned.count("josik_suwon")==1,"report grants one learned art")
	check(game.money==0 and game.progress.stats==before and game.progress.fame==fame,"no money/stat/fame bonus")
	check(actor(q.STUDENT)==null and w.ambient_nodes.size()==11,"temporary student removed after completion")
	check(game.herbalist_quest.snapshot()==other_herb and game.artisan_quest.snapshot()==other_artisan,"other simultaneous quests unchanged")
	await roundtrip(5)
	game.player_menu.open_menu("martial");game.player_menu.select_item("josik_suwon")
	check(game.player_menu.detail.text.contains("200%") and game.player_menu.detail.text.contains("20%"),"K explains recovery and defense")
	var found:=false
	for button in game.player_menu.rows.get_children():
		if button is Button and "조식수원공" in button.text:found=button.icon!=null
	check(found,"K row shows generated icon")
	check(game.progress.assign("josik_suwon",3),"reward art can be assigned")
	game.player_menu.close_menu()
	q._complete();check(game.progress.learned.count("josik_suwon")==1,"duplicate completion cannot duplicate reward")
	# Rewind the explicit pre-duel save to exercise the losing branch independently.
	check(game.save_system.load_slot(3),"rewind before duel")
	await approach(q.STUDENT);drain();game.adventure_ui.primary_action()
	game.battle.player_hp=1;game.battle.select_basic_attack();game.battle.use_selected();await wait_turn();drain()
	check(q.phase=="ready" and q.result=="loss" and game.state=="explore","defeat stops sparring and enables report")
	await roundtrip(6)
	await approach(q.GIVER);game.adventure_ui.primary_action();drain()
	check(q.phase=="completed" and game.progress.learned.count("josik_suwon")==1 and game.money==0,"loss receives same art without replay or penalty")
	var old=game.save_system.capture();old.erase("duel_quest")
	check(game.save_system.validate(old),"older save without new quest accepted")
	var invalid=old.duplicate(true);invalid.duel_quest={"phase":"ready","result":""}
	check(not game.save_system.validate(invalid),"report phase needs an outcome")
	invalid.duel_quest={"phase":"completed","result":"win"};invalid.progress.learned.erase("josik_suwon")
	check(not game.save_system.validate(invalid),"completed save must contain taught art")
	game.reset();check(q.phase=="available" and "josik_suwon" not in game.progress.learned,"new game resets reward")
	await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_DUEL_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
