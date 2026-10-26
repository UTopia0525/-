extends Node
const ID="nanjing_waterfront"
const GIVER="nj_boatman"
const WITNESS="nj_crowd_quay_guest"
const SUSPECT="nj_nochil"
const ROPE="quest_goal:nanjing_waterfront:rope"
const GRAIN="quest_goal:nanjing_waterfront:grain"
const UI=preload("res://scripts/ui.gd")
const Icons=preload("res://scripts/catalog_icons.gd")
const PHASES=["available","rope","grain","witness","confront","demand","battle","aftermath","handover","ready","completed"]
const TARGETS={"available":GIVER,"rope":ROPE,"grain":GRAIN,"witness":WITNESS,"confront":SUSPECT,"demand":SUSPECT,"battle":SUSPECT,"aftermath":SUSPECT,"handover":GIVER,"ready":GIVER,"completed":GIVER}
var game
var phase:="available"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/nanjing_waterfront_quest.json"))
var nodes: Array[Node]=[]
var signature:=""
var transition_revision:=0
func _ready() -> void:
	game.PORTRAITS.ACTORS[SUSPECT]={"name":"노칠","basic_portrait":"male_middle","portrait":"res://assets/portraits/archetypes/water-bandit.png"}
	var stages={}
	for pair in [["offer","뱃사공 오강에게 사라진 화물 이야기 듣기"],["rope","서쪽 하역장 배 옆 잘린 계선줄 조사"],["grain","줄 근처의 끌린 자루와 흘린 곡식 조사"],["witness","나루 손님 윤소영에게 목격담 듣기"],["confront","서쪽 창고 뒤편 노칠 제압 · 접근 시 즉시 교전"],["aftermath","제압된 노칠과 이야기하고 관아에 인계"],["report","오강에게 화물 확보와 인계 결과 보고"]]:stages[pair[0]]={"label":pair[1],"goals":[]}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func reset() -> void:transition_revision+=1;clear_world();phase="available";signature="";_caption_default()
func status() -> String:return "available" if phase=="available" else "ready" if phase=="ready" else "completed" if phase=="completed" else "active"
func stage() -> String:return {"available":"offer","demand":"confront","battle":"confront","handover":"aftermath","ready":"report","completed":"report"}.get(phase,phase)
func target() -> String:return TARGETS[phase]
func in_battle() -> bool:return phase=="battle"
func is_target(id: String) -> bool:return phase not in ["available","completed"] and id==target()
func marker_for(id: String) -> String:return "!" if id==GIVER and phase=="available" else "?" if id==GIVER and phase=="ready" else ""
func reward_label() -> String:return "보수 250문 · 실전 전투 있음 (패배 시 사망)"
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func journal_items() -> Array:
	var result=[]
	if phase not in ["available","rope","completed"]:result.append({"id":"waterfront_rope","name":"계선줄 조사 기록 · 매듭은 온전하고 남은 줄만 잘렸다"})
	if phase not in ["available","rope","grain","completed"]:result.append({"id":"waterfront_grain","name":"화물 조사 기록 · 끌린 자루와 흘린 곡식"})
	return result
func handle_interaction(id: String) -> bool:
	if game.exploration.area_name!="nanjing":return false
	if id==GIVER:
		match phase:
			"available":game.say(data.scenes.intro,_offer)
			"ready":game.say(data.scenes.report,_complete)
			"completed":game.say(data.scenes.post_giver)
			_:game.say(data.scenes.wait)
		return true
	if id==ROPE:
		if phase=="rope":game.say(data.scenes.rope,_advance)
		elif phase in ["ready","completed"]:game.say([["hero","새 계선줄이 단단히 묶여 있다. 오강은 다시 배를 띄울 준비를 하고 있다."]])
		else:game.say(data.scenes.early_rope)
		return true
	if id==GRAIN:
		if phase=="grain":game.say(data.scenes.grain,_advance)
		else:game.say([["hero","바닥에 곡식이 흘러 있다. 배 주인의 사정과 줄의 흔적부터 확인하자."]])
		return true
	if id==WITNESS:
		if phase=="witness":game.say(data.scenes.witness,_advance);return true
		if phase=="completed":game.say(data.scenes.post_witness);return true
	if id==SUSPECT:
		if phase=="confront":_confront();return true
		if phase=="aftermath":game.say(data.scenes.victory,_handover);return true
	return false
func _offer() -> void:game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+"\n목격담 뒤 창고의 범인에게 접근하면 곧바로 전투가 시작됩니다.","나루부터 살펴보겠소",accept,"지금은 다른 용무가 있소",decline)
func accept() -> void:
	if phase!="available":return
	_update("rope");game.say(data.scenes.accept)
func decline() -> void:game.say(data.scenes.decline)
func _update(next: String) -> void:
	phase=next;track();refresh_world();game.adventure_ui.notify("의뢰 갱신 · "+str(game.quest_navigation.definitions[ID].stages[stage()].label),"quest")
func _advance() -> void:
	var next={"rope":"grain","grain":"witness","witness":"confront"}
	if next.has(phase):_update(next[phase])
func _confront() -> void:
	if phase!="confront":return
	phase="demand";game.exploration.player.stop();game.say(data.scenes.confront,_start_battle)
func _start_battle() -> void:
	if phase!="demand":return
	phase="battle";game.start_battle(data.encounter)
