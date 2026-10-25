extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("WUCHANG_RESIDENTS: "+message)
func drain() -> void:
	for i in range(20):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"dialogue terminates")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_wuchang();await physics_frame;await physics_frame
	game.money=2000
	# An unfinished Changsha introduction must not complete at a Wuchang shop.
	game.chapter_number=1;game.chapter_one.intro_complete=true
	var intro=game.trade_intro.current()
	game.chapter_one.accepted_quests[intro.id]={"status":"active","stage":intro.stage}
	game.trade_intro.sync_navigation()
	var world=game.exploration
	check(world.ambient_nodes.size()==11,"eight civilians plus three alliance NPCs")
	check(world.city_data.services.size()==3,"three existing trade types")
	var portraits: Array=[]
	var quest_before=game.chapter_one.snapshot();var regular_before=game.ordinary_quests.snapshot()
	for entry in world.city_data.residents.filter(func(n):return not n.get("alliance_actor",false)):
		var npc=world.decorations.get_node(entry.id)
		for marker in world.occlusion_roots:
			if marker.get_meta("npc_id","")==entry.id:
				check(("거래" in marker.get_child(0).text)==entry.has("service_id"),"trade tag only on actual merchants")
		check(npc.get_parent()==world.player.get_parent(),"NPC and player share foot sorting")
		var visual=Rect2(npc.position+world.CITIZEN_BOUNDS.position,world.CITIZEN_BOUNDS.size)
		for bounds in world.scenery_bounds:check(not visual.grow(6).intersects(bounds),"NPC clears full building silhouette: "+entry.name)
		for road in world.city_data.road_centers:check(not Rect2(road[0]*4,road[1]*4,road[2]*4,road[3]*4).has_point(npc.position),"NPC stays out of road center: "+entry.name)
		var path=world.path_to(npc.position,true)
		check(not path.is_empty(),"click approach reaches "+entry.name)
		if path.is_empty():continue
		for point in path:check(world.can_stand(point),"approach avoids scenery and NPC feet")
		world.player.position=path[-1];world.player.stop();await physics_frame
		check(world.nearest().get("id","")==entry.id,"F picks intended civilian: "+entry.name)
		game.interact()
		if entry.id in ["wc_liu_baicao","wc_shi_dayong"]:game.adventure_ui.secondary_action()
		check(game.dialogue_cast.active_actor==entry.id and game.dialogue_name.text.begins_with(entry.name),"speaker name is correct")
		check(game.dialogue_backdrop.visible,"Wuchang dialogue dims background")
		var actor=game.PORTRAITS.ACTORS[entry.id]
		var texture=game.dialogue_cast.texture_for(actor)
		check(texture!=null and texture.resource_path==actor.portrait and ResourceLoader.exists(actor.portrait),"dedicated portrait is used")
		check(texture.resource_path not in portraits,"each resident has unique artwork")
		portraits.append(texture.resource_path)
		check(game.dialogue_cast.framing.profiles.has(actor.portrait),"portrait has aligned face profile")
		var choices=game.dialogue_cast.portrait_choices.values()
		check(choices.size()==2 and choices[0]!=choices[1],"speaker and player portraits stay distinct")
		drain()
		if entry.has("service_id"):
			check(game.state=="service" and game.city_service.service.actor_id==entry.id,"greeting opens correct person's counter")
			check(game.city_service.portrait.texture.resource_path==actor.portrait,"counter keeps resident portrait")
			if entry.service_id=="city_merchant":
				game.city_service.select_item("bear_strength_pill");game.city_service.transact()
				check(game.progress.inventory.bear_strength_pill==1 and game.money==1900,"existing 100-mun elixir purchase works")
			if entry.service_id=="city_artisan":
				game.city_service.select_item("refined_sword");game.city_service.transact()
				check("refined_sword" in game.progress.owned_weapons and game.money==1600,"existing 300-mun weapon purchase works")
			game.city_service.close_counter()
		check(game.dialogue_lines.is_empty() and world.active,"conversation returns control")
	check(game.chapter_one.snapshot()==quest_before and game.ordinary_quests.snapshot()==regular_before,"civilian talk creates no unapproved quest/reward")
	check(game.ordinary_quests.marks.is_empty(),"no fake quest exclamation marks")
	game.quest_navigation.facility_id="city_merchant"
	check(game.quest_navigation.get_goal(world).label.begins_with("유백초"),"facility guide points to local herbalist")
	game.toggle_city_map()
	check(game.city_overview.facility_widgets[0].visible,"Wuchang facility tools enabled")
	game.toggle_city_map()
	check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"civilian region preserves saves")
	check(world.ambient_nodes.size()==11,"load recreates civilians once")
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_WUCHANG_RESIDENTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
