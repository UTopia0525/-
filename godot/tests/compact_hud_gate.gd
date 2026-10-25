extends SceneTree
var game
var failed:=false
const Travel=preload("res://scripts/overland_travel.gd")
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("COMPACT_GATE: "+message)
func drain() -> void:
	for i in range(160):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
func press_f() -> void:
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=down;Input.parse_input_event(e);await process_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city();await process_frame
	var w=game.exploration;var portal=w.travel_exits[0]
	var path=w.path_to(portal.position,true);check(not path.is_empty(),"locked portal is still approachable")
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id")==portal.id,"F targets actual east portal")
	var origin=w.player.position
	for stage in ["dormant","offered","preparing","after_second","report"]:
		game.bandit_story.stage=stage;game.bandit_story.reward_granted=false
		await press_f()
		check(w.area_name=="changsha" and not game.dialogue_lines.is_empty(),"F denies departure before paid report: "+stage)
		drain();check(w.active and w.player.position==origin,"denial resumes movement without relocation")
		check(portal.portal_label.text.contains("통행 제한"),"locked portal is labelled")
	game.bandit_story.stage="report"
	check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"save before reporting")
	check(not Travel.blocked_reason(game,"mountain_road").is_empty(),"load cannot unlock unpaid campaign")
	game.bandit_story.stage="completed";game.bandit_story.reward_granted=true;game.alliance_story.stage_id="invited"
	await process_frame
	check(w.travel_exits[0].portal_label.text==w.travel_exits[0].open_name,"paid report immediately updates portal label")
	check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"save paid campaign")
	await press_f();check(w.area_name=="mountain_road","F opens real road after paid report")
	Travel.use(game,{"travel":{"area":"changsha","arrival":[1440,510]}})
	check(w.area_name=="changsha" and Travel.blocked_reason(game,"mountain_road").is_empty(),"return travel retains unlock")
	check(is_equal_approx(w.camera.zoom.x,.8),"city uses wider0.8 zoom")
	check((root.get_visible_rect().size/w.camera.zoom).is_equal_approx(Vector2(1600,900)),"1280x720 shows1600x900 world units")
	check(game.minimap.size==Vector2(188,174),"compact minimap dimensions")
	await process_frame
	var buttons=game.compact_toolbar.get_children().filter(func(n):return n is Button)
	check(buttons.size()==7,"seven compact mouse shortcuts retained")
	for i in range(buttons.size()):
		check(buttons[i].get_global_rect().end.y<=720,"toolbar fits screen")
		for j in range(i):check(not buttons[i].get_global_rect().intersects(buttons[j].get_global_rect()),"toolbar buttons do not overlap")
	game._hud_action(0);check(game.player_menu.visible,"compact inventory shortcut works");game.player_menu.close_menu()
	game._hud_action(2);check(game.adventure_ui.window.visible and game.adventure_ui.mode=="journal","compact journal shortcut works");game.adventure_ui.close_menu()
	game._hud_action(5);check(game.settings_menu.window.visible,"compact settings shortcut works");game.settings_menu.close_menu()
	var total:=0
	for q in game.trade_intro.rewards.quests.values():total+=int(q.money)
	check(total==1250,"nine city quests now pay1250 total")
	for build in [{"weapon":"refined_sword","art":"cheongpung"},{"weapon":"thickback_saber","art":"danseok"},{"weapon":"balanced_spear","art":"gwanpung"}]:
		game.progress.reset();game.progress.stats.insight=28;game.money=total
		check(game.progress.purchase("weapon",build.weapon,game),"affordable weapon")
		for id in ["bear_strength_pill","light_step_pill","bone_fortifying_pill","qi_nourishing_pill","bear_strength_pill","light_step_pill"]:
			check(game.progress.purchase("elixir",id,game) and game.progress.consume(id),"six affordable elixirs")
		check(game.progress.purchase("art",build.art,game),"affordable learnable art: "+build.art)
		var stats_total:=0
		for value in game.progress.stats.values():stats_total+=int(value)
		check(game.money==0 and stats_total==104,"each300-mun weapon path reaches realm without leaving city")
	# Old completed quests receive only the newly approved cash difference once.
	for id in ["changsha_pages","changsha_waterway"]:
		game.ordinary_quests.records[id]={"status":"completed","done":game.ordinary_quests.definitions[id].steps.keys(),"branch":""}
	game.money=50
	var old=game.save_system.capture();old.erase("changsha_reward_revision")
	check(game.save_system.validate(old),"old save without cash revision validates")
	var file=FileAccess.open(game.save_system.path(3),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(3) and game.money==150,"old completed quests gain100 difference")
	check(game.save_system.write_slot(4) and game.save_system.load_slot(4) and game.money==150,"new save cannot repeat the adjustment")
	check(game.save_system.load_slot(3) and game.money==150,"reloading original save rewinds instead of accumulating cash")
	old.ordinary_quests.records.erase("changsha_waterway")
	check(game.save_system.reward_adjustment(old)==50,"one previously completed quest gains only50")
	old.changsha_reward_revision=2;check(not game.save_system.validate(old),"unknown cash revision rejected")
	game.reset();game.start_wuchang();check(w.area_name=="wuchang","explicit title preview remains available separately")
	game.reset();await create_timer(.3).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_COMPACT_HUD_GATE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
