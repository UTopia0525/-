extends SceneTree
const Combat=preload("res://scripts/combat_actions.gd")
const Qi=preload("res://scripts/inner_qi.gd")
var game
var failed:=false
var balance: Array=[]
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("HERBALIST_QUEST: "+message)
func drain() -> void:
	for i in range(80):
		if game.dialogue_lines.is_empty():return
		game.advance_dialogue()
	check(false,"finite conversation")
func event_count() -> int:
	return game.exploration.ambient_nodes.filter(func(n):return n.get_meta("npc_id","") in ["herb_gatherer","herb_ruffian"]).size()
func press_f() -> void:
	var event=InputEventKey.new();event.keycode=KEY_F;event.physical_keycode=KEY_F;event.pressed=true
	Input.parse_input_event(event);await process_frame
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await process_frame
func approach(id: String) -> void:
	var world=game.exploration
	var entries: Array=world.objectives.duplicate()
	for npc in world.ambient_nodes:entries.append({"id":npc.get_meta("npc_id"),"position":npc.position})
	for entry in entries:
		if entry.id!=id:continue
		var path=world.path_to(entry.position,true)
		check(not path.is_empty(),"approach path exists: "+id)
		if path.is_empty():return
		world.player.position=path[-1];world.player.stop();await physics_frame;await physics_frame
		check(world.nearest().get("id","")==id,"F finds target: "+id)
		await press_f();return
	check(false,"target exists: "+id)
func save_roundtrip(slot: int) -> void:
	check(game.save_system.write_slot(slot),"write stable phase "+game.herbalist_quest.phase+": "+game.save_system.error)
	check(game.save_system.load_slot(slot),"restore stable phase")
	await process_frame
func wait_turn() -> void:
	var deadline=Time.get_ticks_msec()+20000
	while game.battle.busy and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(not game.battle.busy,"combat motion finishes")
