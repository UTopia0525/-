extends Node
const ID="nanjing_levy"
const GIVER="nj_vendor"
const CLERK="nj_crowd_clerk_runner"
const GUARD="nj_constable"
const SUSPECT="nj_false_collector"
const UI=preload("res://scripts/ui.gd")
const PHASES=["available","clerk","description","suspect","report_guard","arrest","ready","completed"]
const TARGETS={"available":GIVER,"clerk":CLERK,"description":GIVER,"suspect":SUSPECT,"report_guard":GUARD,"arrest":SUSPECT,"ready":GIVER,"completed":GIVER}
var game
var phase:="available"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_levy_quest.json"))
var nodes: Array[Node]=[]
var table_blocks: Array[Rect2]=[]
var table_visual:=Rect2()
var signature:=""
var transition_revision:=0
func _ready() -> void:
	game.PORTRAITS.ACTORS[SUSPECT]={"name":"징수꾼","basic_portrait":data.suspect.basic_portrait}
	var stages={}
	for item in [["offer","노점상 정소복에게 자리세 이야기 듣기"],["clerk","관아 심부름꾼 장원에게 징수표 확인"],["description","정소복에게 징수꾼의 인상착의와 장소 묻기"],["suspect","시장 안쪽 징수꾼에게 자리세를 물어 확인"],["report_guard","포졸 장세평에게 위치와 발언 보고"],["arrest","장세평과 징수꾼의 현장 대질 확인"],["report","정소복에게 체포와 피해 진술 절차 전달"]]:stages[item[0]]={"label":item[1],"goals":[]}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func reset() -> void:transition_revision+=1;clear_world();phase="available";signature="";_caption_default()
func status() -> String:return "available" if phase=="available" else "ready" if phase=="ready" else "completed" if phase=="completed" else "active"
func stage() -> String:return {"available":"offer","ready":"report","completed":"report"}.get(phase,phase)
func target() -> String:return TARGETS[phase]
func is_target(id: String) -> bool:return phase not in ["available","completed"] and id==target()
func marker_for(id: String) -> String:return "!" if id==GIVER and phase=="available" else "?" if id==GIVER and phase=="ready" else ""
func reward_label() -> String:return "보수 200문 · 지출·전투 없음"
func journal_items() -> Array:return [{"id":"levy_receipt","name":"금액과 날짜가 빠진 징수표 · 증거 (판매/소비 불가)"}] if phase not in ["available","completed"] else []
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func prepare_residents(entries: Array) -> void:
	if phase!="arrest":return
	for entry in entries:
		if entry.id==GUARD:entry.point=[938,300]
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="nanjing":return false
	if id==GIVER and game.silk_quest.phase in ["vendor","completed"]:
		if phase=="completed":return false
		game.adventure_ui.choose("정소복 · 노점상","어느 용건부터 이야기할까요?","자리세 징수 이야기",_talk_giver,"비단 구할 곳",_talk_silk);return true
	if id==GIVER:_talk_giver();return true
	if id==SUSPECT:
		if phase=="suspect":game.say(data.scenes.suspect,_advance)
		elif phase=="arrest":game.say(data.scenes.arrest,_arrest_done)
		else:game.say(data.scenes.early_suspect)
		return true
	if is_target(id):
		game.say(data.scenes[phase],_begin_arrest if phase=="report_guard" else _advance);return true
	if phase=="completed" and id in [CLERK,GUARD]:game.say(data.scenes["post_clerk" if id==CLERK else "post_guard"]);return true
	return false
func _talk_giver() -> void:
	match phase:
		"available":game.say(data.scenes.intro,_offer)
		"description":game.say(data.scenes.description,_advance)
		"ready":game.say(data.scenes.report,_complete)
		"completed":game.say(data.scenes.post_giver)
		_:game.say(data.scenes.wait)
