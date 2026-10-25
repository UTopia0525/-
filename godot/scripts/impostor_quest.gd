extends Node
## A post-teaching investigation with separate official pay and alliance gratitude.
const ID="wuchang_borrowed_alliance_name"
const GIVER="wc_lu_zhenghao"
const WITNESS="wc_wu_deshu"
const SUSPECT="impostor_ma"
const MESSENGER="song_jigyeom"
const UI=preload("res://scripts/ui.gd")
const PHASES=["available","witness","verify","confront","battle","ready","thanks","completed"]
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_impostor_quest.json"))
var phase:="available"
var nodes: Array[Node]=[]
var signature:=""
func _ready() -> void:
	game.PORTRAITS.ACTORS[SUSPECT]={"name":"마응칠","basic_portrait":"male_middle"}
	# Song uses the shared dedicated portrait and remains an event-only actor.
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"offer":{"label":"관아 앞 육정호에게 사칭 사건 묻기","goals":[]},
		"witness":{"label":"하역장 오덕수에게 증언과 징수 문서 확인","goals":[]},
		"verify":{"label":"육정호에게 문서와 무림맹 회답 확인","goals":[]},
		"confront":{"label":"나루 창고 뒤 사칭범 마응칠 붙잡기","goals":[]},
		"report":{"label":"관아 앞 육정호에게 체포 결과 보고","goals":[]},
		"thanks":{"label":"송지겸에게 무림맹의 감사 인사 듣기","goals":[]}}}
func eligible() -> bool:
	if game.alliance_visit.phase not in ["training_complete","closed"]:return false
	for id in game.progress.learned:
		if game.progress.arts.get_skill(id).get("acquisition")=="alliance_instructor":return true
	return false
func reset() -> void:clear_world();phase="available";signature=""
func status() -> String:
	if phase=="available":return "available" if eligible() else "locked"
	return "active" if phase in ["witness","verify","confront","battle","thanks"] else phase
func stage() -> String:return {"available":"offer","battle":"confront","ready":"report","completed":"report"}.get(phase,phase)
func target() -> String:return WITNESS if phase=="witness" else SUSPECT if phase in ["confront","battle"] else MESSENGER if phase=="thanks" else GIVER
func marker_for(id: String) -> String:
	if id!=GIVER:return ""
	return "!" if status()=="available" else "?" if phase=="ready" else ""
func is_target(id: String) -> bool:return phase not in ["available","completed"] and id==target()
func reward_label() -> String:return "보수 250문 · 명성+5 · 무림맹 호의도+5 (보수 수령 후 감사 대화)"
func track() -> void:game.quest_navigation.track(ID,stage())
func in_battle() -> bool:return phase=="battle"
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="wuchang" or status()=="locked":return false
	if id==GIVER:
		match phase:
			"available":game.say(data.scenes.intro,_offer)
			"witness":game.say(data.scenes.progress_witness)
			"verify":game.say(data.scenes.verify,_verified)
			"confront":game.say(data.scenes.progress_confront)
			"ready":game.say(data.scenes.report,_paid)
			"thanks":_thank_you()
			"completed":game.say(data.scenes.post)
		return true
	if id==WITNESS and phase=="witness":game.say(data.scenes.witness,_inspect);return true
	if id==SUSPECT and phase=="confront":game.say(data.scenes.confront,_start_battle);return true
	if id==MESSENGER and phase=="thanks":_thank_you();return true
	return false
func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n나루의 증언과 문서를 확인한 뒤 사칭범을 붙잡으세요.","나루에서 알아보겠습니다",accept,"지금은 다른 일이 있습니다",decline)
func accept() -> void:
	if phase!="available" or not eligible():return
	phase="witness";track();refresh_world();game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _inspect() -> void:
	if phase=="witness":game.say(data.scenes.inspect,_inspected)
