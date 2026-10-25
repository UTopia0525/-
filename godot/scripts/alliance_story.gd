extends Node
## Invitation -> verified visit -> steward -> one chosen intermediate technique.
const ID="alliance_main_visit"
const GIVER="song_jigyeom"
const ARTS=["hoeryu","paak","gwanak","banseok","jungun"]
const STAGES=["dormant","invitation","invited","steward","instructor","completed"]
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/alliance_story.json"))
var stage_id:="dormant"
var received_art:=""
var playing:=false
var vouching:=false
var pending_art:=""
var nodes: Array[Node]=[]
var signature:=""
func _ready() -> void:
	game.PORTRAITS.ACTORS[GIVER]={"name":"송지겸","basic_portrait":"male_young"}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":{
		"invitation":{"label":"장사에서 무림맹 사절 송지겸 만나기","goals":[]},
		"invited":{"label":"무창 북동쪽 무림맹 정문에서 방문 용무 전하기","goals":[]},
		"steward":{"label":"정문 안 왼편 총무당에서 허문규 만나기","goals":[]},
		"instructor":{"label":"본단 연무장의 곽진석에게 한 문 전수받기","goals":[]},
		"completed":{"label":"중급 무공 전수 완료 · K에서 초식 편성","goals":[]}}}
func reset() -> void:
	clear_world();stage_id="dormant";received_art="";playing=false;vouching=false;pending_art="";signature=""
func status() -> String:return "locked" if stage_id=="dormant" else "completed" if stage_id=="completed" else "active"
func stage() -> String:return "invitation" if stage_id=="dormant" else stage_id
func reward_label() -> String:return "중급 무공5종 중1종 전수 (금전·명성·호의도 추가 없음)"
func marker_for(_id: String) -> String:return ""
func is_target(id: String) -> bool:
	return (stage_id=="invited" and id in ["alliance_guard_left","alliance_guard_right"]) or (stage_id=="steward" and id=="heo_mungyu") or (stage_id=="instructor" and id=="gwak_jinseok")
func track() -> void:game.quest_navigation.track(ID,stage())
func can_play() -> bool:
	return game.state=="explore" and game.dialogue_lines.is_empty() and not game.get_tree().paused and not game.settings_menu.window.visible and not game.player_menu.visible and not game.city_overview.visible and not game.city_service.visible and not game.dialogue_history.visible and not game.adventure_ui.window.visible
func maybe_start() -> void:
	if not can_play() or playing:return
	if stage_id=="dormant" and game.bandit_story.stage=="completed" and game.bandit_story.reward_granted and game.alliance_visit.phase=="unverified":
		stage_id="invitation";track()
	if stage_id=="invitation" and game.exploration.area_name=="changsha":
		playing=true;refresh_world();game.say(data.scenes.invitation,_invited)
func _invited() -> void:
	if stage_id!="invitation":return
	stage_id="invited";playing=false;track();refresh_world();game.adventure_ui.notify("무림맹의 초대 · 편한 때 육로로 무창 방문","quest")
func handle_interaction(id: String) -> bool:
	var area: String=game.exploration.area_name
	if id==GIVER and stage_id=="invitation" and area=="changsha":playing=true;game.say(data.scenes.invitation,_invited);return true
	if area not in ["wuchang","alliance_office"]:return false
	if id in ["alliance_guard_left","alliance_guard_right"] and stage_id=="invited" and game.alliance_visit.phase=="unverified":
		begin_gate(id);return true
	if id=="heo_mungyu" and stage_id=="steward" and game.alliance_visit.admitted():
		game.say(game.alliance_visit.data.scenes.heo_visiting,_referred);return true
	if id=="gwak_jinseok" and stage_id=="instructor" and game.alliance_visit.phase=="visiting":
		game.say(game.alliance_visit.data.scenes.gwak_visiting,open_teaching);return true
	return false
func begin_gate(speaker: String="alliance_guard_left") -> void:
	if stage_id!="invited" or game.alliance_visit.phase!="unverified" or playing:return
	playing=true
	var lines: Array=data.scenes.guard_invited.duplicate(true)
	if speaker=="alliance_guard_right":
		for line in lines:
			if line[0]=="alliance_guard_left":line[0]="alliance_guard_right"
			elif line[0]=="alliance_guard_right":line[0]="alliance_guard_left"
	game.say(lines,_vouch)
func _vouch() -> void:
	if stage_id!="invited":return
	vouching=true;refresh_world();game.say(data.scenes.vouch,_admitted)
func _admitted() -> void:
	if stage_id!="invited":return
	if not game.alliance_visit.grant_visit():return
	stage_id="steward";playing=false;vouching=false;track();refresh_world();game.adventure_ui.notify("신원 확인 · 총무당 허문규에게 이동","quest")
func _referred() -> void:
	if stage_id!="steward":return
	stage_id="instructor";track();game.adventure_ui.notify("총관 면담 완료 · 본단 연무장 곽진석에게 이동","quest")
func open_teaching() -> void:
	if stage_id=="instructor" and game.alliance_visit.phase=="visiting":game.adventure_ui.open_teaching()
