extends SceneTree
var game
var failed=false
const Outcomes=preload("res://scripts/combat_outcome.gd")
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("DEATH_FLOW: "+message)
func press(code: int) -> void:
	for down in [true,false]:
		var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await process_frame
func wait_for_screen() -> void:
	var deadline=Time.get_ticks_msec()+4000
	while not game.death_screen.ready_to_return and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
	check(game.death_screen.ready_to_return,"death screen becomes confirmable after fall")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"])
	check(Outcomes.defeat_policy({"id":"future_main_boss"})=="death","future encounter defaults to lethal")
	check(Outcomes.defeat_policy({"id":"future_main_boss","defeat_outcome":"typo"})=="death","unknown policy cannot silently grant retries")
	check(Outcomes.defeat_policy({})=="retry","tutorial/practice remains explicit empty-encounter exception")
	for e in game.encounters():
		check(Outcomes.defeat_policy(e)==("death" if e.id in ["qingya_chief","qingya_sentry","nanjing_nochil"] else "nonlethal" if e.id in ["training_student","inn_warrior"] else "retry"),"existing encounter policy: "+e.id)
	game.start_wuchang();game.money=321
	var q=game.qingya_quest
	q.phase="decision";q.heard=q.INVESTIGATORS.keys();q.admitted=true;q.captive_heard=true
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"qingya_camp","arrival":[768,600]}})
	check(game.save_system.write_slot(1),"manual pre-battle save exists")
	var path=game.save_system.path(1);var original=FileAccess.get_file_as_string(path)
	for index in [0]:
		q.phase="fight_chief"
		game.start_battle(q.data.encounters[0])
		game.battle.player_hp=1
		game.battle.select_skill("basic_defense");game.battle.use_selected()
		var deadline=Time.get_ticks_msec()+8000
		while game.state=="battle" and Time.get_ticks_msec()<deadline:await create_timer(.03).timeout
		check(game.state=="game_over" and game.battle.player_hp==0,"actual enemy attack causes lethal loss: "+str(index))
		check(not game.battle.running and game.death_screen.visible,"combat ends and death overlay starts")
		check(not game.exploration.active and not game.exploration.visible and game.dialogue_lines.is_empty(),"death does not resume village exploration or retry dialogue")
		check(q.phase in ["fight_chief","fight_sentry"] and q.branch=="" and game.money==321,"no quest outcome/reward on death")
		check(not game.adventure_ui.window.visible,"automatic result log does not cover death screen")
		var count=game.adventure_ui.results.size();game._on_defeat();game._on_victory(1)
		check(game.state=="game_over" and not game.adventure_ui.window.visible and game.adventure_ui.results.size()==count,"late/duplicate combat signals cannot revive or cover death")
		check(not game.save_system.write_slot(2) and not game.save_system.blocked_reason().is_empty(),"dead progress cannot be saved")
		for key in [KEY_I,KEY_K,KEY_Q,KEY_R,KEY_L,KEY_ESCAPE,KEY_F2,KEY_W,KEY_F]:await press(key)
		check(game.state=="game_over" and not game.settings_menu.window.visible and not game.adventure_ui.window.visible and not game.player_menu.visible,"menus and premature F cannot bypass death")
		game.battle.use_selected();check(not game.battle.running,"dead combat cannot restart")
		await wait_for_screen()
		check(absf(game.battle.player_actor.rotation)>1,"hero visibly falls before ending")
		check(not game.settings_menu.gear.visible,"settings button hidden during death")
		if index==0:await press(KEY_F)
		else:game.death_screen.return_button.pressed.emit();await process_frame
		check(game.state=="title" and game.title_screen.visible and not game.death_screen.visible,"F/button returns to original title")
		check(game.battle.player_hp==300 and game.battle.player_actor.rotation==0,"new session clears death presentation")
		check(game.qingya_quest.phase=="available" and not game.exploration.active,"runtime cleared without automatic retry")
		check(FileAccess.get_file_as_string(path)==original,"manual save remains unchanged")
	check(game.save_system.load_slot(1),"can reload pre-infiltration save from title")
	game.reset()
	# Nonlethal loss still advances the training quest instead of killing the hero.
	game.start_wuchang();game.duel_quest.phase="battle";game.start_battle(game.duel_quest.data.encounter);game.battle.player_hp=0;game._on_defeat()
	check(game.state=="explore" and game.duel_quest.phase=="ready" and not game.death_screen.visible,"training duel retains nonlethal report path")
	game.reset()
	# Legacy retry campaign still withdraws, while a new major enemy needs no opt-in flag.
	game.start_city();game.bandit_story.stage="battle_one";game.start_battle(game.bandit_story.data.encounters[0]);game.battle.player_hp=0;game._on_defeat()
	check(game.state=="story" and not game.death_screen.visible,"pre-existing campaign withdrawal retained")
	game.reset();var new_enemy=game.qingya_quest.data.encounters[0].duplicate(true);new_enemy.erase("defeat_outcome")
	game.start_battle(new_enemy);game.battle.player_hp=0;game._on_defeat()
	check(game.state=="game_over","unannotated future story fight uses shared death handler")
	game.reset();await create_timer(1.8).timeout
	check(game.state=="title" and not game.death_screen.visible,"reset cancels pending death reveal")
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	print("GODOT_DEATH_FLOW: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
