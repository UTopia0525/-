extends SceneTree
var game
var failed=false
const IDS=["hoeryu","paak","gwanak","banseok","jungun"]
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ALLIANCE ARTS: "+message)
func benchmark(model,stats: Dictionary,weapon: String,id: String,enemy: Dictionary) -> Dictionary:
	var qi=preload("res://scripts/inner_qi.gd").new();qi.start(int(stats.inner))
	var eq=preload("res://scripts/inner_qi.gd").new();eq.start(int(enemy.stats.inner))
	var hp=300;var foe=int(enemy.max_hp)
	for turn in range(1,81):
		var attack=model.action(id,stats,weapon)
		if attack.cost>qi.amount:attack=model.action("basic_attack",stats,weapon)
		var plan=model.enemy_plan(enemy.stats,enemy.weapon,enemy.skills,eq.amount,turn)
		var response=model.action(plan,enemy.stats,enemy.weapon)
		qi.spend(attack.cost);eq.spend(response.cost)
		foe-=model.damage(attack.raw,enemy.stats.constitution,enemy.weapon,response.guard)
		if foe<=0:return {"win":true,"hp":hp,"turns":turn}
		hp-=model.damage(response.raw,stats.constitution,weapon,attack.guard)
		if hp<=0:return {"win":false,"hp":0,"turns":turn}
		qi.recover_turn();eq.recover_turn()
	return {"win":false,"hp":hp,"turns":80}
func run() -> void:
	var model=preload("res://scripts/combat_actions.gd").new()
	var arts=model.arts
	var report=[]
	for level in [10,20,50,100]:
		var stats={"strength":level,"agility":level,"constitution":level,"inner":level,"insight":level}
		var row={"stat_each":level}
		for id in IDS:
			var skill=arts.get_skill(id);var weapon: String=model.weapons.DEFAULT_BY_TYPE[skill.required_weapon_type]
			var action=model.action(id,stats,weapon)
			row[id]={"raw":action.raw,"cost":action.cost,"guard":action.guard}
			check(arts.can_learn(id,stats),"no stat/realm restriction "+id)
			check(preload("res://scripts/catalog_icons.gd").texture(id)!=null,"dedicated icon "+id)
			for old in arts.definitions:
				if arts.get_skill(old).get("acquisition")!="city_instructor" or arts.get_skill(old).weapon_style!=skill.weapon_style:continue
				check(action.raw>model.action(old,stats,weapon).raw,"stronger than lower-tier "+old+" at "+str(level))
			for wrong in ["none","sword","saber","spear"]:
				check(arts.can_use_with_weapon(id,wrong)==(wrong==skill.required_weapon_type),"matching equipment still required "+id)
			var zero={"strength":0,"agility":0,"constitution":0,"inner":0,"insight":0}
			check(arts.can_learn(id,zero),"no hidden learning floor "+id)
		report.append(row)
	var early: Dictionary=report[1];var late: Dictionary=report[3]
	check(early.gwanak.raw>early.hoeryu.raw and early.gwanak.raw>early.paak.raw,"spear dominates early raw damage")
	for id in ["hoeryu","paak","banseok","jungun"]:check(late[id].raw>late.gwanak.raw,"higher coefficients overtake spear later "+id)
	check(int(early.hoeryu.guard)==20 and early.gwanak.cost<28,"sword guards and spear equipment reduces qi")
	var encounters=JSON.parse_string(FileAccess.get_file_as_string("res://data/changsha_bandit_story.json")).encounters
	for stats in [{"strength":10,"agility":10,"constitution":10,"inner":10,"insight":10},{"strength":10,"agility":10,"constitution":10,"inner":10,"insight":60},{"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}]:
		for id in IDS:
			for enemy in encounters:
				var weapon: String=model.weapons.DEFAULT_BY_TYPE[arts.get_skill(id).required_weapon_type]
				var result=benchmark(model,stats,weapon,id,enemy)
				check(result.win,"simple attack/basic-attack clears benchmark at "+str(stats)+" / "+id)
	var f=FileAccess.open("user://alliance_arts_balance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_city()
	var p=game.progress
	for id in IDS:
		check(id not in p.learned,"not auto-granted before story "+id)
		check(not p.issue("art",id,999999).is_empty(),"cannot buy story reward from ordinary shop "+id)
		p.learned.append(id) # isolated reward fixture; no runtime story is invented here
		check(p.assign(id,3),"assign learned art to K loadout "+id)
	game.player_menu.open_menu("martial");game.player_menu.select_item("hoeryu")
	check(game.player_menu.detail.get_parsed_text().contains("학습 조건 없음"),"K explains unrestricted learning")
	var buttons=game.player_menu.rows.get_children().filter(func(n):return n is Button)
	for id in IDS:check(buttons.any(func(n):return n.text.contains(arts.get_skill(id).name) and n.icon!=null),"K displays icon "+id)
	game.player_menu.close_menu()
	game.state="service";game.city_service.open_counter(game.exploration.city_data.services.filter(func(s):return s.kind=="training")[0])
	for button in game.city_service.rows.get_children():
		if button is Button:
			for id in IDS:check(not button.text.contains(arts.get_skill(id).name),"ordinary teacher does not sell alliance art "+id)
	game.city_service.close_counter()
	check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"learned story arts survive saves")
	for id in IDS:check(id in p.learned,"saved art survives "+id)
	game.start_battle()
	for id in IDS:
		var skill=arts.get_skill(id);game.battle.equip_weapon(skill.required_weapon_type)
		game.battle.qi.amount=500;game.battle.set_loadout(["basic_attack",id,"",""]);game.battle.select_skill(id)
		check(game.battle.skill_buttons[1].icon!=null and not game.battle.use_button.disabled,"battle icon and usable preview "+id)
		var qi=preload("res://scripts/inner_qi.gd").new();qi.start(10)
		var action=model.action(id,p.stats,model.weapons.DEFAULT_BY_TYPE[skill.required_weapon_type])
		for turn in range(4):
			if qi.amount>=action.cost:break
			qi.recover_turn()
		check(qi.spend(action.cost),"usable after banking starting inner qi "+id)
	game.reset();await create_timer(.3).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	if not failed:print("ALLIANCE ARTS PASS: five arts, no learning gates, equipment, scaling, icons, UI, story/shop separation, saves")
	print(JSON.stringify(report));quit(1 if failed else 0)
