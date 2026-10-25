extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ARTISAN_QUEST: "+message)
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
	check(is_instance_valid(npc),"existing NPC present: "+id)
	if not is_instance_valid(npc):return
	var path=world.path_to(npc.position,true)
	check(not path.is_empty(),"walkable approach: "+id)
	if path.is_empty():return
	world.player.position=path[-1];world.player.stop();await physics_frame;await physics_frame
	check(world.nearest().get("id","")==id,"F selects intended NPC: "+id)
	await press_f()
	if id==game.wages_quest.GIVER:
		if game.adventure_ui.window.visible:game.adventure_ui.secondary_action()
		else:
			drain()
			if game.adventure_ui.window.visible:game.adventure_ui.secondary_action()
func roundtrip(slot: int) -> void:
	var phase: String=game.artisan_quest.phase
	check(game.save_system.write_slot(slot),"save stable phase "+phase+": "+game.save_system.error)
	check(game.save_system.load_slot(slot),"load phase "+phase)
	await process_frame
	check(game.artisan_quest.phase==phase,"saved progress restored")
	check(game.exploration.ambient_nodes.size()==(12 if game.exploration.area_name=="wuchang" else 0),"no duplicate residents after reload")
func journal(filter: String,phase: String) -> void:
	var q=game.artisan_quest;var ui=game.adventure_ui
	ui.open_journal();ui.set_filter(filter)
	check(ui.entries.has(q.ID),"journal lists "+phase)
	ui.select_quest(q.ID)
	check(ui.body.text.contains("보수: 150문") and not ui.body.text.contains("오성"),"journal advertises money only")
	if phase=="completed":check(ui.body.text.contains("보수를 받았습니다."),"completed journal confirms settlement")
	ui.close_menu()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"])
	game.start_wuchang();await physics_frame
	var q=game.artisan_quest;var herb=game.herbalist_quest;var world=game.exploration
	var originals: Array=[]
	for npc in world.ambient_nodes:originals.append(npc.get_meta("npc_id"))
	check(q.phase=="available" and herb.phase=="available","new quest independent of herbalist")
	check(q.marker_for(q.GIVER)=="!" and is_instance_valid(q.marker) and q.marker.text=="!" and q.marker.visible,"actual yellow exclamation visible")
	journal("available","available")
	await approach(q.FARMER);drain()
	check(q.phase=="available","talking to farmer does not auto-accept")
	await approach(q.GIVER);game.adventure_ui.primary_action();drain()
	check(q.phase=="available" and game.adventure_ui.mode=="choice","intro requires explicit acceptance")
	check(not game.save_system.write_slot(9),"offer window cannot save")
	game.adventure_ui.secondary_action();drain()
	check(q.phase=="available","decline preserves availability")
	await roundtrip(1)
	game.money=1000
	await approach(q.GIVER);game.adventure_ui.secondary_action();drain()
	check(game.state=="service" and game.city_service.service.actor_id==q.GIVER,"weapon trade accessible before accepting")
	game.city_service.select_item("refined_sword");game.city_service.transact()
	check(game.money==700 and "refined_sword" in game.progress.owned_weapons,"ordinary weapon transaction retained")
	game.city_service.close_counter()
	var stats=game.progress.stats.duplicate();var fame: int=game.progress.fame;var regular=game.ordinary_quests.snapshot();var intro=game.chapter_one.snapshot()
	await approach(q.GIVER);game.adventure_ui.primary_action();drain();game.adventure_ui.primary_action();drain()
	check(q.phase=="farmer" and herb.phase=="available","independent explicit acceptance without first quest")
	check(game.quest_navigation.get_goal(world).position==actor(q.FARMER).position,"guide follows farmer live position")
	await approach(q.DOCK);drain()
	check(q.phase=="farmer" and game.money==700,"dock visited too early cannot advance or pay")
	q._dock_done();q._complete()
	check(q.phase=="farmer","out-of-order callbacks cannot bypass investigation")
	await roundtrip(2);journal("active","farmer")
	await approach(q.FARMER)
	check(game.dialogue_backdrop.visible,"investigation conversation dims city")
	var paths=game.dialogue_cast.portrait_choices.values()
	check(paths.size()==2 and paths[0]!=paths[1],"farmer and protagonist use distinct portraits")
	check(game.dialogue_lines.any(func(line):return "의심할 필요가 있소?" in line[1]),"approved wording applied")
	check(not game.dialogue_lines.any(func(line):return "의심할 줄 알았겠소?" in line[1]),"replaced wording removed")
	game.advance_dialogue()
	check(q.phase=="farmer" and not game.save_system.write_slot(9),"partial farmer conversation cannot commit or save")
	drain()
	check(q.phase=="dock" and game.quest_navigation.get_goal(world).position==actor(q.DOCK).position,"finished farmer conversation guides to dock")
	await roundtrip(3)
	# Leaving and returning keeps only this quest's stage and original resident placement.
	world.load_area("mountain_road");world.set_active(true)
	check(game.quest_navigation.get_goal(world).position==world.city_point([740,64]),"other-map guide points to Wuchang entrance")
	await roundtrip(4)
	world.load_area("wuchang");world.set_active(true)
	await approach(q.GIVER);game.adventure_ui.secondary_action();drain()
	check(game.state=="service" and q.phase=="dock","trade stays accessible during investigation")
	game.city_service.close_counter()
	await approach(q.FARMER);drain();check(q.phase=="dock","repeating completed step does not restart it")
	await approach(q.DOCK);game.advance_dialogue()
	check(q.phase=="dock" and game.money==700,"partial dock dialogue cannot mark report ready")
	drain()
	check(q.phase=="ready" and q.marker.text=="?" and q.marker.visible and game.money==700,"real question mark after investigation, no early money")
	check(game.quest_navigation.get_goal(world).position==actor(q.GIVER).position,"report guide points to artisan")
	await roundtrip(5);journal("active","ready")
	# Simultaneous quests can be tracked separately; completing one leaves the other intact.
	herb.accept();drain();var herb_before=herb.snapshot()
	game.adventure_ui.open_journal();game.adventure_ui.select_quest(q.ID);game.adventure_ui.primary_action()
	check(game.quest_navigation.quest_id==q.ID and herb.phase=="search","journal can switch back from herbalist tracking")
	await approach(q.GIVER);game.adventure_ui.primary_action()
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(q.phase=="ready" and game.money==700 and not game.save_system.write_slot(9),"last report line still unpaid and unsaveable")
	game.advance_dialogue()
	check(q.phase=="completed" and game.money==850,"only final report completion grants 150")
	check(game.progress.stats==stats and game.progress.fame==fame,"no ability or fame bonus")
	check(herb.snapshot()==herb_before and game.ordinary_quests.snapshot()==regular and game.chapter_one.snapshot()==intro,"other quest progress unchanged")
	check(not q.marker.visible and q.marker_for(q.GIVER)=="","completed marker removed")
	await roundtrip(6);journal("completed","completed")
	for id in [q.GIVER,q.FARMER,q.DOCK]:
		await approach(id)
		if id==q.GIVER:game.adventure_ui.primary_action()
		check(not game.dialogue_lines.is_empty(),"post-completion relationship dialogue exists")
		drain()
	q._complete();q._farmer_done();q._dock_done()
	check(game.money==850 and q.phase=="completed","revisit/reload/callbacks cannot repeat reward")
	check(world.ambient_nodes.map(func(n):return n.get_meta("npc_id"))==originals,"uses original NPCs without new actors")
	var old=game.save_system.capture();old.erase("artisan_quest")
	check(game.save_system.validate(old),"old save without artisan quest stays valid")
	var corrupt=old.duplicate(true);corrupt.artisan_quest={"phase":"unexpected"}
	check(not game.save_system.validate(corrupt),"invalid phase rejected")
	corrupt.artisan_quest={"phase":null};check(not game.save_system.validate(corrupt),"null phase rejected")
	var file=FileAccess.open(game.save_system.path(7),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(7) and q.phase=="available" and herb.phase=="search","legacy defaults only new quest and preserves herbalist")
	game.reset();check(q.phase=="available","new game clears artisan quest")
	await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_ARTISAN_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
