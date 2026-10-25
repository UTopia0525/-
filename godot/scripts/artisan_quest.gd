extends Node
## A standalone investigation; steps commit only after their conversations end.
const ID = "wuchang_artisan_reputation"
const GIVER = "wc_shi_dayong"
const FARMER = "wc_zhou_jifu"
const DOCK = "wc_wu_deshu"
const UI = preload("res://scripts/ui.gd")
const PHASES = ["available","farmer","dock","ready","completed"]
var game
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_artisan_quest.json"))
var phase := "available"
var marker: Label
var signature := ""

func _ready() -> void:
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"offer":{"label":"무창 공방거리의 석대용에게 일거리 묻기","goals":[]},
		"farmer":{"label":"남문 밖 농촌의 주계복에게 호미와 구매 경위 확인","goals":[]},
		"dock":{"label":"하역장의 오덕수에게 반입 장부 확인","goals":[]},
		"report":{"label":"공방거리의 석대용에게 조사 결과 보고","goals":[]}}}

func reset() -> void:
	clear_world();phase="available";signature=""

func status() -> String:return "active" if phase in ["farmer","dock"] else phase
func stage() -> String:return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)
func target() -> String:return FARMER if phase=="farmer" else DOCK if phase=="dock" else GIVER
func is_target(id: String) -> bool:return phase in ["farmer","dock","ready"] and id==target()
func marker_for(id: String) -> String:
	if id!=GIVER:return ""
	return "!" if phase=="available" else "?" if phase=="ready" else ""
func reward_label() -> String:return "보수 %d문" % int(data.reward.money)
func track() -> void:game.quest_navigation.update_quest(ID,stage())

func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="wuchang":return false
	if id==GIVER:
		game.adventure_ui.choose("석대용 · 병장기 장인","호미의 출처에 관한 이야기와 병장기 거래 중 용건을 고르세요.",
			"장인의 이름값",talk_giver,"병장기를 살펴본다",trade)
		return true
	if id==FARMER:
		match phase:
			"farmer":game.say(data.scenes.farmer,_farmer_done)
			"dock":game.say(data.scenes.farmer_wait)
			"ready":game.say(data.scenes.farmer_ready)
			"completed":game.say(data.scenes.post_farmer)
			_:return false
		return true
	if id==DOCK:
		match phase:
			"dock":game.say(data.scenes.dock,_dock_done)
			"ready":game.say(data.scenes.dock_wait)
			"completed":game.say(data.scenes.post_dock)
			_:return false
		return true
	return false

func talk_giver() -> void:
	match phase:
		"available":game.say(data.scenes.intro,_offer)
		"farmer":game.say(data.scenes.progress_farmer)
		"dock":game.say(data.scenes.progress_dock)
		"ready":game.say(data.scenes.report,_complete)
		"completed":game.say(data.scenes.post_giver)

func trade() -> void:
	game.pending_service_id="city_artisan"
	game.say(data.scenes.trade,game._service_done)

func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n주계복에게 호미의 출처를 묻고 나루의 반입 기록을 확인하세요.",
		"어디서 산 물건인지 알아보겠습니다",accept,"지금은 시간을 내기 어렵습니다",decline)

func accept() -> void:
	if phase!="available":return
	phase="farmer";track();refresh_world()
	game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest")
	game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)

func _farmer_done() -> void:
	if phase!="farmer":return
	phase="dock";track();refresh_world()
	game.adventure_ui.notify("의뢰 갱신 · 하역장의 오덕수에게 반입 장부 확인","quest")

func _dock_done() -> void:
	if phase!="dock":return
	phase="ready";track();refresh_world()
	game.adventure_ui.notify("조사 완료 · 석대용에게 보고","quest")

func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=int(data.reward.money)
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world()
	game.adventure_ui.notify("의뢰 완료 · %d문" % int(data.reward.money),"quest")

func goal(world) -> Dictionary:
	var point: Vector2
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id")==target():point=npc.position;break
	elif world.area_name=="mountain_road":
		point=world.city_point([740,64]);label="산길 북쪽 출입구로 무창에 이동"
	elif world.area_name=="changsha":
		point=world.city_point([1490,510]);label="동쪽 농촌에서 무창 방면 산길로 이동"
	elif world.area_name=="alliance_office":
		point=world.city_point([256,321]);label="총무당을 나와 무창 주민에게 이동"
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}

func clear_world() -> void:
	if is_instance_valid(marker):marker.free()
	marker=null

func refresh_world() -> void:
	var world=game.exploration
	var next_signature="%d:%s:%s" % [world.load_revision,world.area_name,phase]
	if signature==next_signature:return
	signature=next_signature;clear_world()
	if world.area_name!="wuchang":return
	for npc in world.ambient_nodes:
		if npc.get_meta("npc_id")!=GIVER:continue
		marker=UI.label(npc,marker_for(GIVER),Rect2(-40,-world.Metrics.CITIZEN_HEIGHT-world.Metrics.QUEST_GAP-world.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"))
		marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5)
		marker.visible=not marker.text.is_empty()
		break

func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:
	phase=value.get("phase","available");signature="";refresh_world()
