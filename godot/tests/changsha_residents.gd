extends SceneTree
var failed=false
var game
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("CHANGSHA_RESIDENTS: "+message)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city();await physics_frame
	var world=game.exploration
	var named=world.city_data.residents.filter(func(n):return n.has("character_profile"))
	check(world.ambient_nodes.size()==16 and named.size()==11,"16 present: 11 named quest roles plus 3 traders and 2 campaign roles")
	var ids=world.city_data.residents.map(func(n):return n.id)
	for removed in ["inn_waiter","carpenter","old_farmer"]:check(removed not in ids,"unused resident removed: "+removed)
	for id in ids:check(not str(id).begins_with("resident_"),"no filler resident remains")
	var names: Array=[]
	for entry in named:
		check(entry.name not in names and entry.name!=entry.role,"individual name for "+entry.id);names.append(entry.name)
		check(not entry.character_profile.background.is_empty() and not entry.character_profile.personality.is_empty(),"simple character background recorded")
		check(game.PORTRAITS.ACTORS[entry.id].name==entry.name,"dialogue identity matches world name")
		check(game.dialogue_cast.basic_portraits.has(entry.character_profile.basic_portrait),"existing basic portrait reused")
		var npc=world.decorations.get_node(entry.id)
		check(not world.path_to(npc.position,true).is_empty(),"named quest NPC remains reachable")
		for tag in world.occlusion_roots:
			if tag.get_meta("npc_id","")==entry.id:
				check(tag.get_child(0).text.contains(entry.name) and tag.get_child(0).text.contains(entry.role),"nameplate includes name and original role")
		if game.ordinary_quests.marks.has(entry.id) and game.ordinary_quests.marker_for(entry.id)!="":
			check(game.ordinary_quests.marks[entry.id].position.y+46<npc.position.y-174,"quest mark clears new nameplate")
	for id in game.quest_navigation.definitions:
		for stage in game.quest_navigation.definitions[id].stages.values():
			for goal in stage.goals:
				if goal.has("npc_id"):check(goal.npc_id in ids,"navigation never points to removed NPC")
	var target=world.decorations.get_node("general_merchant")
	var path=world.path_to(target.position,true);world.player.position=path[-1];world.player.stop();await physics_frame
	var money: int=game.money
	game.interact();check(game.dialogue_name.text.begins_with("고만복"),"casual conversation uses new personal name")
	check(game.dialogue_text.text.contains("끈 한 타래"),"casual conversation reflects background")
	game.advance_dialogue();check(game.money==money,"smalltalk grants no quest reward")
	check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"unchanged NPC IDs preserve saves")
	check(world.ambient_nodes.size()==16 and game.PORTRAITS.ACTORS.cloth_merchant.name=="오금화","load retains trimmed roster and names")
	game.say([["resident_01","지난 장사 거리에서 나누던 말입니다."]])
	check(preload("res://tests/legacy_save_fixture.gd").write(game,2) and game.save_system.load_slot(2),"legacy removed-bystander dialogue save remains readable")
	check(world.ambient_nodes.size()==16 and game.dialogue_cast.portraits.has("resident_01"),"legacy dialogue does not respawn deleted bystanders")
	game.advance_dialogue()
	game.reset();await create_timer(.5).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_CHANGSHA_RESIDENTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
