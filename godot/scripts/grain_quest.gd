extends Node
const ID="wuchang_double_grain"
const GIVER="wc_zhou_jifu"
const CLERK="wc_jin_munsu"
const OFFICER="wc_lu_zhenghao"
const COLLECTOR="grain_yang_samro"
const PHASES=["available","receipt","shipping","official","confront","ready","completed"]
const UI=preload("res://scripts/ui.gd")
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_grain_quest.json"))
var phase:="available"
var nodes: Array[Node]=[]
var officer_home:=Vector2.ZERO
var officer_body: Node2D
var hearing_active:=false
var signature:=""
func _ready() -> void:
	game.PORTRAITS.ACTORS[COLLECTOR]={"name":"양삼로","basic_portrait":"male_common_a"}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"offer":{"label":"남쪽 농촌 주계복에게 독촉 사정 듣기","goals":[]},
		"receipt":{"label":"주계복과 찢어진 영수증 조사","goals":[]},
		"shipping":{"label":"나루 진문수에게 곡식 운송 기록 확인","goals":[]},
		"official":{"label":"육정호에게 관아 수납 기록 대조 요청","goals":[]},
		"confront":{"label":"농촌 양삼로에게 공식 확인 내용 전하기","goals":[]},
		"report":{"label":"주계복에게 납부 확인서 전달","goals":[]}}}
func reset() -> void:clear_world();phase="available";hearing_active=false;signature=""
func status() -> String:return "active" if phase in ["receipt","shipping","official","confront"] else phase
func stage() -> String:return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)
func marker_for(id: String) -> String:return ("!" if phase=="available" else "?" if phase=="ready" else "") if id==GIVER else ""
func is_target(id: String) -> bool:return (phase=="receipt" and id==GIVER) or (phase=="shipping" and id==CLERK) or (phase=="official" and id==OFFICER) or (phase=="confront" and id==COLLECTOR)
func reward_label() -> String:return "보수 200문"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="wuchang":return false
	if id==GIVER:
		if game.artisan_quest.phase!="available":
			game.adventure_ui.choose("주계복 · 용건","곡식 독촉과 농기구 이야기 중 용건을 고르세요.","두 번 걷힌 곡식",talk_giver,"장인의 이름값",_artisan)
		else:talk_giver()
		return true
	if id==CLERK and phase=="shipping":
		if game.wages_quest.phase in ["ledger","decide"]:
			game.adventure_ui.choose("진문수 · 용건","곡식 운송 기록과 품삯 장부는 별도의 일입니다.","세곡 운송 기록",_shipping,"품삯에서 빠진 세 줄",_wages)
		else:_shipping()
		return true
	if id==OFFICER and phase in ["official","confront"]:
		game.adventure_ui.choose("육정호 · 용건","납부 확인과 다른 용건 중 고르세요.","두 번 걷힌 곡식",_officer_talk,"다른 용건",_other_officer)
		return true
	if id==COLLECTOR and phase in ["receipt","shipping","official","confront"]:
		if phase=="confront":
			hearing_active=true;refresh_world();game.say(data.scenes.confront,_cleared)
		else:game.say(data.scenes.collector_wait)
		return true
	return false
func _artisan() -> void:game.artisan_quest.handle_interaction(GIVER)
func _wages() -> void:game.wages_quest.handle_interaction(CLERK)
func _other_officer() -> void:
	if game.impostor_quest.handle_interaction(OFFICER):return
	for entry in game.exploration.city_data.residents:
		if entry.id==OFFICER:game.say(entry.dialogue);return
func talk_giver() -> void:
	match phase:
		"available":game.say(data.scenes.intro,_offer)
		"receipt":game.say(data.scenes.receipt,_receipt_done)
		"ready":game.say(data.scenes.report,_complete)
		"completed":game.say(data.scenes.post)
		_:game.say(data.scenes.progress)
