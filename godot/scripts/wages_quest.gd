extends Node
const STAT_MAX = preload("res://scripts/rules.gd").STAT_MAX
## A standalone non-combat inquiry; shared dock witness has explicit topic routing.
const ID="wuchang_missing_wages"
const GIVER="wc_wu_deshu"
const CLERK="wc_jin_munsu"
const BOARD="quest_goal:wuchang_missing_wages:board"
const PHASES=["available","inspect","ledger","decide","ready","completed"]
const UI=preload("res://scripts/ui.gd")
const Board=preload("res://scripts/work_board.gd")
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_wages_quest.json"))
var phase:="available"
var nodes: Array[Node]=[]
var board_foot:=Rect2()
var board_visual:=Rect2()
var signature:=""
func _ready() -> void:
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"offer":{"label":"나루 오덕수에게 품삯 문제 묻기","goals":[]},
		"inspect":{"label":"오덕수 옆 하역장 가장자리 작업판 조사","goals":[]},
		"ledger":{"label":"창고 앞 진문수에게 지급 장부 확인","goals":[]},
		"decide":{"label":"진문수와 운송료 부담 주체 정리","goals":[]},
		"report":{"label":"오덕수에게 정산 결과 보고","goals":[]}}}
func reset() -> void:clear_world();phase="available";signature=""
func status() -> String:return "active" if phase in ["inspect","ledger","decide"] else phase
func stage() -> String:return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)
func marker_for(id: String) -> String:return ("!" if phase=="available" else "?" if phase=="ready" else "") if id==GIVER else ""
func is_target(id: String) -> bool:return (phase=="inspect" and id==BOARD) or (phase in ["ledger","decide"] and id==CLERK) or (phase=="ready" and id==GIVER)
func reward_label() -> String:return "보수 100문 · 오성+2 (상한200)"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func other_topics() -> Array:
	var topics=[]
	if game.impostor_quest.phase=="witness":topics.append("impostor")
	if game.artisan_quest.phase=="dock":topics.append("artisan")
	return topics
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="wuchang":return false
	if id==GIVER:
		if not other_topics().is_empty():
			game.adventure_ui.choose("오덕수 · 용건","품삯 이야기와 다른 의뢰의 용건을 따로 물을 수 있습니다.","품삯에서 빠진 세 줄",talk_giver,"다른 의뢰의 용건",_other_business)
		else:talk_giver()
		return true
	if id==BOARD:
		game.say(data.scenes.inspect,_inspected) if phase=="inspect" else game.say(data.scenes.board_idle)
		return true
	if id==CLERK:
		match phase:
			"available":game.say(data.scenes.jin_idle)
			"inspect":game.say(data.scenes.jin_before)
			"ledger":game.say(data.scenes.ledger,_ledger_done)
			"decide":choose_correction()
			"ready":game.say(data.scenes.jin_ready)
			"completed":game.say(data.scenes.jin_post)
		return true
	return false
func _other_business() -> void:
	var topics=other_topics()
	if topics.size()==2:
		game.adventure_ui.choose("오덕수 · 다른 용건","진행할 의뢰의 이야기를 고르세요.","빌려 쓴 무림맹 이름",_impostor,"장인의 이름값",_artisan)
	elif topics==["impostor"]:_impostor()
	elif topics==["artisan"]:_artisan()
func _impostor() -> void:game.impostor_quest.handle_interaction(GIVER)
func _artisan() -> void:game.artisan_quest.handle_interaction(GIVER)
func talk_giver() -> void:
	match phase:
		"available":game.say(data.scenes.intro,_offer)
		"inspect":game.say(data.scenes.progress_inspect)
		"ledger":game.say(data.scenes.progress_ledger)
		"decide":game.say(data.scenes.progress_decide)
		"ready":game.say(data.scenes.report,_complete)
		"completed":game.say(data.scenes.post)