func after_victory() -> void:
	if phase!="battle":return
	phase="aftermath";game.battle.hide();game.state="explore";game.exploration.show();game.exploration.camera.enabled=true
	game.exploration.camera.snap_to_player();game.top_hud.show();game.bottom_hint.text=UI.EXPLORATION_HINT;game.bottom_hint.show();game.music.play_track("dock")
	game.say(data.scenes.victory,_handover)
func _handover() -> void:
	if phase!="aftermath":return
	phase="handover";transition_revision+=1;var token=transition_revision
	game.state="story";game.exploration.set_active(false);game.dialogue_backdrop.show()
	game.story_caption.position=Vector2(40,305);game.story_caption.size=Vector2(1200,80);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.story_caption.text="잠시 뒤 · 관아에 노칠과 화물을 인계했다";game.story_caption.show()
	game.get_tree().create_timer(.7,false).timeout.connect(func():
		if token!=transition_revision or phase!="handover":return
		_update("ready");game.state="explore";game.story_caption.hide();_caption_default();game.say(data.scenes.handover))
func _caption_default() -> void:
	game.story_caption.position=Vector2(36,32);game.story_caption.size=Vector2(1200,45);game.story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
func _complete() -> void:
	if phase!="ready":return
	phase="completed";game.money+=250
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world();game.adventure_ui.notify("의뢰 완료 · 250문","coin")
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
var block_map
var blocks: Array[Rect2]=[]
var visuals: Array[Rect2]=[]
func clear_world() -> void:
	var w=game.exploration
	w.objectives=w.objectives.filter(func(o):return not str(o.id).begins_with("quest_goal:nanjing_waterfront:"))
	if is_instance_valid(block_map):
		for bounds in blocks:block_map.blockers.erase(bounds)
	blocks.clear()
	for bounds in visuals:w.scenery_bounds.erase(bounds)
	visuals.clear()
	for n in nodes:
		if not is_instance_valid(n):continue
		if n is Node2D:w.ambient_nodes.erase(n);w.scenery_nodes.erase(n);w.occlusion_roots.erase(n)
		n.free()
	nodes.clear()
func _navigation() -> void:
	var w=game.exploration
	if not is_instance_valid(w.regional_map):return
	w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _prop(id: String, title: String, point: Array, icon: String, solid: bool) -> void:
	var w=game.exploration;var node=preload("res://scripts/city_scenery.gd").new()
	var entry: Dictionary=Icons.entries[icon]
	node.configure({"id":id,"rect":[point[0]-16,point[1]-23,32,23]},{"texture":"res://assets/icons/waterfront-quest.png","source":entry.source,"kind":"cargo","footprints":[[.1,.7,.8,.28]] if solid else []},w.regional_map.world_scale)
	w.decorations.add_child(node);w.occlusion_roots.append(node);w.scenery_nodes.append(node);nodes.append(node)
	if solid:
		w.scenery_bounds.append(node.visual_rect);visuals.append(node.visual_rect);blocks.append_array(node.collision_rects);w.regional_map.blockers.append_array(node.collision_rects)
	if id==ROPE and phase in ["ready","completed"]:node.sprite.modulate=Color(1.15,1.08,.95)
	w.objectives.append({"id":id,"goal_id":id,"name":title,"position":node.position,"node":node,"frame":-1,"important":is_target(id)})
	if is_target(id):
		var mark=UI.label(node,"◆",Rect2(-40,-130,80,92),68,Color("ffcf69"));mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s" % [w.load_revision,w.area_name,phase]
	if signature==sig:return
	signature=sig;clear_world()
	if w.area_name!="nanjing":return
	block_map=w.regional_map
	_prop(ROPE,"새 계선줄" if phase in ["ready","completed"] else "잘린 계선줄",data.rope_point,"waterfront_rope",false)
	if phase not in ["ready","completed"]:_prop(GRAIN,"끌린 자루와 흘린 곡식",data.grain_point,"waterfront_grain",true)
	if phase in ["confront","demand","battle","aftermath"]:
		w._populate_residents([{"id":SUSPECT,"name":"노칠","role":"짐을 옮기는 사내","post":"짐을 옮기는 사내","point":data.suspect_point,"frame":4,"quest_actor":false,"show_name":true}])
		var actor=w.ambient_nodes.back();nodes.append(actor);var tag=w.occlusion_roots.pop_back();tag.reparent(actor);tag.position=Vector2.ZERO
	for a in w.ambient_nodes:
		var text=marker_for(a.get_meta("npc_id"))
		if text.is_empty():continue
		var mark=UI.label(a,text,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"));mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		mark.add_theme_color_override("font_outline_color",Color("2b2614"));mark.add_theme_constant_override("outline_size",5);nodes.append(mark)
	_navigation()
func _process(_delta: float) -> void:
	refresh_world()
	var w=game.exploration
	if phase!="confront" or w.area_name!="nanjing" or game.state!="explore" or not w.active or not game.dialogue_lines.is_empty():return
	if game.player_menu.visible or game.city_overview.visible or game.adventure_ui.window.visible or game.settings_menu.window.visible:return
	for a in w.ambient_nodes:
		if a.get_meta("npc_id")==SUSPECT and w.player.position.distance_to(a.position)<=170:_confront();return
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:transition_revision+=1;phase=value.get("phase","available");signature="";refresh_world()
