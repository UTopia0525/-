extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error("BOOK_QUEST: "+msg)
func drain() -> void:
	for i in range(150):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite dialogue")
func approach(id: String) -> void:
	var w=game.exploration;var point=Vector2.ZERO
	for a in w.ambient_nodes:
		if a.get_meta("npc_id")==id:point=a.position
	check(point!=Vector2.ZERO,"NPC exists "+id)
	var path=w.path_to(point,true);check(not path.is_empty(),"walkable approach "+id)
	if path.is_empty():return
	w.player.position=path[-1];w.player.stop();await physics_frame;await physics_frame
	check(w.nearest().get("id")==id,"F selects "+id)
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=down;Input.parse_input_event(e);await process_frame
func scholar_position() -> Vector2:
	for a in game.exploration.ambient_nodes:
		if a.get_meta("npc_id")==game.book_quest.SCHOLAR:return a.position
	return Vector2.ZERO
func save_restore() -> void:
	var phase: String=game.book_quest.phase
	check(game.save_system.write_slot(8),"save "+phase+game.save_system.error)
	check(game.save_system.load_slot(8),"load "+phase+game.save_system.error)
	check(game.book_quest.phase==phase,"phase restored "+phase)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("nanjing");game.exploration.set_active(true)
	var q=game.book_quest;var p=game.progress;var start=scholar_position()
	check(q.marker_for(q.GIVER)=="!","available giver marker")
	await approach(q.SCHOLAR);drain();check(q.phase=="available","early scholar cannot bypass acceptance")
	await approach(q.GIVER);drain();game.adventure_ui.secondary_action();drain();check(q.phase=="available","decline")
	game.silk_quest.accept();drain();game.cart_quest.accept();drain();game.quest_navigation.track(game.silk_quest.ID,game.silk_quest.stage())
	await approach(q.GIVER);drain();game.adventure_ui.primary_action();drain()
	var money: int=game.money;var stats=p.stats.duplicate();var loadout=p.loadout.duplicate()
	for phase in ["instructor","innkeeper","scholar","return_book","solution"]:
		check(q.phase==phase,"phase "+phase);await save_restore()
		check(game.silk_quest.phase=="market" and game.cart_quest.phase=="worker","concurrent quests intact")
		check(game.quest_navigation.quest_id==game.silk_quest.ID,"selected tracking retained")
		if phase=="innkeeper":
			game.progress.learned.append("gwanak");game.alliance_story.stage_id="completed";game.alliance_story.received_art="gwanak";game.alliance_visit.phase="training_complete"
			game.nanjing_relief_quest.phase="missing"
			await approach(q.INNKEEPER);check(game.adventure_ui.mode=="choice","shared innkeeper chooser")
			game.adventure_ui.primary_action()
		else:
			await approach(q.target())
			if phase=="instructor":
				game.adventure_ui.secondary_action();drain();check(game.state=="service","instructor trade stays accessible")
				game.city_service.close_counter();await approach(q.INSTRUCTOR);game.adventure_ui.primary_action()
		check(not game.save_system.write_slot(9),"dialogue save blocked")
		drain()
		if phase=="solution":await create_timer(1.1).timeout;drain()
	check(q.phase=="ready" and q.marker_for(q.GIVER)=="?","report ready after copy")
	check(start.distance_to(scholar_position())>500,"scholar returns to book street")
	check(p.manuals.is_empty() and not "swaerang" in p.learned,"no early reward/learning")
	await save_restore();await approach(q.GIVER);drain()
	check(q.phase=="completed" and p.manuals.get("swaerang_manual")==1,"manual reward exactly one")
	q._complete();check(p.manuals.swaerang_manual==1,"no duplicate reward")
	check(game.money==money,"no extra money")
	for key in stats:check(int(p.stats[key])==int(stats[key]),"no stat reward")
	await save_restore()
	game.player_menu.open_menu("inventory");game.player_menu.select_category("manual");game.player_menu.select_item("swaerang_manual")
	check(not game.player_menu.action.disabled,"manual usable in I")
	game.player_menu.apply_selection();check("swaerang" in p.learned and p.manuals.swaerang_manual==0,"manual use learns and consumes")
	check(p.loadout==loadout,"learning does not autoequip")
	game.player_menu.switch_mode("martial");game.player_menu.select_item("swaerang");game.player_menu.select_slot(3);game.player_menu.apply_selection()
	check(p.loadout[3]=="swaerang","K loadout works")
	game.player_menu.close_menu();await save_restore()
	check("swaerang" in p.learned and p.manuals.swaerang_manual==0,"used book survives save")
	p.grant_manual("swaerang_manual");check(not p.use_manual("swaerang_manual") and p.manuals.swaerang_manual==1,"known art does not consume")
	check(p.arts.raw_damage("swaerang",{"strength":20,"inner":20,"agility":200})==230,"current grid coefficient: strength9.5 + inner2; agility is not damage")
	check(p.arts.qi_cost("swaerang")==32 and p.arts.can_use_with_weapon("swaerang","saber") and not p.arts.can_use_with_weapon("swaerang","sword"),"current grid cost and weapon restriction")
	check(not p.issue("art","swaerang",9999).is_empty(),"not sold at instructor")
	for id in ["swaerang","swaerang_manual"]:check(preload("res://scripts/catalog_icons.gd").texture(id)!=null,"icon "+id)
	var old=game.save_system.capture();old.erase("book_quest");old.progress.erase("manuals");check(game.save_system.validate(old),"old save accepted")
	var bad=p.snapshot();bad.manuals={"swaerang_manual":-1};check(not p.valid(bad),"negative quantity rejected")
	bad.manuals={"unknown":1};check(not p.valid(bad),"unknown item rejected")
	game.reset();check(q.phase=="available" and p.manuals.is_empty(),"reset")
	game.queue_free();await process_frame;print("BOOK_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
