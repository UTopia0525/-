extends Node
## Independent errands, explicit acceptance and report-time, exactly-once rewards.
const UI = preload("res://scripts/ui.gd")
var game
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/normal_quests.json"))
var records: Dictionary = {}
var pending: Dictionary = {}
var marks: Dictionary = {}
var goal_nodes: Array[Node2D] = []
var revision := -1

func _ready() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/changsha/layout.json"))
	# Old dialogue saves may still name a retired bystander; never respawn their map body.
	for id in layout.get("retired_actor_names",{}):game.PORTRAITS.ACTORS[id]=layout.retired_actor_names[id].duplicate()
	var explicit = {"vegetable_vendor":"female_middle","warehouse_assistant":"female_young","well_grandmother":"female_elder","waterway_farmer":"female_common_a","waiting_father":"male_elder","warehouse_keeper":"male_elder","travelling_merchant":"male_common_b","dock_worker":"male_common_a"}
	for npc in layout.residents:
		if not game.PORTRAITS.ACTORS.has(npc.id): game.PORTRAITS.ACTORS[npc.id] = {"name":npc.name,"extra":explicit.get(npc.id,"female_middle" if npc.frame==5 else "male_young" if npc.frame==7 else "male_middle")}
		if npc.has("character_profile"):
			game.PORTRAITS.ACTORS[npc.id].name=npc.name
			game.PORTRAITS.ACTORS[npc.id].basic_portrait=npc.character_profile.basic_portrait

func reset() -> void:
	records.clear();pending.clear();clear_world();revision=-1

func status(id: String) -> String: return records.get(id,{}).get("status","available")
func stage_for(id: String) -> String:
	if status(id) in ["ready","completed"]: return "report"
	for stage in definitions[id].stages:
		for goal in game.quest_navigation.definitions[id].stages[stage].goals:
			if goal.id not in records.get(id,{}).get("done",[]): return stage
	return "report"
func sync_navigation(id: String) -> void:
	if status(id)=="completed":
		if game.quest_navigation.quest_id==id:game.quest_navigation.clear()
	elif status(id)!="available":game.quest_navigation.track(id,stage_for(id),records[id].done)
func accept(id: String) -> void:
	if status(id)!="available":return
	records[id]={"status":"active","done":[],"branch":""}
	sync_navigation(id);game.adventure_ui.notify("의뢰 수락 · "+game.quest_navigation.definitions[id].title,"quest")
	game.say(definitions[id].accept)
func choose_offer(accepted: bool, id: String) -> void:
	pending.clear()
	if accepted:accept(id)
	else:game.say(definitions[id].decline)
func choose_family(branch: String, id: String) -> void:
	if status(id)!="ready":return
	records[id].branch=branch;pending={"op":"complete","id":id}
	game.say(definitions[id]["branch_a" if branch=="A" else "branch_b"],_after_dialogue)
func handle_interaction(npc: String) -> bool:
	if npc.begins_with("quest_goal:"):
		var parts=npc.split(":");return interact_goal(parts[1],parts[2]) if parts.size()==3 else false
	for id in definitions:
		if definitions[id].giver==npc and status(id)=="ready":
			if id=="changsha_family":
				game.adventure_ui.choose("어떻게 안부를 전할까", "두 선택의 보상은 같습니다. 전할 말의 무게를 고르세요.","형편까지 그대로 전한다",choose_family.bind("A",id),"안부를 중심으로 전한다",choose_family.bind("B",id))
			else:
				pending={"op":"complete","id":id};game.say(definitions[id].report,_after_dialogue)
			return true
	for id in definitions:
		if status(id)!="active":continue
		for goal in game.quest_navigation.definitions[id].stages[stage_for(id)].goals:
			if goal.get("npc_id","")==npc and goal.id not in records[id].done:return interact_goal(id,goal.id)
	for id in definitions:
		if definitions[id].giver!=npc:continue
		match status(id):
			"available":pending={"op":"offer","id":id};game.say(definitions[id].intro,_after_dialogue)
			"active":game.say(definitions[id].progress)
			"completed":
				var post: Array=definitions[id].get("post_"+str(records[id].branch).to_lower(),definitions[id].post)
				post=post.filter(func(line):return line[0]==npc or line[0]=="hero")
				game.say(post if not post.is_empty() else [[npc,"덕분에 한시름 놓았네. 강호 길에 평안이 있기를."]])
		return true
	for id in definitions:
		if status(id)!="completed":continue
		var post: Array=definitions[id].get("post_"+str(records[id].branch).to_lower(),definitions[id].post)
		post=post.filter(func(line):return line[0]==npc)
		if not post.is_empty():game.say(post);return true
	return false
func interact_goal(id: String, goal: String) -> bool:
	if not definitions.has(id) or status(id)!="active" or goal in records[id].done:return false
	var allowed:=false
	for entry in game.quest_navigation.definitions[id].stages[stage_for(id)].goals:
		if entry.id==goal:allowed=true
	if not allowed:return false
	pending={"op":"goal","id":id,"goal":goal};game.say(definitions[id].steps[goal],_after_dialogue);return true