func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n작업판과 지급 장부를 비교해 공제된 품삯을 확인하세요.","기록을 살펴보겠습니다",accept,"지금은 다른 일이 있습니다",decline)
func accept() -> void:
	if phase!="available":return
	phase="inspect";track();refresh_world();game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _inspected() -> void:
	if phase!="inspect":return
	phase="ledger";track();refresh_world();game.adventure_ui.notify("작업 기록 확인 · 진문수에게 지급 장부 묻기","quest")
func _ledger_done() -> void:
	if phase!="ledger":return
	phase="decide";track();refresh_world();choose_correction()
func choose_correction() -> void:
	if phase!="decide":return
	game.adventure_ui.choose("운송료는 누구의 몫인가","작업판은 하역 완료, 계약 앞장은 ‘화주 정산’으로 되어 있습니다.","화주에게 청구할 돈을 일꾼들에게서 뺐군요",_resolve,"일꾼들이 운송료까지 부담하기로 한 것 아닙니까",_wrong)
func _resolve() -> void:
	if phase=="decide":game.say(data.scenes.resolve,_resolved)
func _wrong() -> void:
	if phase=="decide":game.say(data.scenes.wrong,choose_correction)
func _resolved() -> void:
	if phase!="decide":return
	phase="ready";track();refresh_world();game.adventure_ui.notify("정산 바로잡기 완료 · 오덕수에게 보고","quest")
func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=int(data.reward.money)
	var before: int=int(game.progress.stats.insight)
	game.progress.stats.insight=mini(STAT_MAX,before+int(data.reward.insight))
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 100문 · 오성+%d" % (int(game.progress.stats.insight)-before),"quest")
func goal(world) -> Dictionary:
	var point: Vector2;var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		if phase=="inspect":
			for entry in world.objectives:
				if entry.id==BOARD:point=entry.position
		else:
			var target: String=CLERK if phase in ["ledger","decide"] else GIVER
			for npc in world.ambient_nodes:
				if npc.get_meta("npc_id")==target:point=npc.position;break
	elif world.area_name=="changsha":point=world.city_point([1490,510]);label="동쪽 농촌 포탈에서 무창으로 이동"
	elif world.area_name=="mountain_road":point=world.city_point([740,64]);label="북쪽 포탈에서 무창으로 이동"
	elif world.area_name=="alliance_office":point=world.city_point([256,321]);label="총무당을 나와 나루로 이동"
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func clear_world() -> void:
	var w=game.exploration
	w.objectives=w.objectives.filter(func(e):return e.id!=BOARD)
	if board_foot.has_area():
		w.blockers.erase(board_foot)
		if is_instance_valid(w.regional_map):w.regional_map.blockers.erase(board_foot)
	if board_visual.has_area():w.scenery_bounds.erase(board_visual)
	board_foot=Rect2();board_visual=Rect2()
	for node in nodes:
		if is_instance_valid(node):node.free()
	nodes.clear()
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s" % [w.load_revision,w.area_name,phase]
	if signature==sig:return
	signature=sig;clear_world()
	if w.area_name!="wuchang":return
	for npc in w.ambient_nodes:
		if npc.get_meta("npc_id")!=GIVER:continue
		var marker=UI.label(npc,marker_for(GIVER),Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"))
		marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.visible=not marker.text.is_empty();marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5);nodes.append(marker)
	var board=Board.new();board.position=w._clear_citizen_position(w.city_point(data.board_point),{"id":BOARD,"district":"harbor"})
	w.decorations.add_child(board);nodes.append(board)
	board_foot=Rect2(board.position+Board.FOOT.position,Board.FOOT.size);board_visual=Rect2(board.position+Board.VISUAL.position,Board.VISUAL.size)
	w.blockers.append(board_foot);w.regional_map.blockers.append(board_foot);w.scenery_bounds.append(board_visual)
	w.objectives.append({"id":BOARD,"goal_id":"board","name":"나루 작업판","position":board.position,"node":board,"frame":-1,"important":phase=="inspect"})
	w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:phase=value.get("phase","available");signature="";refresh_world()
