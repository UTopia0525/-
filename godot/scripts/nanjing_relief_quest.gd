extends Node
## Optional Nanjing investigation. Fixed handover, once-only pay, then Lu's absence.
const ID="nanjing_relief"
const GIVER="lu_xiaozhuan"
const LADY="namgung_yeonseo"
const INNKEEPER="nj_innkeeper"
const UI=preload("res://scripts/ui.gd")
const PHASES=["available","resident","yeonseo","ledger","contact","witness","arrest","ready","inquiry","missing","completed"]
const TARGETS={"available":GIVER,"resident":"nj_grandmother","yeonseo":LADY,"ledger":"nj_clerk","contact":"jin_yulan","witness":"nj_he_mansik","arrest":"nj_zhao_desheng","ready":LADY,"inquiry":LADY,"missing":INNKEEPER,"completed":INNKEEPER}
var game
var phase:="available"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_relief_quest.json"))
var characters: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_characters.json")).npcs
var nodes: Array[Node]=[]
var signature:=""
func _ready() -> void:
	for entry in characters:
		var actor={"name":entry.name,"basic_portrait":entry.basic_portrait}
		if entry.has("portrait"):actor.portrait=entry.portrait
		game.PORTRAITS.ACTORS[entry.id]=actor
	for entry in JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_residents.json")).npcs:
		var actor={"name":entry.name,"basic_portrait":entry.basic_portrait}
		if entry.has("portrait"):actor.portrait=entry.portrait
		game.PORTRAITS.ACTORS[entry.id]=actor
	var stages={}
	var labels={"offer":"남경 객잔의 육소전에게 구휼 이야기 듣기","resident":"진회하 건너 위씨 할머니에게 배분 사정 묻기","yeonseo":"창고거리 남궁연서와 이야기하기","ledger":"창고 서리 윤문식에게 입출고 장부 확인","contact":"진회하 수변의 진옥란에게 허만식의 행방 묻기","witness":"남쪽 우물 부근의 허만식에게 증언 듣기","arrest":"북쪽 창고의 조덕승을 붙잡아 남궁가에 인계","report":"남궁연서에게 결과 보고·남궁가의 보상 받기","inquiry":"남궁연서의 육소전에 관한 의문 듣기","missing":"객잔 주인 하삼랑에게 육소전의 행방 묻기"}
	for id in labels:stages[id]={"label":labels[id],"goals":[]}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func eligible() -> bool:
	return game.alliance_story.stage_id=="completed" and game.alliance_story.received_art in game.progress.learned and game.alliance_visit.phase in ["training_complete","closed"]
func reset() -> void:clear_world();phase="available";signature=""
func status() -> String:
	if phase=="available":return "available" if eligible() else "locked"
	return "ready" if phase=="ready" else "completed" if phase=="completed" else "active"
func stage() -> String:return {"available":"offer","ready":"report","completed":"missing"}.get(phase,phase)
func target() -> String:return TARGETS[phase]
func is_target(id: String) -> bool:return phase not in ["available","completed"] and id==target()
func marker_for(id: String) -> String:
	return "!" if id==GIVER and status()=="available" else "?" if id==LADY and phase=="ready" else ""
func reward_label() -> String:return "보수 500문 · 남궁세가 호의도+10"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="nanjing":return false
	if id==GIVER:
		if not eligible():game.say(data.scenes.locked)
		elif phase=="available":game.say(data.scenes.intro,_offer)
		else:game.say(data.scenes.lu_wait)
		return true
	if phase not in ["available","completed"] and id==target():
		if phase=="inquiry":game.say(data.scenes.inquiry,_vanish)
		elif phase=="ready":game.say(data.scenes.report,_paid)
		else:game.say(data.scenes[phase],_advance)
		return true
	if id==LADY:
		if phase in ["missing","completed"]:game.say(data.scenes.yeonseo_post)
		elif phase in ["available","resident"]:game.say([[LADY,"제가 가문의 구휼 내역을 확인하고 있습니다. 소문보다 실제로 곡식을 받았는지가 중요하지요."]])
		else:game.say(data.scenes.yeonseo_wait)
		return true
	if id=="jin_yulan":game.say(data.scenes.jin_wait);return true
	if id==INNKEEPER and phase=="completed":game.say(data.scenes.post);return true
	return false
