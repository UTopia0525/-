extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("HANGZHOU_RESIDENTS: "+msg)
func press_f() -> void:
	for pressed in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=pressed;Input.parse_input_event(e);await process_frame;await physics_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var w=game.exploration
	for area in ["hangzhou","cuiyue_hall"]:
		w.load_area(area);await physics_frame
		check(w.ambient_nodes.size()==(10 if area=="hangzhou" else 6),"approved cast count "+area)
		var positions={};var before=game.progress.snapshot();var money=game.money
		for entry in w.city_data.residents:
			var body=w.decorations.get_node(entry.id);positions[entry.id]=[body.position.x,body.position.y]
			var visual=Rect2(body.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
			for bounds in w.scenery_bounds:check(not visual.grow(6).intersects(bounds),"whole body clears scenery "+entry.name)
			for bounds in w.blockers:check(not visual.grow(6).intersects(bounds),"whole body clears wall "+entry.name)
			for road in w.city_data.road_centers:check(not w._city_rect(road).has_point(body.position),"off major street "+entry.name)
			check(not entry.quest_actor and not str(body.get_meta("hud_role")).contains("하오문"),"ordinary resident, no faction leak")
			var path=w.path_to(body.position,true);check(not path.is_empty(),"reachable F target "+entry.name)
			if path.is_empty():continue
			w.player.position=path[-1];w.player.stop();await physics_frame
			check(w.nearest().get("id")==entry.id,"F target unambiguous "+entry.name)
			await press_f();check(game.dialogue_cast.active_actor==entry.id,"actual F conversation "+entry.name)
			var texture=game.dialogue_cast.texture_for(game.PORTRAITS.ACTORS[entry.id])
			if entry.has("portrait"):
				check(texture.resource_path==entry.portrait,"dedicated portrait "+entry.name)
				check(body.get_child(1).texture.atlas.resource_path==("res://assets/characters/cuiyue/residents.png" if entry.id=="cy_manager" else "res://assets/characters/cuiyue/performers.png"),"dedicated exploration sprite")
			else:check(texture.resource_path==game.dialogue_cast.basic_portraits[entry.basic_portrait].path,"existing basic portrait reused")
			check(game.dialogue_backdrop.visible and not game.save_system.blocked_reason().is_empty(),"dialogue backdrop and save restriction")
			for i in range(12):
				if game.dialogue_lines.is_empty():break
				game.advance_dialogue()
			if entry.has("service_id"):game.city_service.close_counter()
			check(game.dialogue_lines.is_empty() and w.active,"conversation ends")
		check(money==game.money and before==game.progress.snapshot(),"chatter grants no rewards")
		w.player.position=w.safe_player_position(w.city_point(w.city_data.spawn));w.player.stop()
		check(game.save_system.write_slot(9) and game.save_system.load_slot(9),"save/reload populated "+area)
		for npc in w.ambient_nodes:
			var p=positions[npc.name];check(npc.position.distance_to(Vector2(p[0],p[1]))<1,"stable placement after restore")
		print("RESIDENT_POSITIONS "+area+" "+JSON.stringify(positions))
	game.queue_free();await process_frame;print("HANGZHOU_RESIDENTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
