extends Node
## Nonlethal training: either result enables report, report teaches one universal art.
const ID="wuchang_training_duel"
const GIVER="wc_lin_zhengshan"
const STUDENT="training_student"
const UI=preload("res://scripts/ui.gd")
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_duel_quest.json"))
var phase:="available"
var result:=""
var signature:=""
var nodes: Array[Node]=[]

func _ready() -> void:
	game.PORTRAITS.ACTORS[STUDENT]={"name":"유소강","basic_portrait":"male_common_b"}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"offer":{"label":"무관 교관 임정산에게 대련 의뢰 묻기","goals":[]},
		"duel":{"label":"무관 연무장의 유소강과 대련","goals":[]},
		"report":{"label":"임정산에게 보고하고 조식수원공 전수받기","goals":[]}}}

func reset() -> void:clear_world();phase="available";result="";signature=""
func status() -> String:return "active" if phase in ["accepted","battle"] else phase
func stage() -> String:return "offer" if phase=="available" else "duel" if phase in ["accepted","battle"] else "report"
func marker_for(id: String) -> String:
	return ("!" if phase=="available" else "?" if phase=="ready" else "") if id==GIVER else ""
func is_target(id: String) -> bool:return id==STUDENT if phase=="accepted" else id==GIVER if phase=="ready" else false
func reward_label() -> String:return "조식수원공 전수"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func in_battle() -> bool:return phase=="battle"

func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="wuchang":return false
	if id==GIVER:
		game.adventure_ui.choose("임정산 · 무관 교관","대련 의뢰와 무공 거래 중 용건을 고르세요.","세 걸음의 대련",talk_giver,"무공을 살펴본다",trade)
		return true
	if id==STUDENT and phase in ["accepted","ready"]:
		game.say(data.scenes.before,_prepare) if phase=="accepted" else game.say(data.scenes.waiting)
		return true
	return false

func talk_giver() -> void:
	match phase:
		"available":game.say(data.scenes.intro,_offer)
		"accepted":game.say(data.scenes.progress)
		"ready":
			var first: String="덕분에 소강이가 제 버릇을 똑똑히 보았소. 상대해 주어 고맙소." if result=="win" else "끝까지 성실하게 상대해 주었소. 소강이에게도 배울 것이 많은 대련이었지."
			game.say([[GIVER,first]]+data.scenes.report,_complete)
		"completed":game.say(data.scenes.post)

func trade() -> void:
	game.pending_service_id="city_instructor";game.say(data.scenes.trade,game._service_done)
func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title),"보수: 조식수원공 전수\n연무장에서 대련을 마치고 보고하세요. 승패와 관계없이 전수합니다.","한 차례 겨뤄 보겠습니다",accept,"다음에 시간을 내겠습니다",decline)
func accept() -> void:
	if phase!="available":return
	phase="accepted";track();refresh_world()
	game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _prepare() -> void:
	if phase!="accepted":return
	game.adventure_ui.choose("연무장 · 대련 준비","병장기와 초식을 정비한 뒤 시작할 수 있습니다.","시작하세",_start_battle,"잠시 준비하고 오겠네",_later)
func _later() -> void:game.say(data.scenes.later)
func _start_battle() -> void:
	if phase!="accepted":return
	phase="battle";game.start_battle(data.encounter)
func after_victory() -> void:_ended("win")
func after_defeat() -> void:_ended("loss")
func _ended(outcome: String) -> void:
	phase="ready";result=outcome
	game.battle.hide();game.state="explore";game.exploration.show()
	game.exploration.camera.enabled=true;game.exploration.camera.snap_to_player()
	game.top_hud.show();game.bottom_hint.text=UI.EXPLORATION_HINT;game.bottom_hint.show()
	game.music.play_track("dock")
	game.say(data.scenes.after_win if outcome=="win" else data.scenes.after_loss,_after_duel)
func _after_duel() -> void:
	track();refresh_world();game.adventure_ui.notify("대련 종료 · 임정산에게 보고","quest")
func _complete() -> void:
	if phase!="ready":return
	phase="completed"
	if data.reward.art not in game.progress.learned:game.progress.learned.append(data.reward.art)
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("조식수원공을 익혔다 · K에서 편성하세요.","learn")

func goal(world) -> Dictionary:
	var point: Vector2
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		var id: String=STUDENT if phase in ["accepted","battle"] else GIVER
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id")==id:point=npc.position;break
	elif world.area_name=="mountain_road":point=world.city_point([740,64]);label="산길 북쪽 출입구로 무창에 이동"
	elif world.area_name=="changsha":point=world.city_point([1490,510]);label="동쪽 농촌에서 무창 방면 산길로 이동"
	elif world.area_name=="alliance_office":point=world.city_point([256,321]);label="총무당을 나와 무관으로 이동"
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
func refresh_world() -> void:
	var world=game.exploration;var next_signature="%d:%s:%s" % [world.load_revision,world.area_name,phase]
	if signature==next_signature:return
	signature=next_signature;clear_world();_navigation()
	if world.area_name!="wuchang":return
	for npc in world.ambient_nodes:
		if npc.get_meta("npc_id")!=GIVER:continue
		var marker=UI.label(npc,marker_for(GIVER),Rect2(-40,-world.Metrics.CITIZEN_HEIGHT-world.Metrics.QUEST_GAP-world.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"))
		marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.visible=not marker.text.is_empty()
		marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5);nodes.append(marker)
	if phase not in ["accepted","battle","ready"]:return
	var entry={"id":STUDENT,"name":"유소강","point":data.student_point,"frame":7,"quest_actor":true,"post":"연무장","district":"martial","character_profile":{},"role":"무관 제자"}
	world._populate_residents([entry]);var npc=world.ambient_nodes.back();nodes.append(npc)
	var tag=world.occlusion_roots.pop_back();tag.reparent(npc);tag.position=Vector2.ZERO
	_navigation()
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase,"result":result}
func valid(value) -> bool:
	if not value is Dictionary or value.get("phase") not in ["available","accepted","battle","ready","completed"]:return false
	return value.get("result")=="" if value.phase in ["available","accepted","battle"] else value.get("result") in ["win","loss"]
func restore(value: Dictionary) -> void:
	phase=value.get("phase","available");result=value.get("result","");signature="";refresh_world()
