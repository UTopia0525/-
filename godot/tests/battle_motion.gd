extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.
var game
var failed := false
var sounds: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	if not ok:
		failed = true
		push_error("BATTLE_MOTION: "+text)
func wait_turn() -> void:
	var deadline := Time.get_ticks_msec()+7000
	while game.battle.busy and Time.get_ticks_msec()<deadline: await create_timer(.03).timeout
	check(not game.battle.busy,"exchange completes once")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_battle()
	var b = game.battle
	b.sound_requested.connect(func(id: String): sounds.append(id))
	for id in ["attack_sword","attack_saber","attack_spear","attack_none","hit","block"]:
		check(game.options.SFX[id].get_length()>0,"playable sound: "+id)
	game.options.update("sfx",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"combat effects obey mute")
	game.options.update("sfx",65)
	check(b.scene_image.texture.resource_path.ends_with("deck-empty.png"),"deck has no baked fighters")
	for type in ["sword","saber","spear","none"]:
		check(b.equip_weapon(type),"equip weapon category: "+type)
		check(b.player_actor.weapon_type==type and b.player_actor.frame_index==b.player_actor.COLUMNS[type],"equipped type selects correct silhouette")
		b.player_actor.attack()
		check(b.player_actor.pose=="windup","player attack starts in preparation pose")
		await create_timer(.2).timeout
		check(b.player_actor.pose=="strike" and b.player_actor.position!=b.player_actor.home,"attack advances to strike and moves forward")
		await create_timer(.55).timeout
		check(b.player_actor.pose=="ready" and b.player_actor.position.is_equal_approx(b.player_actor.home),"attack returns to idle")
	check(sounds.is_empty(),"preview animations never leak combat sounds")
	b.equip_weapon("sword")
	b.select_samjae();b.use_selected();b.use_selected()
	check(sounds.is_empty(),"windup does not play impact early")
	check(b.busy and b.player_actor.pose=="windup","actual action starts player motion and prevents duplicates")
	await create_timer(.48).timeout
	check(sounds==["attack_sword","hit"],"player swing then one enemy impact")
	check(b.enemy_actor.pose=="hit" and b.damage_label.visible and b.damage_label.text=="−42","actual hit drives enemy recoil and floating damage")
	check(b.damage_label.get_theme_color("font_color").r>b.damage_label.get_theme_color("font_color").g,"damage numbers are red")
	check(b.enemy_bar.value==108 and b.enemy_bar.trail.value>108,"HP commits immediately while old health remains visible")
	check(game.options.voices.any(func(v): return v.stream==game.options.SFX.hit),"impact reaches shared audio player")
	var hp_before: int = b.enemy_hp
	await create_timer(.7).timeout
	check(b.enemy_actor.pose=="windup" or b.enemy_actor.pose=="strike","enemy plays its own attack")
	await create_timer(.42).timeout
	check(b.player_actor.pose=="hit" and b.player_hp==286,"enemy hit drives player recoil with unchanged damage")
	await wait_turn()
	check(sounds==["attack_sword","hit","attack_saber","hit"],"enemy swing then one player impact")
	check(b.enemy_hp==hp_before and b.enemy_bar.trail.value==b.enemy_hp and b.player_bar.trail.value==b.player_hp,"trails settle without changing combat numbers")
	# Rapid damage retargets the same trailing segment; healing/load snap rather than replay loss.
	b.player_bar.set_health(250,300,false)
	b.player_bar.set_health(200,300,true)
	await create_timer(.05).timeout
	b.player_bar.set_health(150,300,true)
	check(b.player_bar.trail.value==250 and b.player_bar.current.value==150,"rapid losses preserve the entire recent damage segment")
	b.player_bar.set_health(300,300,false)
	check(b.player_bar.trail.value==300 and b.player_bar.value==300,"reset immediately clears delayed loss")
	await create_timer(.65).timeout
	check(b.player_bar.trail.value==300,"cancelled bar tween cannot damage reset display")
	b.player_actor.attack();b.player_bar.set_health(200,300,true)
	await create_timer(.05).timeout
	game.settings_menu.open_menu()
	var paused_position: Vector2 = b.player_actor.position
	var paused_trail: float = b.player_bar.trail.value
	await create_timer(.4).timeout
	check(b.player_actor.position.is_equal_approx(paused_position) and b.player_bar.trail.value==paused_trail,"settings pauses both motion and delayed health together")
	game.settings_menu.close_menu();b.player_actor.reset_motion();b._update_hp()
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1) and game.save_system.load_slot(1),"new visuals preserve manual saves")
	check(b.enemy_bar.trail.value==b.enemy_hp and b.player_bar.trail.value==b.player_hp and b.player_actor.pose=="ready","load snaps bars and poses to stored state")
	b.select_samjae();b.use_selected()
	game.reset();await create_timer(.8).timeout
	check(game.state=="title" and not b.visible and b.player_actor.pose=="ready" and b.enemy_actor.pose=="ready" and not b.damage_label.visible,"reset cancels motions, floating numbers and stale attack timers")
	game.start_battle(game.bandit_story.data.encounters[1])
	check(b.scene_image.texture.resource_path.ends_with("road-empty.png") and b.enemy_actor.weapon_type=="saber","campaign uses separate empty stage and matching enemy weapon")
	b.enemy_hp=1;b.select_samjae();b.use_selected();await wait_turn()
	check(b.enemy_hp==0 and b.enemy_bar.trail.value==0,"lethal hit drains its full damage segment before victory")
	game.reset();await create_timer(1).timeout
	for voice in game.music.players: voice.stop();voice.stream=null
	for voice in game.options.voices: voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_BATTLE_MOTION: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
