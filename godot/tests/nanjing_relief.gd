extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("NANJING_RELIEF: "+msg)
func drain() -> void:
	for i in range(120):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func actor(id: String):
	for npc in game.exploration.ambient_nodes:
		if npc.get_meta("npc_id")==id:return npc
	return null
func approach(id: String) -> void:
	var w=game.exploration;var a=actor(id)
	check(is_instance_valid(a),"actor present "+id)
	if not is_instance_valid(a):return
	var path=w.path_to(a.position,true)
	check(not path.is_empty(),"walkable F approach "+id)
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id")==id,"F selects "+id)
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=down;Input.parse_input_event(e);await process_frame
func roundtrip() -> void:
	var q=game.nanjing_relief_quest;var expected=q.phase
	check(game.save_system.write_slot(8),"save "+expected+" "+game.save_system.error)
	check(game.save_system.load_slot(8),"load "+expected+" "+game.save_system.error)
	check(q.phase==expected,"phase survives "+expected)
	check(game.exploration.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==q.GIVER).size()==(0 if expected in ["missing","completed"] else 1),"Lu presence survives "+expected)
func qualify() -> void:
	game.progress.learned.append("gwanak");game.alliance_story.stage_id="completed";game.alliance_story.received_art="gwanak";game.alliance_visit.phase="training_complete"
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var q=game.nanjing_relief_quest;var w=game.exploration
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"qingya_hamlet","arrival":[1410,530]}})
	var east=w.travel_exits.filter(func(e):return e.id=="travel:nanjing")[0]
	check(preload("res://scripts/overland_travel.gd").use(game,east) and w.area_name=="nanjing","actual east portal enters Nanjing")
	await physics_frame
	check(q.status()=="locked" and q.marker_for(q.GIVER)=="","locked before teaching")
	q.accept();check(q.phase=="available","direct accept cannot bypass gate")
	await approach(q.GIVER);drain();check(not game.adventure_ui.window.visible,"locked Lu offers only smalltalk")
	game.progress.learned.append("gwanak");q.refresh_world();check(not q.eligible(),"learning an art alone is insufficient")
	game.progress.learned.erase("gwanak");qualify();q.refresh_world()
	check(q.status()=="available" and q.marker_for(q.GIVER)=="!","teaching unlocks exclamation")
	check(game.PORTRAITS.ACTORS[q.GIVER].basic_portrait=="male_young","Lu uses a young common portrait")
	for id in [q.GIVER,"jin_yulan"]:
		var a=actor(id)
		check(is_instance_valid(a),"civilian contact exists")
		for child in a.get_children():
			if child is Node2D:
				for label in child.get_children():
					if label is Label:check(not label.text.contains("하오문"),"no secret affiliation overhead")
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("available");check(game.adventure_ui.entries.has(q.ID),"available journal entry");game.adventure_ui.close_menu()
	# Only Lu can offer. Neither the lady nor later investigation targets advance early.
	await approach("jin_yulan");check(not game.dialogue_lines.is_empty(),"Jin has ordinary smalltalk before her investigation step");drain();check(q.phase=="available","early contact cannot advance quest")
	await approach(q.LADY);drain();check(q.phase=="available","Namgung cannot start quest")
	await approach(q.GIVER);drain();check(game.adventure_ui.mode=="choice","explicit optional acceptance")
	game.adventure_ui.secondary_action();drain();check(q.phase=="available","decline leaves quest available")
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain();check(q.phase=="resident","accept starts resident inquiry")
	var initial_money: int=game.money;var initial_stats=game.progress.stats.duplicate();var initial_fame: int=game.progress.fame
	check(game.progress.known_factions.is_empty(),"no favor revealed before reward")
	game.quest_navigation.track(game.herbalist_quest.ID,"offer")
	for expected in ["resident","yeonseo","ledger","contact","witness","arrest","ready"]:
		check(q.phase==expected,"stage order "+expected)
		await roundtrip()
		check(game.quest_navigation.quest_id==game.herbalist_quest.ID,"another quest tracking is preserved")
		check(not game.quest_navigation.get_goal(w).is_empty(),"other regional quest routes out of Nanjing")
		if expected=="ready":break
		check(q.marker_for(q.LADY)!="?","no early report marker")
		var next_id: String=q.target()
		if expected=="resident":
			q.handle_interaction("nj_clerk");drain();check(q.phase==expected,"early ledger cannot skip resident")
		await approach(next_id)
		check(not game.dialogue_lines.is_empty(),"F opens dialogue "+expected)
		check(game.dialogue_backdrop.visible,"city backdrop dims")
		check(not game.save_system.write_slot(9),"dialogue save blocked")
		check(q.phase==expected,"dialogue must finish before advancing")
		var paths=game.dialogue_cast.portrait_choices.values();var unique={}
		for path in paths:unique[path]=true
		check(paths.size()==unique.size(),"distinct portraits")
		drain()
	check(q.phase=="ready" and q.marker_for(q.LADY)=="?" and game.ordinary_quests.marker_for(q.LADY)=="?","ready report question mark reaches full map and minimap")
	game.city_overview.open_for(w,q.goal(w));check(game.city_overview.district_labels.size()==8,"full map renders all eight district labels");game.city_overview.hide()
	check(game.money==initial_money and game.progress.favor_for("namgung")==0,"no early rewards")
	await approach(q.LADY)
	# Finish just the report, leaving the automatic follow-up unread.
	while q.phase=="ready" and not game.dialogue_lines.is_empty():game.advance_dialogue()
	check(q.phase=="inquiry" and is_instance_valid(actor(q.GIVER)),"Lu remains during reward and inquiry")
	check(game.money==initial_money+500 and game.progress.favor_for("namgung")==10,"exact user rewards")
	q._paid();check(game.money==initial_money+500,"repeat reward callback does not duplicate")
	drain();check(q.phase=="missing" and not is_instance_valid(actor(q.GIVER)),"Lu disappears only after inquiry ends")
	await roundtrip()
	game.adventure_ui.open_favor();check(game.adventure_ui.body.text.contains("강호"),"R favor menu available");check(game.progress.known_factions.has("namgung"),"earned Namgung faction revealed");game.adventure_ui.close_menu()
	await approach(q.INNKEEPER);drain();check(q.phase=="completed","innkeeper confirms absence and completes")
	await roundtrip();q._paid();q.accept();check(game.money==initial_money+500 and game.progress.favor_for("namgung")==10,"completion cannot pay or accept again")
	for stat in initial_stats:check(int(game.progress.stats[stat])==int(initial_stats[stat]),"no unrequested stat reward "+stat)
	check(game.progress.fame==initial_fame,"no unrequested fame reward")
	# Original portrait reused, all city services usable, all NPCs stand off scenery.
	check(game.PORTRAITS.ACTORS[q.LADY].portrait=="res://assets/portraits/namgung/yeonseo.png","canonical Yeonseo portrait reused")
	for a in w.ambient_nodes:
		for b in w.scenery_bounds:check(not Rect2(a.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size).intersects(b),"NPC body avoids buildings "+str(a.name))
	for id in ["nj_merchant","nj_artisan","nj_instructor"]:
		await approach(id);drain();check(game.state=="service" and game.city_service.service.actor_id==id,"service portrait and counter "+id);game.city_service.close_counter()
	# Old layout saves must preserve quest/rewards and avoid newly moved water/buildings.
	var legacy=game.save_system.capture();legacy.world.layout_version=1;legacy.world.position=[2700,2000]
	var file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	var paid_money: int=game.money
	check(game.save_system.load_slot(8),"old Nanjing layout save loads")
	check(q.phase=="completed" and game.money==paid_money and game.progress.favor_for("namgung")==10,"old layout migration preserves story and rewards")
	check(w.player.position.distance_to(w.city_point(w.city_data.spawn))<200 and w.can_stand(w.player.position),"old layout relocates to clear western entry")
	# Existing schema3 saves without the new quest remain readable.
	var old=game.save_system.capture();old.erase("nanjing_relief_quest");check(game.save_system.validate(old),"old save without new field validates")
	var bad=game.save_system.capture();bad.nanjing_relief_quest.phase="unknown";check(not game.save_system.validate(bad),"unknown phases rejected")
	bad=game.save_system.capture();bad.alliance_story.stage="dormant";check(not game.save_system.validate(bad),"progress without teaching rejected")
	var return_exit=w.travel_exits[0];preload("res://scripts/overland_travel.gd").use(game,return_exit);check(w.area_name=="qingya_hamlet","return portal works")
	preload("res://scripts/overland_travel.gd").use(game,east);check(not is_instance_valid(actor(q.GIVER)),"absence persists after region travel")
	game.reset();check(q.phase=="available" and game.progress.favor_for("namgung")==0,"new game resets quest and favor")
	game.queue_free();await process_frame
	if not failed:print("NANJING_RELIEF PASS: prerequisite, F route, investigation, handover, once-only rewards, disappearance, saves, services, concurrent tracking")
	quit(1 if failed else 0)
