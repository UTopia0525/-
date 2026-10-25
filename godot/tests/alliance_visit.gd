extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ALLIANCE VISIT: "+message)
func drain() -> void:
	for i in range(50):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"dialogue terminates")
func press_f() -> void:
	for pressed in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=pressed;Input.parse_input_event(e);await process_frame
	await physics_frame
func talk(id: String) -> void:
	var w=game.exploration;var npc=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==id)[0]
	w.player.position=w.safe_player_position(npc.position+Vector2(0,55));w.player.stop();await physics_frame
	check(w.nearest().get("id","")==id,"F selects "+id);await press_f()
	check(not game.dialogue_lines.is_empty(),"F starts "+id)
	check(game.dialogue_cast.active_actor==id,"F target speaks first "+id)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.options.seen.append("city");game.start_wuchang();await physics_frame;await physics_frame
	var w=game.exploration;var v=game.alliance_visit
	check(w.ambient_nodes.size()==13,"ten civilians plus two guards and instructor")
	for entry in v.data.npcs:
		if entry.area!="wuchang":continue
		var npc=w.decorations.get_node(entry.id)
		check(npc.position.distance_to(w.city_point(entry.point))<20,"intentional faction post retained "+entry.id)
		var visual=Rect2(npc.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
		for bounds in w.scenery_bounds:check(not visual.grow(6).intersects(bounds),"full body clears structures "+entry.id)
	check(w.decorations.get_node("alliance_guard_left").position.x<1480*4 and w.decorations.get_node("alliance_guard_right").position.x>1480*4,"guards flank left/right gate")
	check(w.path_to(w.city_point([1480,810])).is_empty(),"unverified entry is physically disconnected")
	for id in ["heo_mungyu","gwak_jinseok"]:
		var texture=game.dialogue_cast.texture_for(game.PORTRAITS.ACTORS[id])
		check(texture.get_image().get_pixel(0,0).a==0,"named portrait has transparent background "+id)
		check(game.dialogue_cast.framing.profiles.has(texture.resource_path),"named portrait uses aligned face profile "+id)
	var money=game.money;var progress=game.progress.snapshot()
	w.player.position=w.city_point([1480,940]);w.player.stop();Input.action_press("move_up")
	for i in range(18):await physics_frame
	Input.action_release("move_up");await physics_frame
	check(not game.dialogue_lines.is_empty(),"approaching gate prompts refusal")
	check(game.dialogue_lines[0][0]=="alliance_guard_left","gate guard speaks")
	var choices=game.dialogue_cast.portrait_choices.values();check(choices.size()==3 and choices[0]!=choices[1] and choices[1]!=choices[2] and choices[0]!=choices[2],"hero and two guard illustrations are distinct")
	drain();Input.action_press("move_up")
	for i in range(90):await physics_frame
	Input.action_release("move_up");await physics_frame
	check(w.player.position.y>=904*4+15,"holding up cannot walk through the gate barrier")
	game.bandit_story.stage="completed";game.bandit_story.reward_granted=true
	await talk("alliance_guard_right");check(str(game.dialogue_lines).contains("방문 약조") and str(game.dialogue_lines).contains("토벌"),"bandit completion alone does not grant entry")
	drain();check(v.phase=="unverified","guard talk never grants admission")
	check(v.grant_visit(),"future guarantor callback opens authorized visit");await physics_frame;await physics_frame
	w.player.position=w.city_point([1480,940]);w.player.stop();check(not w.path_to(w.city_point([1480,810])).is_empty(),"authorized passage is navigable")
	Input.action_press("move_up");for i in range(100):await physics_frame
	Input.action_release("move_up");await physics_frame
	check(w.player.position.y<904*4,"authorized keyboard crossing succeeds")
	await talk("gwak_jinseok");check(game.dialogue_name.text=="곽진석","dedicated instructor name");check(game.dialogue_cast.texture_for(game.PORTRAITS.ACTORS.gwak_jinseok).resource_path.ends_with("gwak-jinseok.png"),"dedicated instructor art");drain()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"alliance_office","arrival":[256,289]}});await physics_frame
	check(w.ambient_nodes.size()==1,"steward placed in office")
	await talk("heo_mungyu");check(game.dialogue_name.text=="허문규","dedicated steward name");check(game.dialogue_backdrop.visible,"office dialogue dims background");drain()
	check(game.money==money and game.progress.snapshot()==progress,"dialogues grant no skill/money/stats yet")
	check(v.mark_training_complete(),"future teaching callback marks visit for closure")
	check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"training-complete access survives office save")
	check(v.phase=="training_complete","restored phase retained")
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"wuchang","arrival":[1480,820]}});await physics_frame
	w.player.position=w.city_point([1480,820]);w.player.stop();Input.action_press("move_down")
	for i in range(95):await physics_frame
	Input.action_release("move_down");await physics_frame
	check(v.phase=="closed" and w.player.position.y>921*4,"leaving after teaching closes the pass without trapping exit")
	check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"closed pass survives saves")
	check(v.phase=="closed","closed visit cannot reopen by reload")
	check(w.path_to(w.city_point([1480,810])).is_empty(),"closed visit physically blocks re-entry")
	await talk("alliance_guard_left");check(str(game.dialogue_lines).contains("지난 방문") or str(game.dialogue_lines).contains("앞선 방문"),"repeat entry gets post-training refusal");drain()
	check(not v.grant_visit() and not v.mark_training_complete(),"closed visit cannot be reopened by duplicate callbacks")
	var legacy=game.save_system.capture();legacy.erase("alliance_visit");legacy.world.position=[1480*4,810*4]
	var file=FileAccess.open(game.save_system.path(3),FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	check(game.save_system.load_slot(3),"old save without access state is accepted");await physics_frame;await physics_frame
	check(v.phase=="unverified" and v.gate_shape.disabled,"old inside save is allowed to exit")
	var invalid=game.save_system.capture();invalid.alliance_visit={"phase":"open_everything"};check(not game.save_system.validate(invalid),"invalid access state rejected")
	game.reset();await create_timer(.2).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	if not failed:print("ALLIANCE VISIT PASS: guard posts, refusal, physical gate, future callbacks, closure, portraits/dialogue, no rewards, old/new saves")
	quit(1 if failed else 0)
