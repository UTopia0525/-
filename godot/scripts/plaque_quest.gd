extends Node
const ID="wuchang_old_nameplate"
const GIVER="wc_grandmother_zheng"
const MANAGER="wc_no_seongbok"
const PREFIX="quest_goal:wuchang_old_nameplate:"
const PHASES=["available","manager","search","ready","completed"]
const UI=preload("res://scripts/ui.gd")
const Wood=preload("res://scripts/salvaged_wood.gd")
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_plaque_quest.json"))
var phase:="available"
var checked: Array=[]
var nodes: Array[Node]=[]
var feet: Array[Rect2]=[]
var visuals: Array[Rect2]=[]
var signature:=""
func _ready() -> void:
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"offer":{"label":"정씨 할머니에게 문패 이야기 듣기","goals":[]},
		"manager":{"label":"주거구역 서쪽 노성복에게 수색 허락받기","goals":[]},
		"search":{"label":"옛집 목재 적치장에서 문패 찾기","goals":[]},
		"report":{"label":"정씨 할머니에게 문패 돌려드리기","goals":[]}}}
func reset() -> void:clear_world();phase="available";checked=[];signature=""
func status() -> String:return "active" if phase in ["manager","search"] else phase
func stage() -> String:return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)
func marker_for(id: String) -> String:return ("!" if phase=="available" else "?" if phase=="ready" else "") if id==GIVER else ""
func is_target(id: String) -> bool:return (phase=="manager" and id==MANAGER) or (phase=="search" and id.begins_with(PREFIX) and id.trim_prefix(PREFIX) not in checked)
func reward_label() -> String:return "보수 100문"
func track() -> void:game.quest_navigation.track(ID,stage())
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="wuchang":return false
	if id==GIVER:
		match phase:
			"available":game.say(data.scenes.intro,_offer)
			"ready":game.say(data.scenes.report,_complete)
			"completed":game.say(data.scenes.post)
			_:game.say(data.scenes.progress)
		return true
	if id==MANAGER:
		match phase:
			"manager":game.say(data.scenes.permission,_permission)
			"search":game.say(data.scenes.manager_wait)
			"ready","completed":game.say(data.scenes.manager_post)
			_:game.say(data.scenes.manager_idle)
		return true
	if phase=="search" and id.begins_with(PREFIX) and data.props.has(id.trim_prefix(PREFIX)):
		var kind=id.trim_prefix(PREFIX);game.say(data.scenes[kind],_searched.bind(kind));return true
	return false
func _offer() -> void:game.adventure_ui.choose("의뢰 · "+str(data.title),"보수100문 · 관리인의 허락을 받은 뒤 목재를 살펴보세요.","제가 찾아보겠습니다",accept,"지금은 다른 일이 있습니다",decline)
func accept() -> void:
	if phase!="available":return
	phase="manager";track();refresh_world();game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _permission() -> void:
	if phase!="manager":return
	phase="search";track();refresh_world();game.adventure_ui.notify("수색 허락 · 목재 적치장 조사","quest")
func _searched(kind: String) -> void:
	if phase!="search" or not data.props.has(kind):return
	if kind not in checked:checked.append(kind)
	if kind=="door":phase="ready";game.adventure_ui.notify("문패 회수 · 정씨 할머니에게 보고","quest")
	track();refresh_world()
func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=100
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 100문 · 문패를 다시 걸었습니다.","quest")
func goal(world) -> Dictionary:
	var point: Vector2;var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="wuchang":
		if phase=="search":
			var best=INF
			for entry in world.objectives:
				if not str(entry.id).begins_with(PREFIX) or str(entry.id).trim_prefix(PREFIX) in checked:continue
				var distance: float=entry.position.distance_squared_to(world.player.position)
				if distance<best:best=distance;point=entry.position
		else:
			for npc in world.ambient_nodes:
				if npc.get_meta("npc_id")== (MANAGER if phase=="manager" else GIVER):point=npc.position;break
	elif world.area_name=="changsha":point=world.city_point([1490,510]);label="동쪽 농촌에서 무창 방면 산길로 이동"
	elif world.area_name=="mountain_road":point=world.city_point([740,64]);label="북쪽 포탈에서 무창으로 이동"
	elif world.area_name=="alliance_office":point=world.city_point([256,321]);label="총무당을 나와 주거구역으로 이동"
	return {} if point==Vector2.ZERO else {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func clear_world() -> void:
	var w=game.exploration
	w.objectives=w.objectives.filter(func(e):return not str(e.id).begins_with(PREFIX))
	for rect in feet:
		w.blockers.erase(rect)
		if is_instance_valid(w.regional_map):w.regional_map.blockers.erase(rect)
	for rect in visuals:w.scenery_bounds.erase(rect)
	feet.clear();visuals.clear()
	for node in nodes:
		if is_instance_valid(node):node.free()
	nodes.clear()
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s:%s" % [w.load_revision,w.area_name,phase,str(checked)]
	if signature==sig:return
	signature=sig;clear_world()
	if w.area_name!="wuchang":return
	for npc in w.ambient_nodes:
		if npc.get_meta("npc_id")!=GIVER:continue
		var marker=UI.label(npc,marker_for(GIVER),Rect2(-20,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP,40,46),34,Color("ffe14b"));marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.visible=not marker.text.is_empty();marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5);nodes.append(marker)
	if phase=="search":
		for kind in data.props:
			var node=Wood.new();node.kind=kind;node.position=w._clear_citizen_position(w.city_point(data.props[kind]),{"id":PREFIX+kind,"district":"homes"});w.decorations.add_child(node);nodes.append(node)
			var foot=Rect2(node.position+Wood.FOOT.position,Wood.FOOT.size);var visual=Rect2(node.position+Wood.VISUAL.position,Wood.VISUAL.size)
			feet.append(foot);visuals.append(visual);w.blockers.append(foot);w.regional_map.blockers.append(foot);w.scenery_bounds.append(visual)
			w.objectives.append({"id":PREFIX+kind,"goal_id":kind,"name":{"door":"묶어 둔 문짝","beam":"오래된 기둥","planks":"널빤지 더미"}[kind],"position":node.position,"node":node,"frame":-1,"important":kind not in checked})
	if phase=="completed":
		for house in w.scenery_nodes:
			if house.get_meta("scenery_id","")!="home_2":continue
			var plaque=Node2D.new();house.add_child(plaque);plaque.position=w.city_point([397,408])-house.position;nodes.append(plaque)
			var face=ColorRect.new();face.position=Vector2(-24,-14);face.size=Vector2(48,28);face.color=Color("4c3427");plaque.add_child(face)
			for i in range(3):
				var ink=ColorRect.new();ink.position=Vector2(-15+i*12,-9);ink.size=Vector2(3,18-i*2);ink.color=Color("d3b77d");plaque.add_child(ink)
	w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase,"checked":checked.duplicate()}
func valid(value) -> bool:
	if not value is Dictionary or value.get("phase") not in PHASES or not value.get("checked") is Array:return false
	for kind in value.checked:
		if not data.props.has(kind) or value.checked.count(kind)!=1:return false
	if value.phase in ["available","manager"]:return value.checked.is_empty()
	return ("door" in value.checked) if value.phase in ["ready","completed"] else "door" not in value.checked
func restore(value: Dictionary) -> void:phase=value.get("phase","available");checked=value.get("checked",[]).duplicate();signature="";refresh_world()
