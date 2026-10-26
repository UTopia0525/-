extends Node
## Tracks an explicitly supplied quest stage; does not accept or complete quests.
signal target_changed
var definitions: Dictionary
var facility_id:=""
var quest_id := ""
var stage_id := ""
var completed_goal_ids: Array[String] = []

func _ready() -> void:
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/changsha_navigation.json"))

func track(id: String, stage: String, completed: Array = []) -> bool:
	if not definitions.has(id) or not definitions[id].stages.has(stage):
		return false
	facility_id=""
	quest_id = id
	stage_id = stage
	completed_goal_ids.assign(completed)
	target_changed.emit()
	return true

func clear() -> void:
	facility_id=""
	quest_id = ""
	stage_id = ""
	completed_goal_ids.clear()
	target_changed.emit()

func update_quest(id: String, stage: String, completed: Array = []) -> bool:
	# Preserve the player's chosen quest or facility while other errands progress.
	if not facility_id.is_empty() or (not quest_id.is_empty() and quest_id != id): return false
	return track(id,stage,completed)

func get_goal(world) -> Dictionary:
	if not facility_id.is_empty() and world.area_name in ["changsha","wuchang","nanjing"]:
		for npc in world.ambient_nodes:
			if npc.get_meta("service_id","")==facility_id:return {"position":npc.position,"label":npc.get_meta("display_name")+"에게 이동","quest_title":"시설 안내","goal_id":facility_id,"quest_id":"","stage_id":"facility"}
	if not quest_id.is_empty() and quest_id!="qingya_village" and world.area_name=="qingya_camp" and get_parent().qingya_quest.inside_fence():
		for entry in world.objectives:
			if entry.id=="qingya_stealth:exit":return {"position":entry.position,"label":"목책 틈으로 빠져나간 뒤 산촌으로 이동","quest_title":definitions[quest_id].title,"goal_id":entry.id,"quest_id":quest_id,"stage_id":stage_id}
	for quest in get_parent().regional_quests():
		if is_instance_valid(quest) and quest_id==quest.ID:
			var goal: Dictionary=quest.goal(world)
			if not goal.is_empty() or world.area_name not in ["qingya_hamlet","qingya_camp","nanjing"]:return goal
			for exit in world.travel_exits:
				if exit.id==("travel:wuchang" if world.area_name=="qingya_hamlet" else "travel:hamlet"):
					return {"position":exit.position,"label":"기존 의뢰를 위해 "+exit.name+" 이동","quest_title":definitions[quest_id].title,"goal_id":exit.id,"quest_id":quest_id,"stage_id":stage_id}
			return {}
	if quest_id.is_empty():return {}
	if world.area_name != "changsha":
		var exit_id: String={"wuchang":"travel:road_south","mountain_road":"travel:changsha","alliance_office":"travel:office_exit","qingya_hamlet":"travel:wuchang","qingya_camp":"travel:hamlet","nanjing":"travel:hamlet"}.get(world.area_name,"")
		for exit in world.travel_exits:
			if exit.id==exit_id:return {"position":exit.position,"label":"장사 의뢰를 위해 "+exit.name+" 이동","quest_title":definitions[quest_id].title,"goal_id":exit_id,"quest_id":quest_id,"stage_id":stage_id}
		return {}
	var effective_stage = stage_id
	var stage: Dictionary = definitions[quest_id].stages[effective_stage]
	var all_done = not stage.goals.is_empty()
	for goal in stage.goals:
		if not completed_goal_ids.has(str(goal.id)):
			all_done = false
	if all_done and effective_stage != "report" and definitions[quest_id].stages.has("report"):
		effective_stage = "report"
		stage = definitions[quest_id].stages[effective_stage]
	var best: Dictionary = {}
	var distance := INF
	for goal in stage.goals:
		if completed_goal_ids.has(str(goal.id)):
			continue
		var point: Vector2
		if goal.has("npc_id"):
			var found := false
			for citizen in world.ambient_nodes:
				if citizen.get_meta("npc_id", "") == goal.npc_id:
					point = citizen.position
					found = true
					break
			if not found:
				continue
		else:
			point = world.city_point(goal.point)
			for entry in world.objectives:
				if entry.goal_id==goal.id:point=entry.position;break
		var candidate: float = world.player.position.distance_squared_to(point)
		if candidate < distance:
			distance = candidate
			best = {"position": point, "label": stage.label, "quest_title": definitions[quest_id].title, "goal_id": str(goal.id), "quest_id": quest_id, "stage_id": effective_stage}
	return best