func confirm_art(id: String) -> void:
	if stage_id!="instructor" or game.alliance_visit.phase!="visiting" or id not in ARTS or id in game.progress.learned:return
	var art_name: String=game.progress.arts.get_skill(id).name
	game.adventure_ui.choose("전수 확인 · "+art_name,"이번 방문에서는 한 문만 배웁니다. "+art_name+"을 배우겠습니까?\n학습 능력치 제한은 없으며, 실전 사용에는 해당 무기와 내기가 필요합니다.","이 무공을 배우겠습니다",_teach.bind(id),"다른 무공도 살펴보겠습니다",open_teaching)
func _teach(id: String) -> void:
	if stage_id!="instructor" or game.alliance_visit.phase!="visiting" or id not in ARTS or id in game.progress.learned:return
	pending_art=id
	var lines: Array=data.scenes.teaching.duplicate(true)
	for line in lines:line[1]=str(line[1]).replace("{art}",str(game.progress.arts.get_skill(id).name))
	game.say(lines,_finish_teaching)
func _finish_teaching() -> void:
	if stage_id!="instructor" or pending_art not in ARTS or game.alliance_visit.phase!="visiting":return
	if pending_art not in game.progress.learned:game.progress.learned.append(pending_art)
	received_art=pending_art;pending_art="";stage_id="completed"
	game.alliance_visit.mark_training_complete()
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	game.adventure_ui.notify("무공 습득 · "+str(game.progress.arts.get_skill(received_art).name)+" · K에서 편성","learn")
	game.impostor_quest.refresh_world()
func goal(world) -> Dictionary:
	if stage_id in ["dormant","completed"]:return {}
	var point: Vector2;var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
	var toward_changsha: bool=stage_id=="invitation"
	if world.area_name=="changsha":
		point=world.player.position if toward_changsha else world.city_point([1490,510])
		if not toward_changsha:label="동쪽 농촌 포탈에서 무창 방면 산길로 이동"
	elif world.area_name=="mountain_road":point=world.city_point([80,1175] if toward_changsha else [740,64])
	elif world.area_name=="alliance_office":
		if stage_id=="steward":
			for npc in world.ambient_nodes:
				if npc.get_meta("npc_id")=="heo_mungyu":point=npc.position
		else:point=world.city_point([256,321]);label="총무당을 나와 본단 연무장으로 이동" if not toward_changsha else "총무당을 나와 장사로 이동"
	elif world.area_name=="wuchang":
		if toward_changsha:point=world.city_point([1100,1840]);label="남쪽 농촌 포탈에서 장사로 돌아가 사절 만나기"
		elif stage_id=="invited":
			for npc in world.ambient_nodes:
				if npc.get_meta("npc_id")=="alliance_guard_left":point=npc.position;break
		elif stage_id=="steward":point=world.city_point([1077,775])
		elif stage_id=="instructor":
			for npc in world.ambient_nodes:
				if npc.get_meta("npc_id")=="gwak_jinseok":point=npc.position
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func _navigation(points: Array) -> void:
	var w=game.exploration
	if is_instance_valid(w.regional_map):
		w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
	else:
		for point in points:
			var cell=Vector2i((point-w.astar.offset)/w.astar.cell_size)
			for y in range(cell.y-4,cell.y+5):
				for x in range(cell.x-4,cell.x+5):
					var id=Vector2i(x,y)
					if w.astar.is_in_boundsv(id):w.astar.set_point_solid(id,not w.can_stand(w.astar.get_point_position(id)))
func clear_world() -> void:
	var points=[]
	for node in nodes:
		if is_instance_valid(node):points.append(node.position);game.exploration.ambient_nodes.erase(node);node.free()
	nodes.clear()
	if not points.is_empty():_navigation(points)
func refresh_world() -> void:
	var w=game.exploration;var sig="%d:%s:%s:%s:%s" % [w.load_revision,w.area_name,stage_id,playing,vouching]
	if signature==sig:return
	signature=sig;clear_world()
	var point: Vector2
	if w.area_name=="changsha" and stage_id=="invitation" and playing:point=w.player.position+Vector2(-180,0)
	elif w.area_name=="wuchang" and stage_id=="invited" and vouching:point=w.city_point([1480,990])
	if point==Vector2.ZERO:return
	w._populate_residents([{"id":GIVER,"name":"송지겸","point":[point.x/4,point.y/4],"frame":4,"post":"무림맹 사절","quest_actor":true,"character_profile":{},"role":"무림맹 사절"}])
	var npc=w.ambient_nodes.back();nodes.append(npc)
	var tag=w.occlusion_roots.pop_back();tag.reparent(npc);tag.position=Vector2.ZERO
	_navigation([npc.position])
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"stage":stage_id,"received_art":received_art}
func valid(value) -> bool:
	return value is Dictionary and value.get("stage") in STAGES and (value.get("received_art") in ARTS if value.stage=="completed" else value.get("received_art")=="")
func restore(value: Dictionary) -> void:
	stage_id=value.get("stage","dormant");received_art=value.get("received_art","");playing=false;vouching=false;pending_art="";signature="";refresh_world()
