extends Node
## Independent Wuchang rescue. Only a completed clue dialogue unlocks event actors.
const ID = "wuchang_missing_herbalist"
const GIVER = "wc_liu_baicao"
const CLUE = "quest_goal:wuchang_missing_herbalist:clue"
const UI = preload("res://scripts/ui.gd")
var game
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_herbalist_quest.json"))
var phase := "available"
var battle_active := false
var nodes: Array[Node] = []
var signature := ""

func _ready() -> void:
	game.PORTRAITS.ACTORS.herb_gatherer = {"name":"임소평", "basic_portrait":"male_young"}
	game.PORTRAITS.ACTORS.herb_ruffian = {"name":"구칠", "basic_portrait":"male_common_a"}
	game.quest_navigation.definitions[ID] = {"title":data.title,"stages":{
		"offer":{"label":"무창 상점가의 유백초에게 일거리 묻기","goals":[]},
		"search":{"label":"남쪽 산길 첫 굽이의 약초 꾸러미 조사","goals":[]},
		"rescue":{"label":"흔적 너머의 약초꾼을 찾아 구하기","goals":[]},
		"report":{"label":"무창 약재상 유백초에게 귀환 보고","goals":[]}}}

func reset() -> void:
	clear_world();phase="available";battle_active=false;signature=""

func status() -> String:
	return "active" if phase in ["search","rescue"] else phase

func stage() -> String:
	return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)

func marker_for(id: String) -> String:
	if id != GIVER:return ""
	return "?" if phase=="ready" else "!" if phase=="available" else ""

func track() -> void:
	game.quest_navigation.track(ID,stage())

func handle_interaction(id: String) -> bool:
	if id==GIVER and game.exploration.area_name=="wuchang":
		game.adventure_ui.choose("유백초 · 약재상", "약초꾼의 소식과 약재 거래 중 용건을 고르세요.",
			"약초꾼 이야기",talk_giver,"약재를 살펴본다",trade)
		return true
	if id=="herb_gatherer" and phase=="ready" and game.exploration.area_name=="wuchang":
		game.say([["herb_gatherer","소협 덕분에 무사히 돌아왔습니다. 유백초 어른께서 소협을 기다리고 계십니다."]]);return true
	if id==CLUE and phase=="search" and game.exploration.area_name=="mountain_road":
		game.say(data.scenes.clue,_clue_done)
		return true
	if id in ["herb_gatherer","herb_ruffian"] and phase=="rescue" and game.exploration.area_name=="mountain_road":
		game.say(data.scenes.confront,_start_battle)
		return true
	return false

func talk_giver() -> void:
	match phase:
		"available":game.say(data.scenes.intro,_offer)
		"ready":game.say(data.scenes.report,_complete)
		"completed":game.say(data.scenes.post)
		_:game.say(data.scenes.progress)

func trade() -> void:
	game.pending_service_id="city_merchant"
	game.say(data.scenes.trade,game._service_done)

func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title), reward_label()+"\n남쪽 산길에서 약초꾼의 흔적을 찾아 주세요.",
		"제가 찾아보겠습니다",accept,"지금은 다른 일이 있습니다",decline)

func accept() -> void:
	if phase!="available":return
	phase="search";track();refresh_world()
	game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest")
	game.say(data.scenes.accept)

func decline() -> void:game.say(data.scenes.decline)

func _clue_done() -> void:
	if phase!="search":return
	phase="rescue";track();refresh_world()
	game.adventure_ui.notify("약초꾼의 흔적을 찾았다 · 다음 굽이 살피기","quest")

func _start_battle() -> void:
	if phase!="rescue":return
	battle_active=true;game.start_battle(data.encounter)

func in_battle() -> bool:return battle_active

func _return_to_map() -> void:
	battle_active=false;game.battle.hide();game.state="explore"
	game.exploration.show();game.exploration.camera.enabled=true
	game.exploration.camera.snap_to_player();game.top_hud.show()
	game.bottom_hint.text=UI.EXPLORATION_HINT;game.bottom_hint.show()
	game.music.play_track("voyage")

func after_victory() -> void:
	_return_to_map()
	game.say(data.scenes.victory,_rescued_dialogue)

func _rescued_dialogue() -> void:
	# Gu Chil has fled; he does not remain in the following conversation or map.
	_remove_actor("herb_ruffian")
	game.say(data.scenes.rescued,_rescue_done)

func _rescue_done() -> void:
	phase="ready";track();refresh_world()
	game.adventure_ui.notify("임소평이 무창으로 돌아갔다 · 유백초에게 보고","quest")

func after_defeat() -> void:
	_return_to_map()
	# Retreat to the clue, without clearing the investigation or inventing a death timer.
	game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point(data.clue_point)+Vector2(0,-64))
	game.exploration.player.stop();game.exploration.camera.snap_to_player()
	game.say(data.scenes.defeat)

