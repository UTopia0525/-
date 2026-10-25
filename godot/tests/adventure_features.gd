extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,text: String) -> void:
	if not ok:failed=true;push_error("ADVENTURE_FEATURES: "+text)
func drain() -> void:
	var count:=0
	while not game.dialogue_lines.is_empty() and count<200:game.advance_dialogue();count+=1
	check(count<200,"dialogue terminates")
func key(code: int) -> void:
	var event=InputEventKey.new();event.keycode=code;event.pressed=true;root.push_input(event,true)
func approach(id: String) -> void:
	for actor in game.exploration.ambient_nodes:
		if actor.name==id:game.exploration.player.position=actor.position+Vector2(35,0);return
func interact_goal_at_world(id: String,goal: Dictionary) -> void:
	game.ordinary_quests.refresh_world()
	var wanted: String=goal.get("npc_id","quest_goal:"+id+":"+str(goal.id))
	var point:=Vector2.ZERO
	for actor in game.exploration.ambient_nodes:
		if actor.name==wanted:point=actor.position
	for objective in game.exploration.objectives:
		if objective.id==wanted:point=objective.position
	var reached:=false
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(.707,.707),Vector2(-.707,.707),Vector2(.707,-.707),Vector2(-.707,-.707)]:
		var candidate: Vector2=point+direction*34
		if not game.exploration.can_stand(candidate):continue
		game.exploration.player.position=candidate
		if game.exploration.nearest().get("id","")==wanted:reached=true;break
	check(reached,"actual F target reachable: "+wanted)
	if reached:game.interact()
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city();await physics_frame;await physics_frame
	var quests=game.ordinary_quests;var ui=game.adventure_ui
	for id in quests.definitions:
		check(quests.marker_for(quests.definitions[id].giver)=="!" and quests.marks[quests.definitions[id].giver].visible and quests.marks[quests.definitions[id].giver].text=="!","available yellow marker: "+id)
	approach("vegetable_vendor")
	check(game.exploration.nearest().id=="vegetable_vendor","ordinary NPCs really interact with F")
	game.interact();drain()
	check(ui.window.visible and ui.mode=="choice" and quests.status("changsha_baskets")=="available","conversation requests acceptance, never forced")
	ui.secondary_action();drain();check(quests.status("changsha_baskets")=="available","decline preserves offer")
	game.interact();drain();ui.primary_action();drain()
	check(quests.status("changsha_baskets")=="active" and quests.marker_for("vegetable_vendor")=="","accepted independent errand")
	key(KEY_Q);await process_frame
	check(ui.window.visible and ui.mode=="journal" and paused,"Q journal pauses world")
	for i in range(20):
		key(KEY_TAB);check(ui.window.is_ancestor_of(root.gui_get_focus_owner()),"menu keyboard focus cannot escape to gameplay")
	for tab in ui.filter_buttons:check(not tab.get_global_rect().intersects(ui.body.get_global_rect()),"journal tabs do not overlap detail")
	ui.select_quest("changsha_baskets");ui.primary_action()
	check(not paused and game.quest_navigation.quest_id=="changsha_baskets","journal tracks accepted quest")
	check(quests.handle_interaction("general_merchant"),"exchange target interaction")
	var before: int=game.money;drain()
	check(quests.status("changsha_baskets")=="ready" and quests.marker_for("vegetable_vendor")=="?" and quests.marks.vegetable_vendor.text=="?" and game.money==before,"ready question mark without early reward")
	check(game.save_system.write_slot(1),"save ready state")
	quests.handle_interaction("vegetable_vendor")
	check(game.money==before,"reward waits for final dialogue")
	drain();check(game.money==before+100 and quests.status("changsha_baskets")=="completed" and quests.marker_for("vegetable_vendor")=="","report rewards once and removes mark")
	quests.handle_interaction("vegetable_vendor");drain();check(game.money==before+100,"repeat conversation cannot pay twice")
	check(game.save_system.load_slot(1) and quests.status("changsha_baskets")=="ready" and quests.marker_for("vegetable_vendor")=="?","ready state restored")
	# All six independent paths, point investigations, and both family reports use approved rewards.
	for id in quests.definitions:
		if quests.status(id)=="available":quests.accept(id);drain()
		var guard:=0
		while quests.status(id)=="active" and guard<12:
			var stage: String=quests.stage_for(id)
			var goals: Array=game.quest_navigation.definitions[id].stages[stage].goals
			for goal in goals:
				if goal.id in quests.records[id].done:continue
				interact_goal_at_world(id,goal);drain()
			guard+=1
		check(quests.status(id)=="ready","all goals fulfilled: "+id)
		if id=="changsha_family":
			check(game.save_system.write_slot(2),"family ready checkpoint")
			quests.handle_interaction(quests.definitions[id].giver);ui.primary_action();drain()
			var paid: int=game.money
			check(game.save_system.load_slot(2),"rewind family choice")
			quests.handle_interaction(quests.definitions[id].giver);ui.secondary_action();drain()
			check(game.money==paid,"family branches have identical reward")
		else:quests.handle_interaction(quests.definitions[id].giver);drain()
	check(game.money==700 and game.progress.stats.insight==22,"six normal quests pay approved total 700 and insight12")
	game.toggle_city_map()
	await process_frame
	for marker in game.city_overview.actor_markers:
		if not str(marker.get_meta("service","")).is_empty():check(marker.get_child(0).size.x<=24 and marker.get_child(0).size.y<=24,"compact facility badge hitbox")
	game.city_overview.track_facility("city_artisan")
	check(not game.city_overview.visible and game.quest_navigation.facility_id=="city_artisan" and game.quest_navigation.get_goal(game.exploration).stage_id=="facility","map facility guide")
	check(game.save_system.write_slot(3) and game.save_system.load_slot(3) and game.quest_navigation.facility_id=="city_artisan","facility and completed quests persist")
	game.options.update("bgm",20);game.options.update("sfx",80);game.options.update("size",2)
	check(game.options.bgm_volume==20 and game.options.sfx_volume==80 and game.dialogue_text.get_theme_font_size("font_size")==24,"independent volume and readable font controls")
	var config=ConfigFile.new()
	check(config.load(game.options.FILE)==OK and config.get_value("audio","bgm")==20 and config.get_value("audio","sfx")==80 and config.get_value("display","body_size")==24,"preferences persist on disk outside story save")
	check(AudioServer.get_bus_index("Music")!=AudioServer.get_bus_index("Effects"),"separate audio buses")
	game.adventure_ui.open_help();check(paused and not ui.body.text.is_empty(),"help available in game");key(KEY_F2);await process_frame;check(not paused,"help key closes without advancing")
	game.settings_menu.open_menu();ui.open_options();check(ui.window.visible and ui.mode=="options" and paused,"settings opens preferences")
	var sliders: Array=ui.options_box.get_children().filter(func(node):return node is HSlider)
	sliders[0].value=35;sliders[1].value=85
	check(game.options.bgm_volume==35 and game.options.sfx_volume==85,"real sliders update independent channels")
	var selectors: Array=ui.options_box.get_children().filter(func(node):return node is OptionButton)
	selectors[0].select(0);selectors[0].item_selected.emit(0)
	check(game.options.body_size==18,"real font selector callback")
	selectors[0].select(2);selectors[0].item_selected.emit(2)
	var toggles: Array=ui.options_box.get_children().filter(func(node):return node is CheckButton)
	toggles[0].button_pressed=true;check(game.options.fullscreen,"fullscreen toggle callback")
	toggles[0].button_pressed=false;check(not game.options.fullscreen,"windowed toggle callback")
	game.options.update("bgm",20);game.options.update("sfx",80)
	ui.primary_action();key(KEY_ESCAPE);await process_frame
	check(game.settings_menu.window.visible and paused,"help returns to settings without unpausing")
	game.settings_menu.close_menu()
	game.money=1000
	for service in game.exploration.city_data.services:
		if service.id=="city_instructor":game.state="service";game.city_service.open_counter(service)
	game.city_service.select_item("cheongpung")
	check(game.city_service.message.get_parsed_text().contains("[부족]") and game.city_service.balance_preview.text.contains("구매 후 소지금 650문"),"conditions and balance preview")
	game.city_service.close_counter();game.start_battle()
	game.battle.select_basic_attack();game.battle.use_selected()
	var deadline=Time.get_ticks_msec()+8000
	while game.battle.busy and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(game.battle.records.size()==4 and game.battle.records[0].damage==23,"executed action and actual recovery recorded")
	ui.open_log();check(ui.body.get_parsed_text().contains("기본공격") and not ui.body.get_parsed_text().contains("공격할 예정"),"log records actions, not future intent")
	ui.close_menu();game.battle.enemy_hp=1;game.battle.select_basic_attack();game.battle.use_selected()
	deadline=Time.get_ticks_msec()+8000
	while game.battle.busy and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(ui.mode=="result" and ui.window.visible and ui.results[-1].won,"victory opens result without granting invented loot")
	ui.close_menu();game.reset();game.options.update("size",2)
	var batches: Array=[]
	for name in ["prologue_dialogues","chapter_one_intro","trade_intro","changsha_bandit_story","normal_quests"]:
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name+".json"))
		if name=="prologue_dialogues":
			for scene in data.values():batches.append(scene.lines)
		elif name=="chapter_one_intro":batches.append(data)
		elif name=="trade_intro":
			for quest in data.quests:batches.append(quest.lines)
		elif name=="changsha_bandit_story":
			for lines in data.scenes.values():batches.append(lines)
		else:
			for quest in data.values():
				for part in ["intro","accept","decline","progress","report","post","branch_a","branch_b"]:
					if quest.has(part):batches.append(quest[part])
				for lines in quest.steps.values():batches.append(lines)
	for batch in batches:
		for line in batch:
			game.dialogue_text.text=line[1];await process_frame
			check(game.dialogue_text.get_line_count()*game.dialogue_text.get_line_height()<=game.dialogue_text.size.y+2,"large text fits: "+str(line[1]).left(18))
	game.options.update("size",1)

	await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_ADVENTURE_FEATURES: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
