extends Node
## Presentation only. Never changes acceptance, tracking, interaction or discovery.
const UI=preload("res://scripts/ui.gd")
var game
var labels: Array[Label]=[]
var dirty=true
var revision=-1
var name_styles: Dictionary={}
var rendered_names: Array[Label]=[]
var rendered_badges: Array[Label]=[]
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	process_priority=100
	for chosen in [false,true]:
		var style=StyleBoxFlat.new()
		style.bg_color=Color("10221dee") if chosen else Color.TRANSPARENT
		style.border_color=Color("e7c98b") if chosen else Color.TRANSPARENT
		style.set_border_width_all(1 if chosen else 0);style.set_corner_radius_all(3)
		style.content_margin_left=6;style.content_margin_right=6
		name_styles[chosen]=style
	get_tree().node_added.connect(_added)
func _added(node: Node) -> void:
	if node is Label and is_instance_valid(game.exploration) and game.exploration.is_ancestor_of(node):dirty=true
func _scan(node: Node) -> void:
	if node is Label:labels.append(node)
	for child in node.get_children():_scan(child)
func _process(_delta: float) -> void:refresh()
func primary_goal() -> String:
	if game.alliance_story.stage_id not in ["dormant","completed"]:
		return game.quest_navigation.definitions[game.alliance_story.ID].stages[game.alliance_story.stage()].label
	if game.bandit_story.stage not in ["dormant","completed"]:
		return {"offered":"관아에서 토벌 모집 내용 확인하기","preparing":"집결 포졸에게 출발 용무 전하기","report":"관아에서 토벌 보수 받기"}.get(game.bandit_story.stage,"토벌대와 함께 산적 토벌하기")
	if game.chapter_number==1 and game.exploration.area_name=="changsha" and game.bandit_story.stage=="dormant":return "장사를 탐사하세요"
	return ""
func refresh() -> void:
	var w=game.exploration
	if dirty or revision!=w.load_revision:
		labels.clear();_scan(w.decorations);dirty=false;revision=w.load_revision
	labels=labels.filter(func(n):return is_instance_valid(n))
	var exploring=game.state=="explore" and w.active and game.dialogue_lines.is_empty() and not get_tree().paused
	game.compact_toolbar.visible=exploring
	if not exploring:w.hint.hide()
	if game.state=="explore":game.bottom_hint.hide()
	var goal: Dictionary=game.quest_navigation.get_goal(w)
	if exploring and w.area_name not in ["dock","deck"]:_objective(goal)
	elif w.area_name in ["dock","deck"]:
		game.objective_meta.text="Q 의뢰 일지 · F2 조작 안내";game.chapter_goal.hide()
	var target: Dictionary=w.nearest() if exploring else {}
	_names(exploring,target)
	_markers(exploring,goal)
	if exploring and w.hint.visible:_hint(target)
func _objective(goal: Dictionary) -> void:
	game.location.text=game.exploration.city_data.name+" · "+game.exploration.district_at_player()
	var main=primary_goal()
	var side=not goal.is_empty() and goal.get("quest_id","") not in [game.bandit_story.QUEST_ID,game.alliance_story.ID]
	game.chapter_goal.visible=not main.is_empty() and side
	game.chapter_goal.text="주요 이야기 · "+main
	game.chapter_goal.add_theme_font_size_override("font_size",11)
	game.chapter_goal.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	game.chapter_goal.tooltip_text=game.chapter_goal.text
	game.quest_heading.position.y=28 if game.chapter_goal.visible else 9
	game.objective.position.y=51 if game.chapter_goal.visible else 38
	game.objective.size=Vector2(258,43)
	game.objective_meta.position.y=95
	game.objective_meta.add_theme_font_size_override("font_size",10)
	game.quest_heading.text=goal.quest_title if not goal.is_empty() else "주요 목표" if not main.is_empty() else "강호행"
	game.objective.text=str(goal.label).split(" · ")[0] if not goal.is_empty() else main if not main.is_empty() else "주변을 둘러보고 사람들과 이야기하기"
	var other=not goal.is_empty() and (str(goal.label).contains("나가기") or str(goal.label).contains("이동") or str(goal.label).contains("돌아가기"))
	if not goal.is_empty():
		for exit in game.exploration.travel_exits:
			if exit.position.distance_to(goal.position)<150:other=true;break
	game.objective_meta.text=("다른 지역으로 이동" if other else game.save_system.area_name(game.exploration.area_name))+" · Q 의뢰 일지"
	game.objective.tooltip_text=game.quest_heading.text+"\n"+game.objective.text+"\n"+game.objective_meta.text
func _actors() -> Array:
	var actors: Array=game.exploration.ambient_nodes.duplicate()
	for entry in game.exploration.npcs:
		if entry.frame>=0:actors.append(entry.node)
	return actors.filter(func(n):return is_instance_valid(n))
