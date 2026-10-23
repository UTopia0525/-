extends SceneTree
var game
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	if not ok:
		failed=true
		push_error("SPEAR_UI: "+text)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city()
	game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
	game.progress.learned.append_array(["gwanpung","yeonhwan"])
	game.progress.owned_weapons.append("balanced_spear")
	game.progress.loadout=["basic_attack","basic_defense","gwanpung","yeonhwan"]
	game.battle.equip_weapon_item("balanced_spear")
	game.player_menu.open_menu("martial");game.player_menu.select_item("gwanpung")
	check(game.player_menu.detail.text.contains("120 +") and game.player_menu.detail.text.contains("소모17"),"K shows fixed power and equipment-adjusted cost")
	game.player_menu.close_menu()
	for definition in game.exploration.city_data.services:
		if definition.id=="city_instructor":
			game.state="service";game.city_service.open_counter(definition)
	game.city_service.select_item("yeonhwan")
	check(game.city_service.message.text.contains("160 +") and game.city_service.message.text.contains("소모28"),"instructor explains base power and original skill cost")
	game.city_service.dismiss()
	game.start_battle(game.bandit_story.data.encounters[1])
	var b=game.battle
	b.select_skill("yeonhwan")
	check(b.detail.text.contains("160 +") and b.detail.text.contains("280.0"),"battle preview includes fixed power")
	check(b.note.text.contains("26"),"battle preview shows discounted qi cost")
	b.use_selected()
	check(not b.busy and b.enemy_hp==240 and b.qi.amount==20 and b.turn==1,"costly burst cannot bypass resource rules")
	b.select_skill("gwanpung")
	b.use_selected()
	var deadline:=Time.get_ticks_msec()+7000
	while b.busy and Time.get_ticks_msec()<deadline: await create_timer(.04).timeout
	check(b.enemy_hp==45 and b.qi.amount==23 and b.turn==2,"actual battle deals195 and spends17 before normal recovery")
	game.reset();await create_timer(1.0).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_SPEAR_UI: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