func reward_label() -> String:
	if not data.has("reward"):return "보수는 아직 미정입니다."
	return "보수 %d문" % data.reward.money

func _complete() -> void:
	if phase!="ready" or not data.has("reward"):return
	game.money+=int(data.reward.money)
	phase="completed"
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world()
	game.adventure_ui.notify("의뢰 완료 · %d문" % data.reward.money,"quest")

func goal(world) -> Dictionary:
	var point: Vector2
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		if phase in ["search","rescue"]:
			point=world.city_point([1100,1840]);label="남쪽 농촌 끝에서 산길로 나가기"
		else:
			for npc in world.ambient_nodes:
				if npc.get_meta("npc_id")==GIVER:point=npc.position
	elif world.area_name=="mountain_road":
		if phase in ["available","ready","completed"]:
			point=world.city_point([740,64]);label="북쪽 출입구로 무창에 돌아가기"
		else:
			var wanted: String=CLUE if phase=="search" else "herb_gatherer"
			for entry in world.objectives:
				if entry.id==wanted:point=entry.position
	elif world.area_name=="changsha":
		point=world.city_point([1490,510]);label="동쪽 농촌에서 무창 방면 산길로 이동"
	elif world.area_name=="alliance_office":
		point=world.city_point([256,321]);label="총무당을 나와 무창으로 이동"
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}

func _remove_actor(id: String) -> void:
	var world=game.exploration
	for node in nodes.duplicate():
		if not is_instance_valid(node):continue
		if node.get_meta("npc_id","")!=id:continue
		world.ambient_nodes.erase(node);nodes.erase(node);node.free()
	world.objectives=world.objectives.filter(func(e):return e.id!=id)
	_rebuild_navigation()

func clear_world() -> void:
	var world=game.exploration
	world.objectives=world.objectives.filter(func(e):return e.id not in [CLUE,"herb_gatherer","herb_ruffian"])
	for node in nodes:
		if is_instance_valid(node):
			if node is Node2D:world.ambient_nodes.erase(node)
			node.free()
	nodes.clear()

func _rebuild_navigation() -> void:
	var world=game.exploration
	if not is_instance_valid(world.regional_map):return
	world.regional_map.resident_positions.assign(world.ambient_nodes.map(func(n):return n.position))
	world.regional_map._build_navigation();world.astar=world.regional_map.astar

func _actor(id: String, point: Array, frame: int) -> void:
	var world=game.exploration
	var entry={"id":id,"name":game.PORTRAITS.ACTORS[id].name,"point":point,"frame":frame,"quest_actor":true,"post":"약초꾼 구출","allow_road_post":world.area_name=="mountain_road","character_profile":{},"role":"약초꾼" if id=="herb_gatherer" else "불한당"}
	# Use the common full-body placement and foot collision checks, including other actors.
	world._populate_residents([entry])
	var node=world.ambient_nodes.back();nodes.append(node)
	# Common name tags are independent Y-sorted nodes; own them for stage cleanup.
	var tag=world.occlusion_roots.pop_back();tag.reparent(node);tag.position=Vector2.ZERO
	world.objectives.append({"id":id,"goal_id":id,"name":entry.name,"position":node.position,"node":node,"frame":frame,"important":true})

func refresh_world() -> void:
	var world=game.exploration
	var next_signature="%d:%s:%s" % [world.load_revision,world.area_name,phase]
	if signature==next_signature:return
	signature=next_signature;clear_world();_rebuild_navigation()
	if world.area_name=="wuchang":
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id")==GIVER:
				var mark=UI.label(npc,marker_for(GIVER),Rect2(-20,-world.Metrics.CITIZEN_HEIGHT-world.Metrics.QUEST_GAP-world.Metrics.NAME_GAP,40,46),34,Color("ffe14b"))
				mark.add_theme_color_override("font_outline_color",Color("2b2614"));mark.add_theme_constant_override("outline_size",5)
				mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;nodes.append(mark)
		if phase=="ready":_actor("herb_gatherer",[805,1190],7)
	elif world.area_name=="mountain_road":
		if phase=="search":
			var node=preload("res://scripts/herb_bundle.gd").new()
			node.position=world.safe_player_position(world.city_point(data.clue_point))
			world.decorations.add_child(node);nodes.append(node)
			world.objectives.append({"id":CLUE,"goal_id":"clue","name":"떨어진 약초 꾸러미","position":node.position,"node":node,"frame":-1,"important":true})
		elif phase=="rescue":
			world.city_data.road_centers=[]
			_actor("herb_gatherer",[740,325],7)
			_actor("herb_ruffian",[780,325],6)
	_rebuild_navigation()

func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in ["available","search","rescue","ready","completed"]
func restore(value: Dictionary) -> void:
	phase=value.get("phase","available");battle_active=false;signature="";refresh_world()