func _names(exploring: bool,target: Dictionary) -> void:
	var w=game.exploration
	var actors=_actors();rendered_names.clear()
	actors.sort_custom(func(a,b):
		if a==b:return false
		if a.get_meta("npc_id","")==target.get("id","-"):return true
		if b.get_meta("npc_id","")==target.get("id","-"):return false
		return a.global_position.distance_squared_to(w.player.global_position)<b.global_position.distance_squared_to(w.player.global_position))
	var used: Array[Rect2]=[]
	for actor in actors:
		var tag: Label=actor.get_meta("nameplate_label",null)
		if not is_instance_valid(tag):continue
		tag.visible=false
		var id: String=actor.get_meta("npc_id","")
		var chosen=id==target.get("id","-")
		tag.set_meta("interaction_selected",chosen and exploring)
		if not exploring or actor.position.distance_to(w.player.position)>240:continue
		if not target.is_empty() and not chosen and actor.position.distance_to(target.position)<200:continue
		var height=w.Metrics.PROLOGUE_HEIGHT if w.area_name in ["dock","deck"] else w.Metrics.CITIZEN_HEIGHT
		tag.position=Vector2(-109,-height-34);tag.size=Vector2(218,28)
		if not tag.has_meta("emphasis_applied") or bool(tag.get_meta("emphasis_applied"))!=chosen:
			tag.add_theme_stylebox_override("normal",name_styles[chosen])
			tag.add_theme_font_size_override("font_size",16 if chosen else 15)
			tag.set_meta("emphasis_applied",chosen)
		tag.text=str(actor.get_meta("display_name",tag.text))+ (" · "+str(actor.get_meta("hud_role")) if actor.has_meta("hud_role") else "")
		tag.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		tag.add_theme_color_override("font_color",UI.GOLD if chosen else UI.TEXT)
		var bounds=tag.get_global_rect().grow(8)
		var overlap=false
		for rect in used:
			if bounds.intersects(rect):overlap=true;break
		if overlap:continue
		used.append(bounds);tag.visible=true;rendered_names.append(tag)
func _anchor(mark: Label) -> Dictionary:
	var w=game.exploration
	if mark.has_meta("hud_anchor"):return {"position":mark.get_meta("hud_anchor"),"height":0.0}
	for group in [game.ordinary_quests.marks,game.ordinary_quests.target_marks]:
		for id in group:
			if group[id]==mark:
				for npc in w.ambient_nodes:
					if npc.get_meta("npc_id","")==id:return {"position":npc.position,"height":w.Metrics.CITIZEN_HEIGHT}
	var parent=mark.get_parent()
	while is_instance_valid(parent) and parent!=w.decorations:
		for npc in _actors():
			if parent==npc:return {"position":npc.position,"height":w.Metrics.CITIZEN_HEIGHT}
		for entry in w.objectives:
			if parent==entry.node:return {"position":entry.position,"height":w.Metrics.CITIZEN_HEIGHT if entry.frame>=0 else 0.0}
		parent=parent.get_parent()
	return {}
func _markers(exploring: bool,goal: Dictionary) -> void:
	rendered_badges.clear();var used: Array[Rect2]=[];var w=game.exploration
	for mark in labels:
		if not mark.get_meta("quest_marker",false):continue
		var symbol=mark.text
		if symbol.is_empty():mark.visible=false;continue
		var anchor=_anchor(mark)
		var show=exploring
		if symbol.begins_with("◆"):
			show=show and not goal.is_empty() and not anchor.is_empty() and anchor.position.distance_to(goal.position)<120
		mark.visible=show
		if not show:continue
		# Quest-giver symbols keep their size, even when their name is hidden.
		if symbol in ["!","?"] and not anchor.is_empty():
			var origin: Vector2=w.to_global(anchor.position)+Vector2(-40,-float(anchor.height)-126)
			mark.global_position=origin;mark.size=Vector2(80,92)
			for attempt in range(8):
				var overlap=false
				for rect in used:
					if mark.get_global_rect().grow(3).intersects(rect):overlap=true;break
				if not overlap:break
				mark.global_position=origin+Vector2(84*(attempt/2+1)*(1 if attempt%2==0 else -1),0)
			used.append(mark.get_global_rect().grow(3))
		rendered_badges.append(mark)
func _hint(target: Dictionary) -> void:
	var w=game.exploration
	w.indicator.set_body_height(0.0)
	if target.is_empty():return
	var action="이동" if target.has("travel") else "조사" if str(target.id).begins_with("quest_goal:") or target.frame<0 else "거래" if target.has("service_id") else "대화"
	if target.id=="boarding":action="승선"
	if target.has("travel") and not preload("res://scripts/overland_travel.gd").blocked_reason(game,target.travel.area).is_empty():action="통행 확인"
	w.hint.text="F · "+str(target.name)+" · "+action
	w.hint.size=Vector2(320,29);w.hint.position=Vector2(target.position.x-160,maxf(target.position.y,w.player.position.y)+20);w.hint.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var transform=w.get_canvas_transform();var point=transform*w.hint.position
	var screen=w.get_viewport_rect().size;var span=w.hint.size*w.camera.zoom
	point=point.clamp(Vector2(12,195),screen-span-Vector2(12,56))
	w.hint.position=transform.affine_inverse()*point
