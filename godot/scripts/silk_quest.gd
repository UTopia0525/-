extends Node
const ID="nanjing_silk"
const GIVER="nj_crowd_silk_buyer"
const VENDOR="nj_vendor"
const NEIGHBOR="nj_crowd_alley_neighbor"
const MARKET="quest_goal:nanjing_silk:market"
const CHEST="quest_goal:nanjing_silk:chest"
const UI=preload("res://scripts/ui.gd")
const PHASES=["available","market","vendor","neighbor","chest","ready","approval","completed"]
const TARGETS={"available":GIVER,"market":MARKET,"vendor":VENDOR,"neighbor":NEIGHBOR,"chest":CHEST,"ready":GIVER,"approval":GIVER,"completed":GIVER}
var game
var phase:="available"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_silk_quest.json"))
var nodes: Array[Node]=[]
var signature:=""
var transition_revision:=0
func _ready() -> void:
	var stages={}
	for item in [["offer","시장 유소란에게 옷감 사정 듣기"],["market","비단 노점의 주문표와 판매 상황 조사"],["vendor","나루 입구 정소복에게 옷감 구할 곳 묻기"],["neighbor","주거 골목 주씨 아주머니에게 사정 전달"],["chest","허락받은 천 상자에서 자투리 비단 찾기"],["report","유소란에게 남색 자투리 비단 전달"],["approval","유소란에게 손님의 회답과 완료 보수 받기"]]:stages[item[0]]={"label":item[1],"goals":[]}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func reset() -> void:transition_revision+=1;_caption_default();clear_world();phase="available";signature=""
func status() -> String:return "ready" if phase=="ready" else "completed" if phase=="completed" else "available" if phase=="available" else "active"
func stage() -> String:return {"available":"offer","ready":"report","completed":"approval"}.get(phase,phase)
func target() -> String:return TARGETS[phase]
func is_target(id: String) -> bool:return phase not in ["available","completed"] and id==target()
func marker_for(id: String) -> String:return "!" if id==GIVER and phase=="available" else "?" if id==GIVER and phase=="ready" else ""
func reward_label() -> String:return "보수 150문 · 구매 비용 없음"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func journal_items() -> Array:
	if phase in ["available","approval","completed"]:return []
	var result=[{"id":"silk_sample","name":"청색 옷감 견본 · 판매/소비 불가"}]
	if phase=="ready":result.append({"id":"silk_offcuts","name":"남색 자투리 비단 · 유소란에게 전달"})
	return result
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="nanjing":return false
	if id==GIVER:
		match phase:
			"available":game.say(data.scenes.intro,_offer)
			"ready":game.say(data.scenes.report,_begin_approval)
			"approval":_approval_finish()
			"completed":game.say(data.scenes.post_giver)
			_:game.say(data.scenes.wait)
		return true
	if id==CHEST:
		if phase=="chest":game.say(data.scenes.chest,_chest_done)
		elif phase in ["available","market","vendor","neighbor"]:game.say(data.scenes.locked_chest)
		else:game.say([["hero","필요한 천은 이미 챙겼다. 더 가져갈 이유는 없지."]])
		return true
	if id==MARKET:
		if phase=="market":game.say(data.scenes.market,_market_done)
		else:game.say([["hero","큰 주문의 표가 붙은 비단과 한 필 단위의 물건들이 진열되어 있다."]])
		return true
	if id==VENDOR and phase=="vendor":game.say(data.scenes.vendor,_vendor_done);return true
	if id==NEIGHBOR and phase=="neighbor":game.say(data.scenes.neighbor,_neighbor_done);return true
	if phase=="completed" and id in [VENDOR,NEIGHBOR]:game.say(data.scenes["post_vendor" if id==VENDOR else "post_neighbor"]);return true
	return false
func _offer() -> void:
	game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n같은 색과 두께의 옷감을 소량으로 구할 곳을 알아보세요.","조금씩 파는 곳을 알아보겠소",accept,"지금은 다른 용무가 있소",decline)
func accept() -> void:
	if phase!="available":return
	_update("market");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _update(next: String) -> void:
	phase=next;track();refresh_world();game.adventure_ui.notify("의뢰 갱신 · "+str(game.quest_navigation.definitions[ID].stages[stage()].label),"quest")
func _market_done() -> void:
	if phase=="market":_update("vendor")
func _vendor_done() -> void:
	if phase=="vendor":_update("neighbor")
func _neighbor_done() -> void:
	if phase=="neighbor":_update("chest")
func _chest_done() -> void:
	if phase=="chest":_update("ready")
func _begin_approval() -> void:
	if phase!="ready":return
	_update("approval");transition_revision+=1;var token=transition_revision
	game.state="story";game.exploration.set_active(false)
	game.story_caption.position=Vector2(40,305);game.story_caption.size=Vector2(1200,80);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.story_caption.text="잠시 뒤";game.story_caption.show()
	game.dialogue_backdrop.show()
	game.get_tree().create_timer(.85,false).timeout.connect(func():
		if token==transition_revision and phase=="approval":game.story_caption.hide();_approval_finish())
func _approval_finish() -> void:
	if phase=="approval":
		game.state="explore";_caption_default();game.story_caption.hide();game.say(data.scenes.approval,_complete)
func _caption_default() -> void:
	game.story_caption.position=Vector2(36,32);game.story_caption.size=Vector2(1200,45);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
func _complete() -> void:
	if phase!="approval":return
	phase="completed";game.money+=150
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 150문","coin")
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
	var w=game.exploration
	w.objectives=w.objectives.filter(func(o):return not str(o.id).begins_with("quest_goal:nanjing_silk:"))
	for n in nodes:
		if is_instance_valid(n):n.free()
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
	for def in [[MARKET,"비단 노점",[1120,680]],[CHEST,"주씨의 천 상자",[850,618]]]:
		var point=w.city_point(def[2]);var node: Node2D
		if def[0]==CHEST:
			for scenery in w.scenery_nodes:
				if scenery.name=="silk_cloth_chest":node=scenery;point=scenery.position;break
		else:
			for scenery in w.scenery_nodes:
				if scenery.name=="capital_2":node=scenery;point=scenery.position;break
		if node==null:continue
		if is_target(def[0]):
			var mark=UI.label(w.decorations,"◆",Rect2(point+Vector2(-40,-110),Vector2(80,92)),68,Color("ffcf69"));mark.set_meta("hud_anchor",point);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mark.z_index=6;nodes.append(mark)
		w.objectives.append({"id":def[0],"goal_id":def[0],"name":def[1],"position":point,"node":node,"frame":-1,"important":is_target(def[0])})
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:transition_revision+=1;phase=value.get("phase","available");signature="";refresh_world()
