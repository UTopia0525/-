extends Node
const ID="nanjing_book"
const GIVER="nj_bookseller"
const SCHOLAR="nj_crowd_book_buyer"
const INSTRUCTOR="nj_instructor"
const INNKEEPER="nj_innkeeper"
const UI=preload("res://scripts/ui.gd")
const PHASES=["available","instructor","innkeeper","scholar","return_book","solution","copying","ready","completed"]
const TARGETS={"available":GIVER,"instructor":INSTRUCTOR,"innkeeper":INNKEEPER,"scholar":SCHOLAR,"return_book":GIVER,"solution":SCHOLAR,"copying":GIVER,"ready":GIVER,"completed":GIVER}
var game
var phase:="available"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_book_quest.json"))
var nodes: Array[Node]=[]
var signature:=""
var transition_revision:=0
func _ready() -> void:
	var stages={}
	for item in [["offer","서책거리 소학겸에게 사정 듣기"],["instructor","조원식 교관에게 진학명의 행방 묻기"],["innkeeper","하삼랑에게 객잔의 품팔이 서생 묻기"],["scholar","객잔 뒤편 진학명과 이야기"],["return_book","소학겸에게 젖은 책과 사정 전달"],["solution","진학명에게 필사로 책임질 방법 전하기"],["copying","필사와 정리가 끝나기를 기다리기"],["report","소학겸에게 돌아가 진학명과 함께 보고"]]:stages[item[0]]={"label":item[1],"goals":[]}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func reset() -> void:
	transition_revision+=1;clear_world();phase="available";signature="";_caption_default()
func status() -> String:return "available" if phase=="available" else "completed" if phase=="completed" else "ready" if phase=="ready" else "active"
func stage() -> String:return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)
func target() -> String:return TARGETS[phase]
func is_target(id: String) -> bool:return phase not in ["available","completed"] and id==target()
func marker_for(id: String) -> String:return "!" if id==GIVER and phase=="available" else "?" if id==GIVER and phase=="ready" else ""
func reward_label() -> String:return "보수 · 쇄랑도결 1권 (사용 시 중급 쇄랑도법 습득)"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func prepare_residents(entries: Array) -> void:
	for entry in entries:
		if entry.id==SCHOLAR:
			if phase not in ["ready","completed"]:entry.point=[1124,950]
			entry.show_name=true
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="nanjing":return false
	if id==INNKEEPER and game.nanjing_relief_quest.is_target(id):
		if phase=="innkeeper":game.adventure_ui.choose("하삼랑 · 객잔 주인","어느 용건을 물으시겠어요?","품팔이 서생 이야기",_talk_target,"육소전의 행방",_talk_relief);return true
		return false
	if id==INSTRUCTOR and phase in ["instructor","completed"]:
		game.adventure_ui.choose("조원식 · 교관","서생 이야기 또는 무공 전수를 고르세요.","빌려준 책 이야기",_talk_instructor,"무공을 살펴본다",_trade);return true
	if id==GIVER:
		match phase:
			"available":game.say(data.scenes.intro,_offer)
			"return_book":game.say(data.scenes.return_book,_advance)
			"ready":game.say(data.scenes.report,_complete)
			"completed":game.say(data.scenes.post_giver)
			_:game.say(data.scenes.wait)
		return true
	if is_target(id):_talk_target();return true
	if id==SCHOLAR and phase in ["available","instructor","innkeeper"]:game.say(data.scenes.early_scholar);return true
	if phase=="completed" and id in [SCHOLAR,INNKEEPER]:game.say(data.scenes["post_scholar" if id==SCHOLAR else "post_innkeeper"]);return true
	return false
func _talk_target() -> void:
	if phase in ["instructor","innkeeper","scholar"]:game.say(data.scenes[phase],_advance)
	elif phase=="solution":game.say(data.scenes.solution,_begin_copy)
func _talk_instructor() -> void:
	if phase=="completed":game.say(data.scenes.post_instructor)
	else:_talk_target()
func _talk_relief() -> void:game.nanjing_relief_quest.handle_interaction(INNKEEPER)
func _trade() -> void:
	game.pending_service_id="city_instructor"
	for service in game.exploration.city_data.services:
		if service.id=="city_instructor":game.say(service.greeting_lines,game._service_done);return
func _offer() -> void:game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n책과 함께 돌아오지 않는 서생의 행방을 알아보세요.","서생을 찾아보겠소",accept,"지금은 다른 용무가 있소",decline)
func accept() -> void:
	if phase!="available":return
	_update("instructor");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _update(next: String) -> void:
	phase=next;track();refresh_world();game.adventure_ui.notify("의뢰 갱신 · "+str(game.quest_navigation.definitions[ID].stages[stage()].label),"quest")
func _advance() -> void:
	var next={"instructor":"innkeeper","innkeeper":"scholar","scholar":"return_book","return_book":"solution"}
	if next.has(phase):_update(next[phase])
func _begin_copy() -> void:
	if phase!="solution":return
	_update("copying");transition_revision+=1;var token=transition_revision
	game.state="story";game.exploration.set_active(false)
	game.story_caption.position=Vector2(40,305);game.story_caption.size=Vector2(1200,80);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.story_caption.text="잠시 뒤 · 서가에 다시 불이 켜졌다";game.story_caption.show();game.dialogue_backdrop.show()
	game.get_tree().create_timer(.85,false).timeout.connect(func():
		if token==transition_revision and phase=="copying":_finish_copy())
func _finish_copy() -> void:
	if phase!="copying":return
	_update("ready");game.state="explore";_caption_default();game.story_caption.hide()
	var w=game.exploration
	if w.area_name=="nanjing":
		var point: Vector2=w.player.position;w.load_area("nanjing");w.player.position=w.safe_player_position(point);w.camera.snap_to_player()
	game.say(data.scenes.after_copy)
func _caption_default() -> void:
	game.story_caption.position=Vector2(36,32);game.story_caption.size=Vector2(1200,45);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
func _complete() -> void:
	if phase!="ready":return
	if not game.progress.grant_manual("swaerang_manual"):return
	phase="completed"
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 쇄랑도결 1권 · I → 서적에서 사용","learn")
func goal(world) -> Dictionary:
	var point=Vector2.ZERO
	var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	if world.area_name=="nanjing":
		for a in world.ambient_nodes:
			if a.get_meta("npc_id")==target():point=a.position
	else:
		var exit_id: String={"changsha":"travel:road_east","mountain_road":"travel:wuchang","wuchang":"travel:qingya","alliance_office":"travel:office_exit","qingya_hamlet":"travel:nanjing","qingya_camp":"travel:hamlet"}.get(world.area_name,"")
		for exit in world.travel_exits:
			if exit.id==exit_id:point=exit.position;label="남경 의뢰를 위해 "+str(exit.name)+" 이동"
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func clear_world() -> void:
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
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:transition_revision+=1;phase=value.get("phase","available");signature="";refresh_world()