func simulation(stats: Dictionary,weapon: String,skill: String,e: Dictionary) -> Dictionary:
	var c=Combat.new();var pq=Qi.new();var eq=Qi.new();pq.start(stats.inner);eq.start(e.stats.inner)
	var hp=300;var ehp=int(e.max_hp)
	for turn in range(1,81):
		var intent=c.enemy_plan(e.stats,e.weapon,e.skills,eq.amount,turn)
		var enemy=c.action(intent,e.stats,e.weapon)
		var action=c.action("basic_attack",stats,weapon)
		for id in [skill,"samjae"]:
			var option=c.action(id,stats,weapon)
			if not option.is_empty() and option.cost<=pq.amount and option.raw>action.raw:action=option
		check(pq.spend(action.cost),"player action affordable")
		ehp=maxi(0,ehp-c.damage(action.raw,e.stats.constitution,e.weapon,enemy.guard))
		if ehp==0:return {"win":true,"turns":turn,"hp":hp}
		check(eq.spend(enemy.cost),"enemy action affordable")
		hp=maxi(0,hp-c.damage(enemy.raw,stats.constitution,weapon,action.guard))
		if hp==0:return {"win":false,"turns":turn,"hp":hp}
		pq.recover_turn();eq.recover_turn()
	return {"win":false,"turns":80,"hp":hp}
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","battle","trade"])
	game.start_wuchang();await physics_frame
	var q=game.herbalist_quest;var world=game.exploration
	check(q.marker_for(q.GIVER)=="!","actual available quest has yellow exclamation")
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("available")
	check(game.adventure_ui.entries.has(q.ID),"available quest in journal")
	game.adventure_ui.select_quest(q.ID)
	check(game.adventure_ui.body.text.contains("200문") and not game.adventure_ui.body.text.contains("오성"),"journal advertises money only")
	game.adventure_ui.close_menu()
	await approach(q.GIVER);game.adventure_ui.primary_action();drain()
	check(game.adventure_ui.mode=="choice" and q.phase=="available","listening alone does not accept")
	game.adventure_ui.secondary_action();drain();check(q.phase=="available","can decline")
	await approach(q.GIVER);game.adventure_ui.secondary_action();drain()
	check(game.state=="service" and game.city_service.service.actor_id==q.GIVER,"medicine trade remains accessible")
	game.city_service.close_counter()
	await approach(q.GIVER);game.adventure_ui.primary_action();drain();game.adventure_ui.primary_action();drain()
	check(q.phase=="search" and game.quest_navigation.get_goal(world).position==world.city_point([1100,1840]),"accept guides to rural exit")
	await save_roundtrip(1)
	world.load_area("mountain_road");world.set_active(true);await process_frame
	check(event_count()==0,"no event NPC before clue investigation")
	check(not q.handle_interaction("herb_gatherer"),"cannot bypass clue by directly requesting encounter")
	world.player.position=world.city_point([760,325]);await process_frame
	check(event_count()==0 and world.nearest().get("id","") not in ["herb_gatherer","herb_ruffian"],"walking directly to encounter reveals nobody")
	await save_roundtrip(2)
	check(event_count()==0,"reload before clue cannot reveal actors")
	await approach(q.CLUE)
	check(q.phase=="search" and event_count()==0,"starting clue dialogue does not reveal actors")
	check(not game.save_system.write_slot(9),"investigation dialogue cannot save")
	game.advance_dialogue();check(event_count()==0,"first clue line cannot reveal actors")
	drain();await process_frame
	check(q.phase=="rescue" and event_count()==2,"only last investigation line unlocks two actors")
	check(world.objectives.filter(func(e):return e.id==q.CLUE).is_empty(),"consumed clue is no longer interactive")
	for npc in world.ambient_nodes:
		var visual=Rect2(npc.position+world.CITIZEN_BOUNDS.position,world.CITIZEN_BOUNDS.size)
		for bounds in world.scenery_bounds:check(not visual.grow(6).intersects(bounds),"event actor clears full scenery silhouette")
		for bounds in world.blockers:check(not visual.grow(6).intersects(bounds),"event actor clears blockers")
	var textures: Array=[]
	for id in ["hero","herb_gatherer","herb_ruffian"]:textures.append(game.dialogue_cast.texture_for(game.PORTRAITS.ACTORS[id]).resource_path)
	check(textures[0]!=textures[1] and textures[1]!=textures[2] and textures[0]!=textures[2],"conversation uses distinct portraits")
	await save_roundtrip(3);check(event_count()==2,"reload investigated phase creates actors exactly once")
	await approach("herb_gatherer")
	check(game.dialogue_backdrop.visible and game.adventure_ui.toast.position.y<500,"road dialogue dims scenery and notifications clear text")
	drain()
	check(game.state=="battle" and q.in_battle() and game.battle.enemy_hp==320 and game.battle.enemy_qi.amount==12,"Gu Chil encounter configured")
	check(not game.save_system.write_slot(9),"combat save blocked")
	game.battle.player_hp=1;game.battle.select_basic_attack();game.battle.use_selected();await wait_turn();drain()
	check(game.state=="explore" and q.phase=="rescue" and event_count()==2 and game.money==0,"defeat retreats without loss of clue or payout")
	await save_roundtrip(4)
	game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
	await approach("herb_ruffian");drain()
	check(game.battle.player_hp==300 and game.battle.qi.amount==20,"retry restores full condition")
	for turn in range(20):
		if game.state!="battle":break
		game.battle.select_skill("samjae");game.battle.use_selected();await wait_turn()
	drain();check(q.phase=="ready" and event_count()==0 and game.money==0,"victory unlocks report, does not pay, removes road NPCs")
	await save_roundtrip(5)
	check(game.quest_navigation.get_goal(world).position==world.city_point([740,64]),"report guides to Wuchang portal")
	world.load_area("wuchang");world.set_active(true);await physics_frame
	check(event_count()==1 and q.marker_for(q.GIVER)=="?","gatherer returned to herbalist, report question mark")
	await save_roundtrip(6)
	await approach("herb_gatherer");drain()
	check(q.phase=="ready" and game.money==0,"returned gatherer speaks but does not settle the quest")
	var insight: int=game.progress.stats.insight;var fame: int=game.progress.fame
	await approach(q.GIVER);game.adventure_ui.primary_action()
	check(not game.save_system.write_slot(9) and game.money==0,"report cannot save or pay early")
	drain()
	check(q.phase=="completed" and game.money==200 and game.progress.stats.insight==insight and game.progress.fame==fame,"report pays exactly 200 and changes no stats or fame")
	check(event_count()==0 and q.marker_for(q.GIVER).is_empty(),"completion removes temporary actor and quest marker")
	await save_roundtrip(7)
	await approach(q.GIVER);game.adventure_ui.primary_action();drain();q._complete()
	check(game.money==200,"revisit/reload/callback cannot duplicate payout")
	var old: Dictionary=game.save_system.capture();old.erase("herbalist_quest")
	check(game.save_system.validate(old),"older save without quest field stays valid")
	check(not q.valid({"phase":"battle"}) and not q.valid({"phase":null}),"invalid persistent phases rejected")
	var file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(game.save_system.load_slot(8) and q.phase=="available","old save defaults to unaccepted quest")
	# Approved enemy uses ordinary arts and their learning limits, shared qi and damage.
	var combat=Combat.new();var enemy: Dictionary=q.data.encounter
	for id in enemy.skills:check(combat.arts.can_learn(id,enemy.stats),"enemy meets art learning conditions")
	for id in game.progress.arts.definitions:
		var art: Dictionary=game.progress.arts.get_skill(id)
		if art.get("acquisition")!="city_instructor":continue
		var stats: Dictionary=game.progress.RULES.STARTING_STATS.duplicate()
		for key in art.requirements.stats:stats[key]=maxi(stats[key],art.requirements.stats[key])
		var total=0
		for value in stats.values():total+=int(value)
		stats.insight+=maxi(0,100-total)
		var weapon: String=game.progress.weapons.DEFAULT_BY_TYPE[art.required_weapon_type]
		var result=simulation(stats,weapon,id,enemy)
		balance.append(result.merged({"skill":id,"weapon":weapon,"stats":stats}))
		# Record extreme minimum builds; the enemy buff no longer guarantees an attack-only win.
		var balanced={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
		result=simulation(balanced,weapon,id,enemy)
		balance.append(result.merged({"skill":id,"profile":"balanced_100"}))
		check(result.win,"balanced realm floor clears with "+id)
	var out=FileAccess.open("user://herbalist-balance.json",FileAccess.WRITE);out.store_string(JSON.stringify(balance,"  "));out.close()
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_HERBALIST_QUEST: "+("FAIL" if failed else "PASS")+" · balance cases "+str(balance.size()))
	quit(1 if failed else 0)