func _offer() -> void:game.adventure_ui.choose("의뢰 · "+str(data.title),"보수200문 · 영수증과 운송 기록을 확인하고 관아에서 납부 사실을 대조하세요.","납부 경위를 확인해 보겠습니다",accept,"지금은 다른 일이 있습니다",decline)
func accept() -> void:
	if phase!="available":return
	phase="receipt";track();refresh_world();game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _receipt_done() -> void:
	if phase!="receipt":return
	phase="shipping";track();refresh_world();game.adventure_ui.notify("영수증 확인 · 나루 운송 기록 찾기","quest")
func _shipping() -> void:
	if phase!="shipping":return
	var lines: Array=data.scenes.shipping.duplicate(true)
	if game.wages_quest.phase=="completed":lines=data.scenes.shipping_known+lines
	game.say(lines,_shipping_done)
func _shipping_done() -> void:
	if phase!="shipping":return
	phase="official";track();refresh_world();game.adventure_ui.notify("운송 기록 확인 · 관아 수납 기록 대조 필요","quest")
func _officer_talk() -> void:
	if phase=="official":game.say(data.scenes.official,_verified)
	elif phase=="confront":game.say(data.scenes.officer_field)
func _verified() -> void:
	if phase!="official":return
	phase="confront";track();refresh_world();game.adventure_ui.notify("납부 확인 · 농촌에서 양삼로 추궁","quest")
func _cleared() -> void:
	if phase!="confront":return
	hearing_active=false;phase="ready";track();refresh_world();game.adventure_ui.notify("독촉 철회 · 주계복에게 확인서 전달","quest")
func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=200
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 200문","quest")
func goal(world) -> Dictionary:
	var point: Vector2;var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		var target: String={"shipping":CLERK,"official":OFFICER,"confront":COLLECTOR}.get(phase,GIVER)
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id")==target:point=npc.position;break
	elif world.area_name=="changsha":point=world.city_point([1490,510]);label="동쪽 농촌에서 무창 방면 산길로 이동"
	elif world.area_name=="mountain_road":point=world.city_point([740,64]);label="북쪽 포탈에서 무창으로 이동"
	elif world.area_name=="alliance_office":point=world.city_point([256,321]);label="총무당을 나와 무창으로 이동"
	return {} if point==Vector2.ZERO else {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func _tag_position(npc: Node2D) -> void:
	for tag in game.exploration.occlusion_roots:
		if is_instance_valid(tag) and tag.get_meta("npc_id","")==OFFICER:tag.position=npc.position
func clear_world() -> void:
	var w=game.exploration
	if is_instance_valid(officer_body) and officer_home!=Vector2.ZERO:
		officer_body.position=officer_home;_tag_position(officer_body)
	officer_body=null;officer_home=Vector2.ZERO
	for node in nodes:
		if is_instance_valid(node):
			if node is Node2D:w.ambient_nodes.erase(node)
			node.free()
	nodes.clear()
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s:%s" % [w.load_revision,w.area_name,phase,hearing_active]
	if signature==sig:return
	signature=sig;clear_world()
	if w.area_name!="wuchang":return
	for npc in w.ambient_nodes:
		if npc.get_meta("npc_id")==GIVER:
			var marker=UI.label(npc,marker_for(GIVER),Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"));marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.visible=not marker.text.is_empty();marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5);nodes.append(marker)
		if phase=="confront" and hearing_active and npc.get_meta("npc_id")==OFFICER:
			officer_body=npc;officer_home=npc.position;npc.position=w._clear_citizen_position(w.city_point(data.officer_point),{"id":OFFICER,"district":"farmland"});_tag_position(npc)
	if phase in ["receipt","shipping","official","confront"]:
		w._populate_residents([{"id":COLLECTOR,"name":"양삼로","point":data.collector_point,"frame":4,"post":"세곡 독촉 현장","district":"farmland","quest_actor":true,"character_profile":{},"role":"징수 담당 아전"}])
		var npc=w.ambient_nodes.back();nodes.append(npc);var tag=w.occlusion_roots.pop_back();tag.reparent(npc);tag.position=Vector2.ZERO
	w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:phase=value.get("phase","available");hearing_active=false;signature="";refresh_world()