func _inspected() -> void:
	if phase!="witness":return
	phase="verify";track();refresh_world();game.adventure_ui.notify("징수 문서 확인 · 육정호에게 보고","quest")
func _verified() -> void:
	if phase!="verify":return
	phase="confront";track();refresh_world();game.adventure_ui.notify("사칭 확인 · 나루 창고 뒤 마응칠 찾기","quest")
func _start_battle() -> void:
	if phase!="confront":return
	phase="battle";game.start_battle(data.encounter)
func _return_to_map() -> void:
	game.battle.hide();game.state="explore";game.exploration.show()
	game.exploration.camera.enabled=true;game.exploration.camera.snap_to_player()
	game.top_hud.show();game.bottom_hint.text=UI.EXPLORATION_HINT;game.bottom_hint.show();game.music.play_track("dock")
func after_victory() -> void:
	if phase!="battle":return
	phase="ready";_return_to_map();game.say(data.scenes.victory,_resolved)
func after_defeat() -> void:
	if phase!="battle":return
	phase="confront";_return_to_map();game.say(data.scenes.defeat,_retreat)
func _retreat() -> void:
	track();refresh_world();game.adventure_ui.notify("조사 진도 유지 · I/K 정비 후 마응칠에게 재도전","quest")
func _resolved() -> void:
	track();refresh_world();game.adventure_ui.notify("사칭범 체포 · 육정호에게 보고","quest")
func _paid() -> void:
	if phase!="ready":return
	phase="thanks";game.money+=int(data.reward.money)
	track();refresh_world();game.adventure_ui.notify("관의 보수 · 250문","coin")
	_thank_you()
func _thank_you() -> void:
	if phase=="thanks":game.say(data.scenes.thanks,_complete,["hero",GIVER])
func _complete() -> void:
	if phase!="thanks":return
	phase="completed";game.progress.fame+=int(data.reward.fame)
	game.progress.add_favor(str(data.reward.faction),int(data.reward.favor))
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 명성+5 · 무림맹 호의도+5","quest")

func goal(world) -> Dictionary:
	if status()=="locked":return {}
	var point: Vector2
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id")==target():point=npc.position;break
	elif world.area_name=="mountain_road":point=world.city_point([740,64]);label="산길 북쪽 출입구로 무창에 이동"
	elif world.area_name=="changsha":point=world.city_point([1490,510]);label="동쪽 농촌에서 무창 방면 산길로 이동"
	elif world.area_name=="alliance_office":point=world.city_point([256,321]);label="총무당을 나와 관아 앞으로 이동"
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
func _actor(id: String,point: Array,frame: int,role: String,district: String) -> void:
	var world=game.exploration
	world._populate_residents([{"id":id,"name":game.PORTRAITS.ACTORS[id].name,"point":point,"frame":frame,"quest_actor":true,"post":role,"district":district,"character_profile":{},"role":role}])
	var node=world.ambient_nodes.back();nodes.append(node)
	var tag=world.occlusion_roots.pop_back();tag.reparent(node);tag.position=Vector2.ZERO
func refresh_world() -> void:
	var w=game.exploration;var next_signature="%d:%s:%s:%s" % [w.load_revision,w.area_name,phase,status()]
	if signature==next_signature:return
	signature=next_signature;clear_world();_navigation()
	if w.area_name!="wuchang":return
	for npc in w.ambient_nodes:
		if npc.get_meta("npc_id")!=GIVER:continue
		var marker=UI.label(npc,marker_for(GIVER),Rect2(-20,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP,40,46),34,Color("ffe14b"))
		marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.visible=not marker.text.is_empty()
		marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5);nodes.append(marker)
	if phase in ["confront","battle"]:_actor(SUSPECT,data.suspect_point,7,"사칭범","harbor")
	if phase=="thanks":_actor(MESSENGER,data.messenger_point,4,"무림맹 외무 무사","government")
	_navigation()
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:phase=value.get("phase","available");signature="";refresh_world()
