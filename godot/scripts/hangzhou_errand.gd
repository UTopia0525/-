extends "res://scripts/suzhou_errand.gd"
func present() -> void:
 if data.steps.has(phase) and data.steps[phase].get("mode","")=="choice":
  var spec: Dictionary=data.steps[phase]
  game.adventure_ui.choose(data.title,spec.choice_hint,spec.choices[0].label,_select_branch.bind(0),spec.choices[1].label,_select_branch.bind(1));return
 super.present()
func goal(world) -> Dictionary:
 if phase=="completed":return {}
 var goal_id=target();var destination="cuiyue_hall" if goal_id.begins_with("cy_") else "hangzhou"
 var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
 if world.area_name==destination:
  for npc in world.ambient_nodes:
   if npc.get_meta("npc_id")==goal_id:return {"position":npc.position,"label":label,"quest_title":data.title,"goal_id":goal_id,"quest_id":ID,"stage_id":stage()}
  return {}
 if world.area_name=="qingya_camp" and game.qingya_quest.inside_fence():
  for entry in world.objectives:
   if entry.id=="qingya_stealth:exit":return {"position":entry.position,"label":"목책 틈으로 빠져나가기","quest_title":data.title,"goal_id":entry.id,"quest_id":ID,"stage_id":stage()}
 var route={"cuiyue_hall":"travel:hall_exit","hangzhou":"travel:hall_entry","suzhou_hangzhou_canal":"travel:hangzhou","suzhou":"travel:canal","murong_estate":"travel:suzhou","nanjing_suzhou_road":"travel:suzhou","nanjing":"travel:suzhou_road","namgung_estate":"travel:nanjing","qingya_hamlet":"travel:nanjing","qingya_camp":"travel:hamlet","wuchang":"travel:qingya","alliance_office":"travel:office_exit","mountain_road":"travel:wuchang","changsha":"travel:road_east"}
 for entry in world.travel_exits:
  if entry.id==route.get(world.area_name,""):return {"position":entry.position,"label":entry.name+" · "+label,"quest_title":data.title,"goal_id":entry.id,"quest_id":ID,"stage_id":stage()}
 return {}
func valid(v) -> bool:
 if not super.valid(v):return false
 # Only states reachable through a completed conversation may be loaded.
 var queue=[{"phase":"available","branch":""}];var seen={}
 while not queue.is_empty():
  var state: Dictionary=queue.pop_front();var key=state.phase+":"+state.branch
  if seen.has(key):continue
  seen[key]=true
  if state.phase==v.phase and state.branch==v.get("branch",""):return true
  if state.phase=="available":queue.append({"phase":data.first,"branch":""})
  elif state.phase=="ready":queue.append({"phase":"completed","branch":state.branch})
  elif data.steps.has(state.phase):
   var step: Dictionary=data.steps[state.phase]
   if step.get("mode","")=="choice":
    for c in step.choices:queue.append({"phase":c.next,"branch":c.key})
   else:queue.append({"phase":step.get("next","ready"),"branch":state.branch})
 return false
