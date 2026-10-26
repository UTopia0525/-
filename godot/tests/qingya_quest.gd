extends SceneTree
var game
var failed=false
const Travel=preload("res://scripts/overland_travel.gd")
func _initialize() -> void:run.call_deferred()
func check(ok: bool,text: String) -> void:
	if not ok:failed=true;push_error("QINGYA: "+text)
func drain() -> void:
	for i in range(300):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"dialogue must end")
func close_choice() -> void:
	if game.adventure_ui.window.visible:game.adventure_ui.close_menu()
func settle() -> void:await process_frame;await physics_frame;await physics_frame
func f() -> void:
	for down in [true,false]:
		var event=InputEventKey.new();event.keycode=KEY_F;event.physical_keycode=KEY_F;event.pressed=down;Input.parse_input_event(event);await process_frame
func target(id: String) -> Dictionary:
	var world=game.exploration
	for npc in world.ambient_nodes:
		if npc.get_meta("npc_id")==id:return {"position":npc.position,"id":id}
	for entry in world.travel_exits+world.objectives:
		if entry.id==id:return entry
	return {}
func interact(id: String) -> void:
	var t=target(id);check(not t.is_empty(),"target exists: "+id)
	if t.is_empty():quit(1);await process_frame;return
	var path=game.exploration.path_to(t.position,true)
	check(not path.is_empty(),"reachable interaction: "+id)
	if path.is_empty():quit(1);await process_frame;return
	game.exploration.player.position=path[-1];game.exploration.player.stop();await settle()
	check(game.exploration.nearest().get("id")==id,"F selects "+id)
	await f()
func init_world() -> void:
	game.reset();game.start_wuchang();await settle()
	for key in game.progress.stats:game.progress.stats[key]=20
	game.progress.learned.append("cheongpung")
	game.qingya_quest.refresh_world()
func investigation() -> void:
	await interact("qy_ren_shoutian");drain()
	check(game.adventure_ui.window.visible and game.qingya_quest.phase=="available","offered but not auto-accepted")
	game.adventure_ui.primary_action();drain();await settle()
	check(game.qingya_quest.phase=="investigate","accepted by dialogue")
	for id in ["qy_shi_xiaoman","qy_zhou_guiniang","qy_liang_boan"]:
		await interact(id);drain();await settle()
	check(game.qingya_quest.phase=="confront","all testimony enables first confrontation")
func audience() -> void:
	await interact("travel:camp");await settle()
	check(game.exploration.area_name=="qingya_camp","north portal enters camp")
	check(target("qy_ren_shouyi").is_empty(),"captive is not reachable before admission")
	await interact("qy_ding_kui");drain();await settle()
	await interact("qy_ren_shouyi");drain();await settle()
	await interact("qy_ma_yunpiao");drain()
	check(game.qingya_quest.phase=="decision" and game.adventure_ui.window.visible,"chief opens two final paths")
