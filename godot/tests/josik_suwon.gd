extends SceneTree
const Combat=preload("res://scripts/combat_actions.gd")
const Qi=preload("res://scripts/inner_qi.gd")
var failed:=false
var game
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("JOSIK: "+message)
func wait_turn() -> void:
	var deadline=Time.get_ticks_msec()+20000
	while game.battle.busy and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(not game.battle.busy,"exchange completes")
func run() -> void:
	var c=Combat.new();var stats={"strength":10,"agility":10,"constitution":10,"inner":10,"insight":10}
	for weapon in ["none"]+c.weapons.definitions.keys():
		var action=c.action("josik_suwon",stats,weapon)
		check(not action.is_empty() and action.raw==0 and action.cost==0 and action.guard==20 and action.qi_restore==20,"universal weapon-independent effects: "+weapon)
	var action=c.action("josik_suwon",stats,"plain_iron_sword")
	var qi=Qi.new();qi.start(10);var ready={}
	check(c.commit_support(action,qi,ready,1)==20 and qi.amount==30,"instant twice inner power")
	qi.recover_turn();check(qi.amount==40,"ordinary inner-power recovery added once")
	check(ready.josik_suwon==5,"used turn1 becomes available at turn5")
	for t in [2,3,4]:check(c.cooldown_remaining("josik_suwon",t,ready)==5-t,"blocked next three own turns")
	check(c.cooldown_remaining("josik_suwon",5,ready)==0,"available after three full turns")
	qi.restore(100,490);check(c.commit_support(action,qi,{},1)==10 and qi.amount==500,"cap five hundred")
	qi.restore(100,0)
	var high=stats.duplicate();high.inner=100
	check(c.commit_support(c.action("josik_suwon",high,"none"),qi,{},1)==200 and qi.amount==200,"inner100 restores two hundred")
	for inner in [0,1,10,20,50,100]:
		var sample=stats.duplicate();sample.inner=inner
		check(c.action("josik_suwon",sample,"plain_iron_sword").qi_restore==inner*2,"recovery follows inner-power stat")
	check(c.action("basic_defense",stats,"none").guard==20,"both actors basic guard reduced to twenty percent")
	check(c.damage(100,0,"none",20)==80,"twenty percent damage reduction")
	check(c.damage(100,20,"refined_sword",20)==51,"constitution and weapon passive with one active guard")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","battle"])
	game.progress.learned.append("josik_suwon");game.progress.assign("josik_suwon",3)
	game.start_battle(game.duel_quest.data.encounter)
	var b=game.battle
	b.select_skill("josik_suwon")
	check(b.detail.text.contains("200%") and b.detail.text.contains("현재 20") and b.detail.text.contains("20%") and b.detail.text.contains("3"),"battle explanation displays effects")
	check(b.skill_buttons[3].icon!=null,"new battle icon visible")
	check(b.qi.amount==10 and b.ready_turns.is_empty(),"preview does not restore or start cooldown")
	var hp: int=b.player_hp
	b.use_selected();b.use_selected();check(b.qi.amount==30 and b.ready_turns.josik_suwon==5,"one committed activation despite double press")
	await wait_turn()
	check(b.turn==2 and b.qi.amount==40,"instant gain plus one natural turn recovery")
	check(b.player_hp==hp-c.damage(28,10,"plain_iron_sword",20),"only this enemy action reduced twenty percent")
	check(b.skill_buttons[3].text.contains("대기 3턴"),"visible cooldown in slot")
	b.select_skill("josik_suwon");check(b.use_button.disabled,"cooldown explains but prevents use")
	b.use_selected();check(b.turn==2 and b.qi.amount==40 and not b.busy,"blocked use consumes no turn or resource")
	# A historical combat-file fixture verifies locked state without enabling new combat saves.
	game.duel_quest.phase="battle"
	game.progress.loadout=b.loadout.duplicate()
	check(not game.save_system.write_slot(9),"normal combat save remains forbidden")
	check(preload("res://tests/legacy_save_fixture.gd").write(game,1) and game.save_system.load_slot(1),"cooldown persists in compatible combat snapshot")
	check(b.turn==2 and b.cooldown_remaining("josik_suwon")==3 and b.qi.amount==40 and b.use_button.disabled,"reload cannot reset cooldown or restore again")
	var bad=game.save_system.capture();bad.battle.ready_turns.josik_suwon=99999
	check(not game.save_system.validate(bad),"invalid cooldown bound rejected")
	for t in [2,3,4]:
		check(b.cooldown_remaining("josik_suwon")==5-t,"waits for own turns")
		b.select_basic_attack();b.use_selected();await wait_turn()
	check(b.turn==5 and b.cooldown_remaining("josik_suwon")==0,"three alternate actions unlock skill")
	b.select_skill("josik_suwon");check(not b.use_button.disabled,"reusable turn five")
	# Defending enemy does not carry the support guard into the following attack.
	b.enemy_intent="basic_defense";hp=b.player_hp;b.use_selected();await wait_turn()
	check(b.player_hp==hp and b.cooldown_remaining("josik_suwon")==3,"recovery still works against enemy guard")
	b.select_basic_attack();b.use_selected();await wait_turn()
	# Reinitialize for fallback and new-fight checks, independent of current quest outcome.
	b.cancel();b.set_encounter(game.duel_quest.data.encounter);b.set_loadout(["josik_suwon","","",""]);b.begin()
	b.select_skill("josik_suwon");b.use_selected();await wait_turn()
	check(b.skill_buttons[0].text.contains("임시 기본공격"),"all other slots removed still offers fallback during cooldown")
	b.select_slot(0);check(b.selected_action=="basic_attack","fallback selectable")
	b.cancel();b.begin();check(b.ready_turns.is_empty() and b.qi.amount==10,"new battle resets cooldown and qi")
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_JOSIK_SUWON: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
