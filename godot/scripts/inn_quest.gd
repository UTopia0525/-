extends Node
## Hear both accounts, then resolve through guaranteed mediation or nonlethal combat.
const ID="wuchang_inn_quarrel"
const GIVER="wc_du_sanniang"
const WORKER="inn_worker"
const WARRIOR="inn_warrior"
const UI=preload("res://scripts/ui.gd")
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_inn_quest.json"))
var phase:="available"
var heard: Array=[]
var branch:=""
var defeats:=0
var nodes: Array[Node]=[]
var signature:=""

func _ready() -> void:
	game.PORTRAITS.ACTORS[WORKER]={"name":"양복","basic_portrait":"male_common_a"}
	game.PORTRAITS.ACTORS[WARRIOR]={"name":"장만길","basic_portrait":"male_common_b"}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"offer":{"label":"객잔 주인 도삼랑에게 시비 중재 의뢰 묻기","goals":[]},
		"listen":{"label":"객잔 앞 양복과 장만길에게 각각 사정 듣기","goals":[]},
		"resolve":{"label":"장만길에게 말을 걸어 중재 또는 비무 선택","goals":[]},
		"report":{"label":"도삼랑에게 해결 결과 보고","goals":[]}}}
func reset() -> void:
	clear_world();phase="available";heard.clear();branch="";defeats=0;signature=""
func status() -> String:return "active" if phase in ["listening","deciding","battle"] else phase
func stage() -> String:return "offer" if phase=="available" else "listen" if phase=="listening" else "resolve" if phase in ["deciding","battle"] else "report"
func marker_for(id: String) -> String:
	return ("!" if phase=="available" else "?" if phase=="ready" else "") if id==GIVER else ""
func is_target(id: String) -> bool:
	return id in [WORKER,WARRIOR] and (id not in heard if phase=="listening" else phase=="deciding")
func reward_label() -> String:return "보수 %d문" % int(data.reward.money)
func track() -> void:game.quest_navigation.track(ID,stage())
func in_battle() -> bool:return phase=="battle"

func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="wuchang":return false
	if id==GIVER:
		match phase:
			"available":game.say(data.scenes.intro,_offer)
			"listening":game.say(data.scenes.progress)
			"deciding":choose_resolution()
			"ready":game.say(data.scenes.report,_complete)
			"completed":game.say(data.scenes.post)
		return true
	if id not in [WORKER,WARRIOR]:return false
	match phase:
		"listening":
			if id in heard:game.say(data.scenes.worker_wait if id==WORKER else data.scenes.warrior_wait)
			elif id==WORKER:game.say(data.scenes.worker,_worker_done)
			else:game.say(data.scenes.warrior,_warrior_done)
		"deciding":choose_resolution()
		"ready":game.say(data.scenes.resolved)
		_:return false
	return true
func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title),"보수 150문 · 대화 또는 선택 비무\n두 손님의 사정을 듣고 시비를 해결한 뒤 보고하세요.","양쪽 말을 들어보겠습니다",accept,"지금은 다른 일이 있습니다",decline)
func accept() -> void:
	if phase!="available":return
	phase="listening";track();refresh_world()
	game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _worker_done() -> void:_heard(WORKER)
func _warrior_done() -> void:_heard(WARRIOR)
func _heard(id: String) -> void:
	if phase!="listening" or id in heard:return
	heard.append(id)
	if heard.size()==2:phase="deciding"
	track();refresh_world()
	game.adventure_ui.notify("양쪽 사정을 들었다 · 해결 방식 선택" if phase=="deciding" else "다른 손님의 사정도 듣기","quest")
	if phase=="deciding":choose_resolution()
func choose_resolution() -> void:
	if phase!="deciding" or heard.size()!=2:return
	var text: String="말로 중재하거나 객잔 옆 빈 마당에서 비무할 수 있습니다. 두 경로의 보수는 150문으로 같습니다."
	if defeats>0:text="비무에서 물러났습니다. 중재로 해결하거나 정비 후 다시 겨룰 수 있습니다. 보수는 같습니다."
	game.adventure_ui.choose("객잔 앞 · 어떻게 해결할까",text,"두 사람 모두 사과할 일이 있소",mediate,"나와 손을 맞추시겠소",challenge)
func mediate() -> void:
	if phase!="deciding" or heard.size()!=2:return
	game.say(data.scenes.mediate,_talk_done)
func _talk_done() -> void:
	if phase!="deciding":return
	branch="talk";phase="ready";_resolved()
func challenge() -> void:
	if phase!="deciding" or heard.size()!=2:return
	game.say(data.scenes.challenge,_start_battle)
func _start_battle() -> void:
	if phase!="deciding":return
	phase="battle";branch="duel"
	game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point(data.duel_point))
	game.exploration.player.stop();game.exploration.camera.snap_to_player()
	game.start_battle(data.encounter)
