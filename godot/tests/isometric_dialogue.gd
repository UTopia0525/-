extends SceneTree
var scene
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ISO_DIALOGUE: "+message)
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func key(code: int,pressed: bool,echo=false) -> void:
	var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.echo=echo
	Input.parse_input_event(event);Input.flush_buffered_events();await process_frame;await process_frame
func tap(code: int) -> void:
	await key(code,true);await key(code,false)
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func pose():return [scene.actor.facing,scene.actor.facing_flipped]
func run() -> void:
	create_timer(90).timeout.connect(func():push_error("ISO_DIALOGUE watchdog");quit(2))
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(2)
	scene.patrols_enabled=false
	var a=scene.npcs[0];var b=scene.npcs[1];var ui=scene.dialogue
	# Physical range, occlusion, corner and gate cases use the real collision world.
	scene.actor.set_logical(Vector2(6,9));a.set_logical(Vector2(6.65,9));b.set_logical(Vector2(7.8,10));await frames(2)
	check(scene.interaction.target==a and a.interaction_target and not b.interaction_target,"one nearby target highlighted")
	check(scene.interaction.caption.text.contains("F 대화"),"visible F prompt")
	b.set_logical(Vector2(6.55,9.65));await frames(2);check(scene.interaction.target==a,"nearest accessible target wins")
	a.set_logical(Vector2(6.6,8.7));b.set_logical(Vector2(6.6,9.3));await frames(2);check(scene.interaction.target==a,"equal-distance target is deterministic")
	scene.actor.set_logical(Vector2(6.8,6.95));a.set_logical(Vector2(6.8,5.95));b.set_logical(Vector2(10,10));await frames(2)
	check(not scene.interaction.reachable(a) and scene.interaction.target==null,"wall prevents dialogue even at short distance")
	scene.actor.set_logical(Vector2(8.65,2.8));a.set_logical(Vector2(7.8,1.95));await frames(2)
	check(not scene.interaction.reachable(a),"building corner blocks dialogue")
	scene.actor.set_logical(Vector2(3.12,7.05));a.set_logical(Vector2(3.12,6.05));await frames(2)
	check(scene.interaction.reachable(a),"open gate permits dialogue through clear passage")
	scene.visibility_hint.refresh();check(not scene.visibility_hint.captions[a].visible,"focused NPC shows one interaction name instead of a duplicate hidden label")
	# Clicking retains selection-only behavior; it never begins or walks to dialogue.
	scene.actor.set_logical(Vector2(6,9));a.set_logical(Vector2(6.65,9));await frames(2)
	var click_start=scene.actor.position
	await click(scene.get_canvas_transform()*(a.position+Vector2(0,-45)))
	check(not ui.active and scene.selected==a and scene.actor.position==click_start,"NPC click selects without dialogue or movement")
	# Simultaneous and staggered W+D releases keep the diagonal-facing pose.
	a.set_logical(Vector2(10,10));b.set_logical(Vector2(10,11))
	for release_first in [KEY_D,KEY_W]:
		scene.actor.set_logical(Vector2(8,9));await key(KEY_W,true);await key(KEY_D,true);await frames(10)
		var diagonal=pose();check(diagonal==["back",true],"W+D uses upper-right orientation")
		await key(release_first,false);await frames(2);await key(KEY_W if release_first==KEY_D else KEY_D,false);await frames(3)
		check(pose()==diagonal,"staggered release preserves last diagonal orientation")
		await key(KEY_A,true);await frames(2);check(pose()==["front",true],"new movement direction updates promptly")
		await key(KEY_A,false);await frames(2)
	scene.actor.set_logical(Vector2(8,9));await key(KEY_W,true);await key(KEY_D,true);await frames(5)
	await key(KEY_D,false);await frames(9);check(pose()==["back",false],"deliberately continuing one axis changes facing")
	await key(KEY_W,false);await frames(2)
	var stopped=pose();scene.actor._face_movement(Vector2.ZERO,1.0/60);check(pose()==stopped,"zero-input collision correction cannot replace the last facing")
	# Initiate with a real F key while patrols are enabled.
	scene.reset_trial();scene.actor.set_logical(Vector2(3.9,9.7));scene.patrols_enabled=true;await frames(2)
	var first_source=ui.data.conversations.GatePorter.duplicate(true)
	await key(KEY_F,true)
	check(ui.active and ui.dialogue_index==0 and ui.target==a,"initial F opens exactly the first line")
	if not ui.active:
		print("F diagnostic: target=",scene.interaction.target," reachable=",scene.interaction.reachable(a)," release_lock=",scene.interaction.require_release," F=",Input.is_action_pressed("iso_interact")," positions=",scene.actor.logical," / ",a.logical)
		scene.queue_free();await process_frame;quit(1);return
	check(scene.actor.motion_paused and a.motion_paused and not b.motion_paused,"only player and partner paused")
	check(ui.dialogue_panel.get_script().resource_path=="res://scripts/paper_dialogue_panel.gd","actual shared paper panel")
	check(ui.dialogue_history.get_script().resource_path=="res://scripts/dialogue_history.gd","actual shared history")
	check(ui.dialogue_cast.get_script().resource_path=="res://scripts/dialogue_portraits.gd","actual shared portrait compositor")
	var partner="iso_gate_porter"
	check(ui.dialogue_cast.portraits.hero.position.x<100 and ui.dialogue_cast.portraits[partner].position.x>800,"hero left, partner right")
	check(ui.dialogue_cast.portrait_choices.hero=="res://assets/portraits/player/hero.png","original hero portrait")
	check(ui.dialogue_cast.portrait_choices[partner]=="res://assets/portraits/extras/male_common_a.png","existing common portrait")
	check(ui.dialogue_cast.portraits.hero.self_modulate==ui.CAST.DIM and ui.dialogue_cast.portraits[partner].self_modulate==Color.WHITE,"inactive hero dimmed")
	check(ui.backdrop.visible and ui.backdrop.color.a>.6,"background dimmed")
	await key(KEY_F,true,true);check(ui.dialogue_index==0,"held-key echo does not skip")
	await key(KEY_F,false)
	var player_point=scene.actor.position;var partner_point=a.position;var other_start=b.position
	var patrol_state=[a.patrol.index,a.patrol.step,a.patrol.pause,a.patrol.detour]
	await key(KEY_W,true);await frames(90)
	check(scene.actor.position==player_point and a.position==partner_point,"held movement cannot move conversation participants")
	check(b.position.distance_to(other_start)>30,"other NPC continues actual patrol")
	check([a.patrol.index,a.patrol.step,a.patrol.pause,a.patrol.detour]==patrol_state,"talk preserves waypoint and yielding state")
	check(scene.depth_cycles==0,"moving third NPC retains depth consistency")
	await tap(KEY_F);check(ui.dialogue_index==1,"F advances one line")
	check(ui.dialogue_cast.portraits.hero.self_modulate==Color.WHITE and ui.dialogue_cast.portraits[partner].self_modulate==ui.CAST.DIM,"speaker brightness swaps without swapping sides")
	var hints=scene.show_occlusion_hint
	await tap(KEY_H);check(ui.dialogue_history.visible and paused and ui.dialogue_history.shown_lines==2,"shared history pauses and displays only read lines")
	var transcript=ui.dialogue_history.transcript.get_parsed_text()
	check(transcript.contains(first_source[0][1]) and transcript.contains(first_source[1][1]) and not transcript.contains(first_source[2][1]),"future lines remain hidden")
	await tap(KEY_F);check(ui.dialogue_index==1,"F cannot advance behind history")
	await tap(KEY_ESCAPE);check(not paused and not ui.dialogue_history.visible and scene.show_occlusion_hint==hints,"history returns without affecting world H toggle")
	await click(ui.dialogue_next.get_global_rect().get_center());check(ui.dialogue_index==2,"real mouse click advances shared-style next button once")
	await tap(KEY_F);await tap(KEY_F);await key(KEY_F,true)
	check(not ui.active and not scene.actor.motion_paused and not a.motion_paused,"finish restores original movement states")
	check(ui.data.conversations.GatePorter==first_source,"reusable dialogue source not cleared")
	check(not ui.CAST.ACTORS.has(partner),"no prototype identity leaked into shared static registry")
	await frames(15);await key(KEY_F,true,true)
	check(not ui.active and scene.actor.position==player_point,"held F and W cannot reopen or cause a post-dialogue jump")
	await key(KEY_F,false);await key(KEY_W,false);await frames(2);await key(KEY_W,true);await frames(8);await key(KEY_W,false)
	check(scene.actor.position.distance_to(player_point)>10,"fresh movement works after neutral input")
	await frames(30);check(a.position.distance_to(partner_point)>20,"partner resumes authored route")
	# The other NPC has its own five-line conversation and a different existing portrait.
	scene.patrols_enabled=false;scene.reset_trial();scene.actor.set_logical(Vector2(10.35,5.35));await frames(2);await tap(KEY_F)
	check(ui.active and ui.target==b and ui.dialogue_lines.size()==5,"second NPC conversation works")
	check(ui.dialogue_cast.portrait_choices.iso_rear_porter=="res://assets/portraits/wuchang/wu_deshu.png","second common portrait reused")
	await key(KEY_F,true);await tap(KEY_H);await key(KEY_F,false);await tap(KEY_H)
	await tap(KEY_F);check(ui.dialogue_index==2,"F released inside history cannot swallow the next fresh press")
	await tap(KEY_H);check(paused,"history active before scene removal")
	scene.queue_free();await process_frame;await process_frame
	check(not paused,"removing scene restores shared-history tree pause")
	check(not InputMap.has_action("iso_interact"),"prototype input actions removed")
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/main.tscn","main entry unchanged")
	print("ISOMETRIC_DIALOGUE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