func win_fight() -> void:
	var limit=20
	while game.state=="battle" and limit>0:
		game.battle.select_skill("basic_attack");game.battle.use_selected()
		while game.battle.busy:await create_timer(.03).timeout
		limit-=1
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"])
	await init_world()
	var q=game.qingya_quest;var world=game.exploration
	await interact("travel:qingya");await settle()
	check(world.area_name=="qingya_hamlet" and q.phase=="available","walking in does not accept quest")
	check(world.ambient_nodes.size()==4,"four residents before event")
	check(not game.ordinary_quests.marker_for(q.GIVER).is_empty(),"available quest marker exposed to maps")
	check(not world.path_to(world.city_point([1470,530]),true).is_empty(),"west-east road remains passable without quest")
	check(not Travel.blocked_reason(game,"nanjing").is_empty(),"unbuilt Nanjing destination cannot load as deck")
	game.quest_navigation.track("wuchang_missing_herbalist","offer")
	check(not game.quest_navigation.get_goal(world).is_empty(),"old quest guides back from new region")
	await investigation()
	check(game.quest_navigation.quest_id=="wuchang_missing_herbalist","parallel progress preserves selected quest")
	check(game.save_system.write_slot(1),"save before first confrontation")
	await interact("qy_hou_liu");drain();game.adventure_ui.primary_action();drain();await settle()
	check(q.phase=="camp","can proceed without first battle")
	await audience()
	close_choice()
	check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"save and restore before irreversible branch")
	q=game.qingya_quest;world=game.exploration
	await interact("qy_ma_yunpiao");drain();game.adventure_ui.secondary_action();game.adventure_ui.primary_action();drain();await settle()
	check(q.phase=="ready" and q.branch=="maintain","confirmed noncombat branch")
	await interact("travel:hamlet");await settle()
	var cash=game.money;var insight=game.progress.stats.insight
	await interact(q.GIVER)
	check(game.money==cash and game.progress.stats.insight==insight,"no reward before last report line")
	drain();await settle()
	check(q.phase=="completed" and game.money==cash and game.progress.stats.insight==mini(100,insight+5),"maintain pays insight only once")
	await interact(q.GIVER);drain();check(game.progress.stats.insight==mini(100,insight+5),"repeat report cannot duplicate insight")
	await interact("travel:wuchang");await settle();await interact("travel:qingya");await settle()
	check(not q.ruined and world.ambient_nodes.size()==4,"maintain village survives return")
	# Rewind to the real pre-choice save and take combat branch.
	check(game.save_system.load_slot(2),"rewind to decision")
	q=game.qingya_quest;world=game.exploration
	game.progress.stats.strength=100;game.progress.stats.agility=100;game.progress.stats.inner=100
	await interact("qy_ma_yunpiao");drain();game.adventure_ui.primary_action();game.adventure_ui.primary_action();drain()
	check(game.state=="battle" and q.phase=="fight_chief","chief battle starts with matching quest state")
	check(not game.save_system.write_slot(9),"combat saving blocked")
	game._on_defeat();drain();await settle()
	check(q.phase=="decision" and q.branch=="","chief defeat does not commit outcome or reward")
	await interact("qy_ma_yunpiao");drain();game.adventure_ui.primary_action();game.adventure_ui.primary_action();drain()
	await win_fight();drain();await settle()
	check(q.phase=="ready" and q.branch=="assault","actual committed attacks complete chief battle")
	await interact("travel:hamlet");await settle()
	check(not q.ruined,"first return before reward is intact")
	game.progress.stats.agility=20
	cash=game.money;var before=game.progress.stats.agility
	await interact(q.GIVER);drain();check(q.phase=="reward" and game.money==cash,"reward selection precedes atomic payment")
	close_choice();check(game.save_system.write_slot(7),"pending stat choice is saved without paying")
	for stat in ["strength","agility","constitution"]:
		check(game.save_system.load_slot(7),"rewind unpaid reward for "+stat)
		var old_stats=game.progress.stats.duplicate();q._grant(stat)
		check(game.money==cash+200 and game.progress.stats[stat]==mini(100,int(old_stats[stat])+5),"stat selection applies exact gain with cap: "+stat)
		for other in old_stats:
			if other!=stat:check(game.progress.stats[other]==old_stats[other],"unselected stats unchanged")
	check(game.save_system.load_slot(7),"restore real reward choice")
	q._choose_stat();game.adventure_ui.secondary_action();game.adventure_ui.primary_action();await settle()
	check(q.phase=="completed" and game.money==cash+200 and q.reward_stat=="agility" and game.progress.stats.agility==mini(100,before+5),"chosen stat and cash paid once with cap")
	q._grant("strength");check(game.money==cash+200,"repeated callback cannot duplicate money")
	check(game.save_system.write_slot(3),"intact rewarded village can save")
	check(game.save_system.load_slot(3) and not q.departed and not q.ruined,"loading does not count as map departure")
	await interact("travel:wuchang");await settle()
	check(q.departed and not q.ruined,"other map arms return consequence")
	check(game.save_system.write_slot(4) and game.save_system.load_slot(4),"departure state persists outside")
	await interact("travel:qingya");await settle();drain();await settle()
	check(q.ruined and world.ambient_nodes.is_empty(),"return replaces village and removes all residents")
	check(world.regional_map.data.objects.any(func(o):return o.prefab=="ruined_home"),"independent buildings use ruined assets")
	var reward_money=game.money;var stats=game.progress.stats.duplicate()
	for key in ["home","store","place"]:
		await interact("qingya_ruin:"+key);drain();await settle()
	check(q.regret_seen and q.ruin_checks.size()==3,"three investigations complete regret dialogue")
	check(game.money==reward_money and game.progress.stats==stats,"aftermath awards nothing")
	check(game.save_system.write_slot(5) and game.save_system.load_slot(5) and q.ruined and q.regret_seen,"ruins and regret survive save restore")
	var invalid=q.snapshot();invalid.branch="maintain";check(not q.valid(invalid),"inconsistent ruined peaceful branch rejected")
	# Earlier confrontation: defeat is retryable, and an actual battle can clear it.
	check(game.save_system.load_slot(1),"rewind to confrontation")
	q=game.qingya_quest
	await interact("qy_hou_liu");drain();game.adventure_ui.secondary_action()
	check(q.in_battle(),"first collision can fight")
	game._on_defeat();drain();await settle();check(q.phase=="confront","defeat returns to retryable phase")
	await interact("qy_hou_liu");drain();game.adventure_ui.secondary_action()
	game.progress.stats.strength=100;game.battle.player_stats.strength=100;game.battle.player_stats.agility=100
	await win_fight();drain();await settle();check(q.phase=="camp","actual sentry battle unlocks audience")
	# Older saves have no quest field and get a clean unaccepted incident.
	game.reset();game.start_city();await settle()
	var old=game.save_system.capture();old.erase("qingya_quest")
	check(game.save_system.validate(old),"old save without new quest field validates")
	var file=FileAccess.open(game.save_system.path(6),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(6) and game.qingya_quest.phase=="available","old save defaults incident without rewards")
	game.reset();await create_timer(.2).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_QINGYA_QUEST: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
