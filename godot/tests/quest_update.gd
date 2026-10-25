extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("QUEST_UPDATE: "+message)
func drain() -> void:
	for i in range(160):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
func travel(area: String,point: Array) -> void:
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":area,"arrival":point}})
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
	var nav=game.quest_navigation;var ui=game.adventure_ui;var w=game.exploration
	game.ordinary_quests.accept("changsha_baskets");drain()
	game.ordinary_quests.accept("changsha_pages");drain()
	check(nav.quest_id=="changsha_baskets","accepting a second quest preserves first guide")
	game.wages_quest.accept();drain();game.grain_quest.accept();drain()
	ui.open_journal();ui.select_quest(game.wages_quest.ID);ui.primary_action()
	check(nav.quest_id==game.wages_quest.ID,"Q explicitly selects another quest across regions")
	game.grain_quest.talk_giver();drain()
	check(nav.quest_id==game.wages_quest.ID and game.grain_quest.phase=="shipping","another quest progresses without replacing selected guide")
	check(nav.get_goal(w).position==w.city_point([1490,510]),"Changsha guides to Wuchang exit")
	travel("mountain_road",[125,1175]);check(nav.get_goal(w).position==w.city_point([740,64]),"road guides to Wuchang")
	travel("wuchang",[1100,1790]);await process_frame
	ui.open_journal();ui.set_filter("active")
	check(ui.entries.has("changsha_baskets") and ui.entries.has("changsha_pages") and ui.entries.has(game.wages_quest.ID) and ui.entries.has(game.grain_quest.ID),"all accepted quests coexist in other city")
	ui.select_quest("changsha_baskets");ui.primary_action()
	check(nav.get_goal(w).position==w.city_point([1100,1840]),"Wuchang guides back to Changsha")
	check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"save/load cross-region selection")
	check(nav.quest_id=="changsha_baskets" and game.wages_quest.phase=="inspect" and game.grain_quest.phase=="shipping","selection and concurrent progress persist")
	ui.open_journal();ui.set_filter("available")
	check(ui.entries.has("changsha_family") and ui.entries.has(game.plaque_quest.ID),"both cities' available quests listed")
	check(not ui.entries.has(game.impostor_quest.ID),"locked quest remains unavailable");ui.close_menu()
	travel("alliance_office",[256,289]);check(nav.get_goal(w).goal_id=="travel:office_exit","interior guides toward Changsha")
	travel("changsha",[600,500]);await process_frame
	game.ordinary_quests.refresh_world()
	check(game.ordinary_quests.marker_for("vegetable_vendor")=="","accepted quest removes offer icon")
	check(game.ordinary_quests.marks.well_grandmother.get_theme_font_size("font_size")==68,"world quest icons double34 to68")
	for id in game.trade_intro.rewards.quests:check(game.trade_intro.rewards.quests[id].stat_gains.insight==2,"Changsha reward2: "+id)
	check(game.bandit_story.data.reward.insight==2 and game.wages_quest.data.reward.insight==2,"main and Wuchang insight rewards2")
	game.money=4000
	for service in w.city_data.services:
		if service.id=="city_artisan":game.state="service";game.city_service.open_counter(service)
	var shop=game.city_service
	check(shop.rows.get_child_count()==3 and shop.weapon_stock()==["refined_sword","thickback_saber","balanced_spear"],"Changsha exactly three basic weapons")
	shop.select_item("hundredfold_sword");shop.transact()
	check(game.money==4000 and "hundredfold_sword" not in game.progress.owned_weapons,"hidden expensive item cannot bypass stock")
	for id in shop.weapon_stock():shop.select_item(id);shop.transact()
	check(game.money==3100,"all three cost300 each");shop.close_counter()
	travel("wuchang",[760,1190]);await process_frame
	for service in w.city_data.services:
		if service.id=="city_artisan":game.state="service";shop.open_counter(service)
	check(shop.rows.get_child_count()==9,"Wuchang weapon tiers retained");shop.close_counter()
	var citizen=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==game.plaque_quest.GIVER)[0]
	w.player.position=w.safe_player_position(citizen.position+Vector2(48,30));game.minimap.refresh()
	check(game.minimap.quest_badges.any(func(b):return b.symbol=="!"),"minimap shows available quests in Wuchang")
	game.city_overview.open_for(w,nav.get_goal(w))
	check(game.city_overview.actor_markers.any(func(m):return m is Label and m.text=="!"),"overview shows available quest badges")
	game.city_overview.show_residents=false;game.city_overview.apply_filter()
	check(game.city_overview.actor_markers.any(func(m):return m is Label and m.text=="!" and m.visible),"quest icons remain when ordinary residents are hidden")
	game.city_overview.hide()
	var combat=preload("res://scripts/combat_actions.gd").new()
	var enemies=game.encounters()+[{"id":"tutorial","stats":{"strength":12,"agility":12,"constitution":5,"inner":6,"insight":5},"weapon":"thickback_saber","skills":["bandit_chop","soemok"]}]
	for e in enemies:
		check("soemok" in e.skills,"lower art assigned: "+e.id)
		var amount: int=e.stats.inner;var used:=false
		for turn in range(1,13):
			var plan=combat.enemy_plan(e.stats,e.weapon,e.skills,amount,turn)
			var a=combat.action(plan,e.stats,e.weapon)
			check(a.cost<=amount,"enemy respects qi: "+e.id)
			used=used or plan=="soemok";amount=mini(500,amount-int(a.cost)+int(e.stats.inner))
		check(used,"enemy actually uses learned lower art: "+e.id)
	game.start_battle();var b=game.battle
	check(not b.executed_icon.visible,"enemy icon is hidden before an executed move")
	b.select_skill("basic_defense");b.use_selected()
	while b.busy:await create_timer(.03).timeout
	b.use_selected()
	while b.turn_label.text!="상대의 차례":await create_timer(.02).timeout
	check(b.executed_icon.visible and b.executed_icon.texture==preload("res://scripts/catalog_icons.gd").texture("soemok"),"new enemy art icon appears only when actually executed")
	while b.busy:await create_timer(.03).timeout
	game.reset();await create_timer(.3).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_QUEST_UPDATE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