func _offer() -> void:
	if phase!="available" or not eligible():return
	game.adventure_ui.choose("의뢰 · "+str(data.title),"남궁의 구휼 물자가 주민들에게 전달되지 않는 까닭을 조사하세요.\n보상은 사건 해결 후 남궁세가에서 받습니다.","사정을 알아보겠소",accept,"지금은 다른 용무가 있소",decline)
func accept() -> void:
	if phase!="available" or not eligible():return
	phase="resident";track();refresh_world();game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _advance() -> void:
	var next={"resident":"yeonseo","yeonseo":"ledger","ledger":"contact","contact":"witness","witness":"arrest","arrest":"ready","missing":"completed"}
	if not next.has(phase):return
	phase=next[phase]
	if phase=="completed":
		if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	else:track()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 육소전의 행방은 알 수 없다" if phase=="completed" else "의뢰 갱신 · "+str(game.quest_navigation.definitions[ID].stages[stage()].label),"quest")
func _paid() -> void:
	if phase!="ready":return
	phase="inquiry";game.money+=int(data.reward.money)
	game.progress.add_favor(str(data.reward.faction),int(data.reward.favor))
	track();refresh_world();game.adventure_ui.notify("남궁가의 사례 · 500문 · 남궁세가 호의도+10","coin")
	game.say(data.scenes.inquiry,_vanish)
func _vanish() -> void:
	if phase!="inquiry":return
	phase="missing";track();refresh_world();game.adventure_ui.notify("육소전에게 돌아가 행방 확인","quest")
func goal(world) -> Dictionary:
	if status()=="locked":return {}
	var point=Vector2.ZERO
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="nanjing":
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id")==target():point=npc.position;break
	else:
		var exit_id: String={"changsha":"travel:road_east","mountain_road":"travel:wuchang","wuchang":"travel:qingya","alliance_office":"travel:office_exit","qingya_hamlet":"travel:nanjing","qingya_camp":"travel:hamlet"}.get(world.area_name,"")
		for exit in world.travel_exits:
			if exit.id==exit_id:point=exit.position;label="남경 의뢰를 위해 "+str(exit.name)+" 이동";break
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func clear_world() -> void:
	for node in nodes:
		if not is_instance_valid(node):continue
		if node is Node2D:game.exploration.ambient_nodes.erase(node)
		node.free()
	nodes.clear()
func _navigation() -> void:
	var w=game.exploration
	if not is_instance_valid(w.regional_map):return
	w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s:%s" % [w.load_revision,w.area_name,phase,status()]
	if signature==sig:return
	signature=sig;clear_world()
	if w.area_name!="nanjing":return
	_navigation()
	for original in characters:
		var entry: Dictionary=original.duplicate(true)
		if entry.id==GIVER and phase in ["missing","completed"]:continue
		if entry.id=="nj_he_mansik" and phase!="witness":continue
		if entry.id=="nj_zhao_desheng" and phase!="arrest":continue
		if entry.id==LADY and phase=="arrest":entry.point=[580,190]
		w._populate_residents([entry])
		var actor=w.ambient_nodes.back();nodes.append(actor)
		var tag=w.occlusion_roots.pop_back();tag.reparent(actor);tag.position=Vector2.ZERO
	for npc in w.ambient_nodes:
		var text=marker_for(npc.get_meta("npc_id"))
		if text.is_empty():continue
		var marker=UI.label(npc,text,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"))
		marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.add_theme_color_override("font_outline_color",Color("2b2614"));marker.add_theme_constant_override("outline_size",5);nodes.append(marker)
	_navigation()
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:phase=value.get("phase","available");signature="";refresh_world()