func _talk_silk() -> void:game.silk_quest.handle_interaction(GIVER)
func _offer() -> void:game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n관의 이름으로 거둔 자리세가 정당한지 확인하세요.","관아에 확인해 보겠소",accept,"지금은 다른 용무가 있소",decline)
func accept() -> void:
	if phase!="available":return
	_update("clerk");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _update(next: String) -> void:
	phase=next;track();refresh_world();game.adventure_ui.notify("의뢰 갱신 · "+str(game.quest_navigation.definitions[ID].stages[stage()].label),"quest")
func _advance() -> void:
	var next={"clerk":"description","description":"suspect","suspect":"report_guard"}
	if next.has(phase):_update(next[phase])
func _begin_arrest() -> void:
	if phase!="report_guard":return
	phase="arrest";track();transition_revision+=1;var token=transition_revision
	game.state="story";game.exploration.set_active(false)
	game.story_caption.position=Vector2(40,305);game.story_caption.size=Vector2(1200,80);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.story_caption.text="잠시 뒤 · 시장 안쪽";game.story_caption.show();game.dialogue_backdrop.show()
	game.get_tree().create_timer(.65,false).timeout.connect(func():
		if token!=transition_revision or phase!="arrest":return
		_reload_market(true);game.state="explore";_caption_default();game.story_caption.hide();game.say(data.scenes.arrest,_arrest_done))
func _arrest_done() -> void:
	if phase!="arrest":return
	_update("ready");_reload_market(false)
func _reload_market(at_scene: bool) -> void:
	var w=game.exploration
	if w.area_name!="nanjing":return
	var point: Vector2=w.city_point([960,333]) if at_scene else w.player.position
	w.load_area("nanjing")
	if at_scene:
		for a in w.ambient_nodes:
			if a.get_meta("npc_id")==SUSPECT:
				var path=w.path_to(a.position,true)
				if not path.is_empty():point=path[-1]
	w.player.position=w.safe_player_position(point);w.camera.snap_to_player()
func _caption_default() -> void:
	game.story_caption.position=Vector2(36,32);game.story_caption.size=Vector2(1200,45);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=200
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 200문","coin")
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
var block_map
func clear_world() -> void:
	var w=game.exploration
	if is_instance_valid(block_map):
		for bounds in table_blocks:block_map.blockers.erase(bounds)
	table_blocks.clear()
	w.scenery_bounds.erase(table_visual)
	for n in nodes:
		if not is_instance_valid(n):continue
		if n is Node2D:
			w.ambient_nodes.erase(n);w.scenery_nodes.erase(n);w.occlusion_roots.erase(n)
		n.free()
	nodes.clear()
func _navigation() -> void:
	var w=game.exploration
	if not is_instance_valid(w.regional_map):return
	w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s" % [w.load_revision,w.area_name,phase]
	if signature==sig:return
	signature=sig;clear_world()
	if w.area_name!="nanjing":return
	if phase not in ["ready","completed"]:
		var table=preload("res://scripts/city_scenery.gd").new()
		table.configure({"id":"levy_collection_desk","rect":[985,270,45,46]},{"texture":"res://assets/icons/levy-quest.png","source":[730,115,790,820],"kind":"stall","footprints":[[.12,.60,.76,.37]]},w.regional_map.world_scale)
		w.decorations.add_child(table);w.occlusion_roots.append(table);nodes.append(table);w.scenery_nodes.append(table);w.scenery_bounds.append(table.visual_rect)
		table_visual=table.visual_rect;block_map=w.regional_map;table_blocks.assign(table.collision_rects);block_map.blockers.append_array(table_blocks)
		w._populate_residents([data.suspect.duplicate(true)])
		var actor=w.ambient_nodes.back();nodes.append(actor)
		var tag=w.occlusion_roots.pop_back();tag.reparent(actor);tag.position=Vector2.ZERO
	for a in w.ambient_nodes:
		var text=marker_for(a.get_meta("npc_id"))
		if text.is_empty():continue
		var mark=UI.label(a,text,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"));mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		mark.add_theme_color_override("font_outline_color",Color("2b2614"));mark.add_theme_constant_override("outline_size",5);nodes.append(mark)
	_navigation()
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:transition_revision+=1;phase=value.get("phase","available");signature="";refresh_world()
