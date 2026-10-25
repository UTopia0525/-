extends SceneTree
var game
const Combat=preload("res://scripts/combat_actions.gd")
const Qi=preload("res://scripts/inner_qi.gd")
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ALLIANCE_STORY: "+message)
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
	var state=game.alliance_story.snapshot()
	check(game.save_system.write_slot(slot),"stable phase save: "+game.save_system.error)
	check(game.save_system.load_slot(slot) and game.alliance_story.snapshot()==state,"quest phase/outcome restored")
	await process_frame
func press_f() -> void:
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=down;Input.parse_input_event(e);await process_frame
func travel(id: String) -> void:
	var w=game.exploration;var exits=w.travel_exits.filter(func(n):return n.id==id)
	check(exits.size()==1,"portal exists: "+id)
	if exits.is_empty():return
	w.player.position=w.safe_player_position(exits[0].position+Vector2(0,45));w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id")==id,"F selects travel portal: "+id);await press_f()
func open_journal() -> void:
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("active")
	check(game.adventure_ui.entries.has(game.alliance_story.ID),"main story in Q")
	game.adventure_ui.close_menu()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	var q=game.alliance_story;var v=game.alliance_visit;var w=game.exploration
	await approach("alliance_guard_left");drain()
	check(v.phase=="unverified" and q.stage_id=="dormant","no invitation before campaign")
	# Begin at the existing campaign's settled state, with its existing rewards.
	game.bandit_story.stage="completed";game.bandit_story.reward_granted=true;game.money=500;game.progress.fame=5
	for key in game.progress.stats:game.progress.stats[key]=20
	await process_frame
	await approach("alliance_guard_left");drain()
	check(v.phase=="unverified" and q.stage_id=="invitation","campaign alone cannot bypass meeting Song")
	await open_journal()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"changsha","arrival":[1195,515]}})
	game.settings_menu.open_menu();q.maybe_start();check(game.dialogue_lines.is_empty(),"settings not interrupted")
	game.settings_menu.close_menu();q.maybe_start()
	check(q.stage_id=="invitation" and not game.dialogue_lines.is_empty() and actor(q.GIVER)!=null,"Song appears only for invitation event")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(q.stage_id=="invitation" and v.phase=="unverified","invitation commits at last line")
	game.advance_dialogue()
	check(q.stage_id=="invited" and w.area_name=="changsha" and actor(q.GIVER)==null,"invitation does not teleport or leave permanent Song")
	await roundtrip(1)
	await travel("travel:road_east");check(w.area_name=="mountain_road","walk east from Changsha to road")
	await travel("travel:wuchang");check(w.area_name=="wuchang","road reaches Wuchang south")
	check(game.quest_navigation.get_goal(w).position==actor("alliance_guard_left").position,"guide points to actual F guard target")
	await approach("alliance_guard_left")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(actor(q.GIVER)==null and v.phase=="unverified","guards stop hero before Song vouches")
	game.advance_dialogue()
	check(actor(q.GIVER)!=null and v.phase=="unverified","Song arrives after identity check")
	var portraits=game.dialogue_cast.portrait_choices.values()
	check(portraits.size()==4,"hero guards and guarantor on screen")
	for portrait in portraits:check(portraits.count(portrait)==1,"distinct portraits in gate scene")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(v.phase=="unverified","gate stays closed until guarantee concludes")
	game.advance_dialogue();await physics_frame;await physics_frame
	check(v.phase=="visiting" and q.stage_id=="steward" and actor(q.GIVER)==null,"guarantee opens one visit and event Song leaves")
	check(not w.path_to(w.city_point([1480,810])).is_empty(),"authorized gate now navigable")
	await roundtrip(2)
	# Asking the teacher before meeting the steward cannot grant a technique.
	await approach("gwak_jinseok");check(game.dialogue_lines==v.data.scenes.gwak_idle,"teacher directs early visitor to steward");drain();check(q.stage_id=="steward" and game.progress.learned.size()==1,"cannot skip steward")
	await travel("travel:office_entry");check(w.area_name=="alliance_office","F enters actual steward office")
	await approach("heo_mungyu")
	while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
	check(q.stage_id=="steward","steward referral waits for last line");game.advance_dialogue()
	check(q.stage_id=="instructor","steward refers hero to courtyard teacher")
	await roundtrip(3)
	await travel("travel:office_exit");await approach("gwak_jinseok");drain()
	check(game.adventure_ui.mode=="teaching" and game.adventure_ui.rows.get_child_count()==5,"five-way selection")
	for row in game.adventure_ui.rows.get_children():check(row.icon!=null,"each art has existing icon")
	game.adventure_ui.select_teaching("gwanak")
	check(game.adventure_ui.body.text.contains("창") and game.adventure_ui.body.text.contains("내기"),"selection explains weapon and qi")
	game.adventure_ui.primary_action();check(game.adventure_ui.mode=="choice","explicit final confirmation")
	game.adventure_ui.secondary_action();check(game.adventure_ui.mode=="teaching" and game.progress.learned.size()==1,"can go back without learning")
	game.adventure_ui.close_menu();await roundtrip(4)
	var stats=game.progress.stats.duplicate();var money: int=game.money;var fame: int=game.progress.fame;var loadout=game.progress.loadout.duplicate()
	# Rewind this stable pre-selection save for each mutually exclusive reward.
	for id in q.ARTS:
		check(game.save_system.load_slot(4),"rewind teacher stage")
		q.open_teaching();game.adventure_ui.select_teaching(id);game.adventure_ui.primary_action();game.adventure_ui.primary_action()
		check(game.dialogue_lines.size()>0 and id not in game.progress.learned,"confirm starts teaching without immediate grant")
		check(not game.save_system.write_slot(9),"teaching dialogue saves blocked")
		while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
		check(id not in game.progress.learned and not game.impostor_quest.eligible(),"last teaching line still pending reward/unlock")
		game.advance_dialogue()
		check(q.stage_id=="completed" and q.received_art==id and game.progress.learned==["samjae",id],"exactly one selected art granted: "+id)
		check(v.phase=="training_complete" and game.impostor_quest.eligible(),"real teaching unlocks impostor quest")
		check(game.progress.stats==stats and game.money==money and game.progress.fame==fame and game.progress.favor_for("murim_alliance")==0,"no unapproved money/stat/fame/favor grant")
		check(game.progress.loadout==loadout,"learned skill not forced over equipped slots")
		q._finish_teaching();q.confirm_art("hoeryu");check(game.progress.learned.size()==2,"duplicate callback and second choice cannot grant again")
		game.player_menu.open_menu("martial");game.player_menu.select_item(id)
		check(game.player_menu.detail.text.contains(game.progress.arts.get_skill(id).name),"K displays received skill")
		check(game.progress.assign(id,3),"learned skill can be assigned in K");game.player_menu.close_menu()
		await roundtrip(5)
	# Closing the visit is driven by physically walking out, not merely leaving the office.
	w.player.position=w.city_point([1480,820]);w.player.stop();Input.action_press("move_down")
	for i in range(100):await physics_frame
	Input.action_release("move_down");await physics_frame
	check(v.phase=="closed","leaving compound closes visit")
	check(w.path_to(w.city_point([1480,810])).is_empty(),"no unrestricted reentry")
	await approach("alliance_guard_left");drain();check(v.phase=="closed" and game.progress.learned.size()==2,"guard refuses repeat visit without erasing reward")
	check(game.impostor_quest.marker_for(game.impostor_quest.GIVER)=="!","follow-up quest remains unlocked after leaving")
	await roundtrip(6)
	var old=game.save_system.capture();old.erase("alliance_story")
	check(game.save_system.validate(old),"pre-story save accepted")
	var file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(8) and q.stage_id=="completed","legacy trained save resumes as completed")
	var bad=game.save_system.capture();bad.alliance_story.received_art="samjae"
	check(not game.save_system.validate(bad),"invalid reward rejected")
	bad=game.save_system.capture();bad.progress.learned.erase(q.received_art);bad.progress.loadout[3]=""
	check(not game.save_system.validate(bad),"completed story without learned reward rejected")
	game.reset();check(q.stage_id=="dormant" and q.received_art=="" and game.progress.learned==["samjae"],"new game resets story and grant")
	await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_ALLIANCE_STORY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