func _return_to_map() -> void:
	game.battle.hide();game.state="explore";game.exploration.show()
	game.exploration.camera.enabled=true;game.exploration.camera.snap_to_player()
	game.top_hud.show();game.bottom_hint.text=UI.EXPLORATION_HINT;game.bottom_hint.show();game.music.play_track("dock")
func after_victory() -> void:
	if phase!="battle":return
	phase="ready";_return_to_map();game.say(data.scenes.victory,_resolved)
func after_defeat() -> void:
	if phase!="battle":return
	defeats+=1;phase="deciding";branch=""
	_return_to_map();game.say(data.scenes.defeat,_after_retreat)
func _after_retreat() -> void:
	track();refresh_world();game.adventure_ui.notify("정비 후 재도전 또는 말로 중재할 수 있습니다.","quest")
func _resolved() -> void:
	track();refresh_world();game.adventure_ui.notify("시비 해결 · 도삼랑에게 보고","quest")
func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=int(data.reward.money)
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · %d문" % int(data.reward.money),"quest")

func goal(world) -> Dictionary:
	var point: Vector2
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		var targets: Array=[WORKER,WARRIOR].filter(func(id):return id not in heard) if phase=="listening" else [WARRIOR] if phase in ["deciding","battle"] else [GIVER]
		var distance:=INF
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id") not in targets:continue
			var d: float=world.player.position.distance_squared_to(npc.position)
			if d<distance:distance=d;point=npc.position
	elif world.area_name=="mountain_road":point=world.city_point([740,64]);label="산길 북쪽 출입구로 무창에 이동"
	elif world.area_name=="changsha":point=world.city_point([1490,510]);label="동쪽 농촌에서 무창 방면 산길로 이동"
	elif world.area_name=="alliance_office":point=world.city_point([256,321]);label="총무당을 나와 객잔으로 이동"
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func clear_world() -> void:
	for node in nodes:
		if not is_instance_valid(node):continue
		if node is Node2D:game.exploration.ambient_nodes.erase(node)
		node.free()
	nodes.clear()
func _navigation() -> void:
	var world=game.exploration
	if not is_instance_valid(world.regional_map):return
	world.regional_map.resident_positions.assign(world.ambient_nodes.map(func(n):return n.position))
	world.regional_map._build_navigation();world.astar=world.regional_map.astar
func _actor(id: String,point: Array,frame: int,role: String) -> void:
	var world=game.exploration
	world._populate_residents([{"id":id,"name":game.PORTRAITS.ACTORS[id].name,"point":point,"frame":frame,"quest_actor":true,"post":"객잔 앞 평상","district":"inns","character_profile":{},"role":role}])
	var node=world.ambient_nodes.back();nodes.append(node)
	var tag=world.occlusion_roots.pop_back();tag.reparent(node);tag.position=Vector2.ZERO
func refresh_world() -> void:
	var w=game.exploration;var next_signature="%d:%s:%s" % [w.load_revision,w.area_name,phase]
	if signature==next_signature:return
	signature=next_signature;clear_world();_navigation()
	if w.area_name!="wuchang":return
	for npc in w.ambient_nodes:
		if npc.get_meta("npc_id")!=GIVER:continue
		var marker=UI.label(npc,marker_for(GIVER),Rect2(-20,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP,40,46),34,Color("ffe14b"))
		marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.visible=not marker.text.is_empty()
		marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5);nodes.append(marker)
	if phase in ["listening","deciding","battle","ready"]:
		_actor(WORKER,data.worker_point,6,"하역 일꾼")
		_actor(WARRIOR,data.warrior_point,7,"떠돌이 무인")
	_navigation()
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase,"heard":heard.duplicate(),"branch":branch,"defeats":defeats}
func valid(value) -> bool:
	if not value is Dictionary or value.get("phase") not in ["available","listening","deciding","battle","ready","completed"]:return false
	if not value.get("heard") is Array or not game.progress.whole(value.get("defeats"),0,1000000):return false
	for id in value.heard:
		if id not in [WORKER,WARRIOR] or value.heard.count(id)!=1:return false
	if value.phase=="available":return value.heard.is_empty() and value.get("branch")=="" and value.defeats==0
	if value.phase=="listening":return value.heard.size()<2 and value.get("branch")=="" and value.defeats==0
	if value.heard.size()!=2:return false
	if value.phase=="deciding":return value.get("branch")==""
	if value.phase=="battle":return value.get("branch")=="duel"
	return value.get("branch") in ["talk","duel"]
func restore(value: Dictionary) -> void:
	phase=value.get("phase","available");heard=value.get("heard",[]).duplicate();branch=value.get("branch","");defeats=int(value.get("defeats",0));signature="";refresh_world()