func _after_dialogue() -> void:
	if pending.is_empty():return
	var work: Dictionary=pending.duplicate();pending.clear();var id: String=work.id
	match work.op:
		"offer":game.adventure_ui.choose("의뢰 · "+game.quest_navigation.definitions[id].title,"보수 %d문 · 오성+5\n다른 일반 의뢰와 독립적으로 받을 수 있습니다." % int(game.trade_intro.rewards.quests[id].money),"맡는다",choose_offer.bind(true,id),"나중에 온다",choose_offer.bind(false,id))
		"goal":
			if status(id)!="active" or work.goal in records[id].done:return
			records[id].done.append(work.goal)
			if stage_for(id)=="report":records[id].status="ready"
			if game.quest_navigation.quest_id==id:sync_navigation(id)
			game.adventure_ui.notify("의뢰 갱신 · "+game.quest_navigation.definitions[id].title,"quest")
		"complete":
			if status(id)!="ready":return
			var reward: Dictionary=game.trade_intro.rewards.quests[id]
			var before: int=game.progress.stats.insight
			game.money+=int(reward.money);game.progress.stats.insight=mini(100,before+int(reward.stat_gains.insight))
			records[id].status="completed";sync_navigation(id)
			game.adventure_ui.notify("의뢰 완료 · %d문 · 오성+%d" % [int(reward.money),int(game.progress.stats.insight)-before],"quest")
	refresh_world()
func is_target(npc: String) -> bool:
	if is_instance_valid(game.artisan_quest) and game.artisan_quest.is_target(npc):return true
	for id in definitions:
		if status(id)!="active":continue
		for goal in game.quest_navigation.definitions[id].stages[stage_for(id)].goals:
			if goal.get("npc_id","")==npc:return true
	return false
func marker_for(npc: String) -> String:
	for quest in game.regional_quests():
		if is_instance_valid(quest) and npc==quest.GIVER:return quest.marker_for(npc)
	for id in definitions:
		if definitions[id].giver==npc:
			return "?" if status(id)=="ready" else "!" if status(id) in ["available","active"] else ""
	if npc=="bandit_officer":return "?" if game.bandit_story.stage=="report" else "!" if game.bandit_story.stage=="offered" else ""
	return "!" if npc=="bandit_muster" and game.bandit_story.stage=="preparing" else ""
func clear_world() -> void:
	for mark in marks.values():
		if is_instance_valid(mark):mark.free()
	marks.clear()
	for node in goal_nodes:
		if is_instance_valid(node):node.free()
	goal_nodes.clear()
	if is_instance_valid(game.exploration):game.exploration.objectives=game.exploration.objectives.filter(func(e):return not str(e.id).begins_with("quest_goal:changsha_"))
func refresh_world() -> void:
	var world=game.exploration
	if revision!=world.load_revision:
		clear_world();revision=world.load_revision
		if world.has_meta("quest_signature"):world.remove_meta("quest_signature")
	if world.area_name!="changsha":return
	for npc in world.ambient_nodes:
		var id: String=npc.get_meta("npc_id")
		if not marks.has(id):
			var mark=UI.label(world.decorations,"",Rect2(0,0,40,46),34,Color("ffe14b"));mark.z_index=6;mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			mark.add_theme_color_override("font_outline_color",Color("2b2614"));mark.add_theme_constant_override("outline_size",5);marks[id]=mark
		marks[id].position=npc.position+Vector2(-20,-world.Metrics.CITIZEN_HEIGHT-world.Metrics.QUEST_GAP-(world.Metrics.NAME_GAP if npc.get_meta("show_name",false) else 0.0));marks[id].text=marker_for(id);marks[id].visible=not str(marks[id].text).is_empty()
	# Rebuild investigation markers only when the stage/completion signature changes.
	var signature:=JSON.stringify(records)
	if world.get_meta("quest_signature","")==signature:return
	world.set_meta("quest_signature",signature)
	for node in goal_nodes:
		if is_instance_valid(node):node.free()
	goal_nodes.clear();world.objectives.clear()
	for id in definitions:
		if status(id)!="active":continue
		for goal in game.quest_navigation.definitions[id].stages[stage_for(id)].goals:
			if not goal.has("point") or goal.id in records[id].done:continue
			var node=Node2D.new();node.position=world.safe_player_position(world.city_point(goal.point));node.z_index=2
			var mark=UI.label(node,"◆",Rect2(-15,-24,30,30),24,UI.GOLD);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			world.decorations.add_child(node);goal_nodes.append(node)
			world.objectives.append({"id":"quest_goal:"+id+":"+goal.id,"goal_id":goal.id,"name":"의뢰 조사 지점","node":node,"position":node.position,"frame":-1})
func _process(_delta: float) -> void:refresh_world()
func snapshot() -> Dictionary:return {"records":records.duplicate(true),"pending":pending.duplicate(true)}
func valid(data) -> bool:
	if not data is Dictionary or not data.get("records") is Dictionary or not data.get("pending",{}) is Dictionary:return false
	for id in data.records:
		if not definitions.has(id):return false
		var r=data.records[id]
		if not r is Dictionary or r.get("status") not in ["active","ready","completed"] or r.get("branch") not in ["","A","B"] or not r.get("done") is Array:return false
		for goal in r.done:
			if not goal is String or not definitions[id].steps.has(goal) or r.done.count(goal)!=1:return false
		var all_done: bool=r.done.size()==definitions[id].steps.size()
		if all_done!=(r.status in ["ready","completed"]):return false
	var work=data.get("pending",{})
	return work.is_empty() or (definitions.has(work.get("id")) and work.get("op") in ["offer","goal","complete"] and (work.op!="goal" or definitions[work.id].steps.has(work.get("goal"))))
func restore(data: Dictionary) -> void:
	reset();records=data.get("records",{}).duplicate(true);pending=data.get("pending",{}).duplicate(true);refresh_world()
