extends Node
const ID="nanjing_cart"
const GIVER="nj_dockworker"
const WORKER="nj_crowd_port_worker"
const ARTISAN="nj_artisan"
const CLERK="nj_clerk"
const OWNER="nj_crowd_inn_guest"
const CART="quest_goal:nanjing_cart:cart"
const UI=preload("res://scripts/ui.gd")
const PHASES=["available","worker","cart","artisan","clerk","owner","ready","completed"]
const TARGETS={"available":GIVER,"worker":WORKER,"cart":CART,"artisan":ARTISAN,"clerk":CLERK,"owner":OWNER,"ready":GIVER,"completed":GIVER}
var game
var phase:="available"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_cart_quest.json"))
var nodes: Array[Node]=[]
var signature:=""
func _ready() -> void:
	var stages={}
	for item in [["offer","나루의 곽만재에게 수레 이야기 듣기"],["worker","왕복생에게 수레가 부러진 경위 듣기"],["cart","창고거리 남쪽의 부서진 수레 조사"],["artisan","공방의 유철생에게 부러진 차축 진단받기"],["clerk","창고 서리 윤문식에게 당시 반출 상황 확인"],["owner","객잔 부근 석문수에게 수리비와 품삯 협의"],["report","곽만재에게 결과 전달·왕복생과 이야기"]]:stages[item[0]]={"label":item[1],"goals":[]}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func reset() -> void:clear_world();phase="available";signature=""
func status() -> String:return "available" if phase=="available" else "ready" if phase=="ready" else "completed" if phase=="completed" else "active"
func stage() -> String:return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)
func target() -> String:return TARGETS[phase]
func is_target(id: String) -> bool:return phase not in ["available","completed"] and id==target()
func marker_for(id: String) -> String:return "!" if id==GIVER and phase=="available" else "?" if id==GIVER and phase=="ready" else ""
func reward_label() -> String:return "보수 200문 · 수리비 지출 없음"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func journal_items() -> Array:return [{"id":"cart_axle","name":"부러진 차축 조각 · 조사 증거 (판매/소비 불가)"}] if phase in ["artisan","clerk","owner","ready"] else []
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="nanjing":return false
	if id==CLERK and game.nanjing_relief_quest.is_target(id):
		if phase=="clerk":game.adventure_ui.choose("윤문식 · 창고 서리","확인할 용건을 고르세요.","수레 반출 상황",_talk_clerk,"구휼 장부",_talk_relief);return true
		return false
	if id==ARTISAN and phase in ["artisan","completed"]:
		game.adventure_ui.choose("유철생 · 장인","차축 이야기 또는 병장기 거래를 고르세요.","한 수레의 무게",_talk_artisan,"병장기를 살펴본다",_trade);return true
	if id==GIVER:
		if phase=="available":game.say(data.scenes.intro,_offer)
		elif phase=="ready":game.say(data.scenes.report,_complete)
		elif phase=="completed":game.say(data.scenes.post_giver)
		else:game.say(data.scenes.wait)
		return true
	if phase not in ["available","completed","ready"] and id==target():
		game.say(data.scenes[phase],_advance);return true
	if id==CART:
		game.say([["hero","짐을 덜어 내고 받침을 댄 수레다. 축과 바퀴 수리를 기다리고 있군." if phase=="completed" else "짐이 한쪽으로 쏠린 채 축이 부러져 있다. 일꾼의 설명부터 들어야겠어." if phase in ["available","worker"] else "이미 부러진 축과 적재 상태를 확인했다."]]);return true
	if phase=="completed" and id in [WORKER,CLERK,OWNER]:game.say(data.scenes[{WORKER:"post_worker",CLERK:"post_clerk",OWNER:"post_owner"}[id]]);return true
	return false
func _talk_artisan() -> void:
	if phase=="artisan":game.say(data.scenes.artisan,_advance)
	elif phase=="completed":game.say(data.scenes.post_artisan)
func _talk_clerk() -> void:
	if phase=="clerk":game.say(data.scenes.clerk,_advance)
func _talk_relief() -> void:game.nanjing_relief_quest.handle_interaction(CLERK)
func _trade() -> void:
	game.pending_service_id="city_artisan"
	for service in game.exploration.city_data.services:
		if service.id=="city_artisan":game.say(service.greeting_lines,game._service_done);return
func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n수레의 상태와 당시 사정을 함께 살펴보세요.","수레와 사정을 살펴보겠소",accept,"지금은 다른 용무가 있소",decline)
func accept() -> void:
	if phase!="available":return
	phase="worker";track();refresh_world();game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _advance() -> void:
	var next={"worker":"cart","cart":"artisan","artisan":"clerk","clerk":"owner","owner":"ready"}
	if not next.has(phase):return
	phase=next[phase];track();refresh_world();game.adventure_ui.notify("의뢰 갱신 · "+str(game.quest_navigation.definitions[ID].stages[stage()].label),"quest")
func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=int(data.reward.money)
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 200문","coin")
func goal(world) -> Dictionary:
	var point=Vector2.ZERO
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="nanjing":
		for a in world.ambient_nodes:
			if a.get_meta("npc_id")==target():point=a.position
		for o in world.objectives:
			if o.id==target():point=o.position
	else:
		var exit_id: String={"changsha":"travel:road_east","mountain_road":"travel:wuchang","wuchang":"travel:qingya","alliance_office":"travel:office_exit","qingya_hamlet":"travel:nanjing","qingya_camp":"travel:hamlet"}.get(world.area_name,"")
		for exit in world.travel_exits:
			if exit.id==exit_id:point=exit.position;label="남경 의뢰를 위해 "+str(exit.name)+" 이동"
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func clear_world() -> void:
	game.exploration.objectives=game.exploration.objectives.filter(func(o):return o.id!=CART)
	for node in nodes:
		if is_instance_valid(node):node.free()
	nodes.clear()
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s" % [w.load_revision,w.area_name,phase]
	if signature==sig:return
	signature=sig;clear_world()
	if w.area_name!="nanjing":return
	for a in w.ambient_nodes:
		var text=marker_for(a.get_meta("npc_id"))
		if text.is_empty():continue
		var mark=UI.label(a,text,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"));mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		mark.add_theme_color_override("font_outline_color",Color("2b2614"));mark.add_theme_constant_override("outline_size",5);nodes.append(mark)
	for prop in w.scenery_nodes:
		if prop.name!="capital_12":continue
		var prefab: Dictionary=w.city_data.prefabs["quest_cart_waiting" if phase=="completed" else "quest_cart_broken"]
		var tex=AtlasTexture.new();tex.atlas=load(prefab.texture);tex.region=Rect2(prefab.source[0],prefab.source[1],prefab.source[2],prefab.source[3])
		prop.sprite.texture=tex;prop.sprite.scale=prop.visual_rect.size/tex.region.size
		for tile in w.art_tiles:
			if tile.target.position==Vector2(265,315):tile.texture=tex.atlas;tile.source=tex.region
		w.objectives.append({"id":CART,"goal_id":CART,"name":"수리 대기 수레" if phase=="completed" else "부서진 곡물 수레","position":prop.position,"node":prop,"frame":-1,"important":is_target(CART)})
		if phase=="cart":
			var marker=UI.label(w.decorations,"◆",Rect2(prop.position+Vector2(-40,-190),Vector2(80,92)),68,Color("ffcf69"));marker.set_meta("hud_anchor",prop.position);marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.z_index=6;nodes.append(marker)
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:phase=value.get("phase","available");signature="";refresh_world()
