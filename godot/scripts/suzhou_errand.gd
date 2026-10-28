extends Node
## One independent civilian errand. Conversations commit only at their last line.
var game
var hub
var data: Dictionary
var ID: String
var GIVER: String
var phase="available"
var branch=""
var pending_phase=""
var pending_next=""
func _ready() -> void:
 ID=data.id;GIVER=data.giver
 var stages={"offer":{"label":game.PORTRAITS.ACTORS[GIVER].name+"에게 의뢰 묻기","goals":[]},"report":{"label":game.PORTRAITS.ACTORS[data.reporter].name+"에게 완료 보고","goals":[]}}
 for key in data.steps:stages[key]={"label":data.steps[key].label,"goals":[]}
 game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func reset() -> void:phase="available";branch="";pending_phase="";pending_next=""
func status() -> String:return phase if phase in ["available","ready","completed"] else "active"
func stage() -> String:
 if phase=="available":return "offer"
 if phase in ["ready","completed"]:return "report"
 if phase=="battle":return fight_step()
 return phase
func fight_step() -> String:
 for key in data.steps:
  if data.steps[key].get("mode","") in ["battle","spar"]:return key
 return ""
func target() -> String:
 if phase=="available":return GIVER
 if phase in ["ready","completed"]:return data.reporter
 return data.steps[stage()].target
func is_target(id: String) -> bool:return phase not in ["available","completed"] and target()==id
func marker_for(id: String) -> String:
 if phase=="ready" and id==data.reporter:return "?"
 return "!" if phase=="available" and id==GIVER else ""
func reward_label() -> String:return "보수 %d문" % int(data.reward.money)
func track() -> void:game.quest_navigation.update_quest(ID,stage());hub.invalidate()
func in_battle() -> bool:return phase=="battle"
func present() -> void:
 if phase=="available":game.say(data.intro,_offer);return
 if phase=="ready":game.say(data.report,_complete);return
 if phase=="completed":return
 var spec: Dictionary=data.steps[stage()]
 var mode=str(spec.get("mode",""))
 if mode=="choice":
  game.adventure_ui.choose(data.title,"사정을 들었다. 어떻게 말을 전할까?",spec.choices[0].label,_select_branch.bind(0),spec.choices[1].label,_select_branch.bind(1));return
 if mode=="spar":
  game.adventure_ui.choose("연무장 · 지도 대련",str(spec.choices_hint),"손을 맞춰 보겠습니다",_fight_dialogue,"아직 준비가 필요합니다",func():game.say([["sz_instructor","마음이 급하면 발부터 흐트러지지. 준비되면 다시 오시오."]]));return
 pending_phase=phase;pending_next=str(spec.get("next","ready"))
 var scene: Array=spec.get("scene_by_branch",{}).get(branch,spec.scene)
 game.say(scene,_start_battle if mode=="battle" else _advance)
func remind() -> void:
 game.say(data.progress)
func _offer() -> void:
 if phase!="available":return
 var danger="\n실전 전투가 포함되며 패배하면 사망합니다." if data.get("encounter",{}).get("defeat_outcome")=="death" else "\n지도 대련에서 패배해도 사망하지 않으며 다시 도전할 수 있습니다." if data.has("encounter") else ""
 game.adventure_ui.choose("의뢰 · "+str(data.title),reward_label()+danger,"일을 맡겠습니다",accept,"지금은 다른 볼일이 있습니다",func():game.say(data.decline))
func accept() -> void:
 if phase!="available":return
 phase=data.first;track();game.say(data.accept);game.adventure_ui.notify("의뢰 수락 · "+str(data.title),"quest")
func _select_branch(index: int) -> void:
 if not data.steps.has(phase) or data.steps[phase].get("mode")!="choice":return
 var c: Dictionary=data.steps[phase].choices[index]
 branch=c.key;pending_phase=phase;pending_next=c.next
 game.say(c.scene,_advance)
func _advance() -> void:
 if phase!=pending_phase or pending_next.is_empty():return
 phase=pending_next;pending_next="";pending_phase="";track()
 game.adventure_ui.notify("의뢰 갱신 · "+str(game.quest_navigation.definitions[ID].stages[stage()].label),"quest")
func _fight_dialogue() -> void:
 if phase!=fight_step():return
 pending_phase=phase;game.say(data.steps[phase].scene,_start_battle)
func _start_battle() -> void:
 if not data.has("encounter") or phase!=fight_step():return
 phase="battle";track();game.start_battle(data.encounter)
func after_victory() -> void:_ended(true)
func after_defeat() -> void:
 if data.encounter.defeat_outcome=="nonlethal":_ended(false)
func _ended(win: bool) -> void:
 if phase!="battle":return
 phase="ready" if win else fight_step();pending_phase="";pending_next=""
 game.battle.hide();game.state="explore";game.exploration.show();game.exploration.camera.enabled=true;game.exploration.camera.snap_to_player()
 game.top_hud.show();game.bottom_hint.text=preload("res://scripts/ui.gd").EXPLORATION_HINT;game.bottom_hint.show();game.music.play_track("dock")
 track();game.say(data.after_win if win else data.after_loss)
func _complete() -> void:
 if phase!="ready":return
 phase="completed";game.money+=int(data.reward.money)
 if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
 hub.invalidate();game.adventure_ui.notify("의뢰 완료 · %d문" % int(data.reward.money),"quest")
func goal(world) -> Dictionary:
 if phase=="completed":return {}
 var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
 if world.area_name=="suzhou":
  for npc in world.ambient_nodes:
   if npc.get_meta("npc_id")==target():return {"position":npc.position,"label":label,"quest_title":data.title,"goal_id":target(),"quest_id":ID,"stage_id":stage()}
  if data.has("enemy_point") and target()=="sz_extortionist":return {"position":world.city_point(data.enemy_point),"label":label,"quest_title":data.title,"goal_id":target(),"quest_id":ID,"stage_id":stage()}
 else:
  var exit_id={"cuiyue_hall":"travel:hall_exit","hangzhou":"travel:canal","suzhou_hangzhou_canal":"travel:suzhou","murong_estate":"travel:suzhou","nanjing":"travel:suzhou_road","nanjing_suzhou_road":"travel:suzhou","namgung_estate":"travel:nanjing","qingya_hamlet":"travel:nanjing","qingya_camp":"travel:hamlet","wuchang":"travel:qingya","alliance_office":"travel:office_exit","mountain_road":"travel:wuchang","changsha":"travel:road_east"}.get(world.area_name,"")
  for entry in world.travel_exits:
   if entry.id==exit_id:return {"position":entry.position,"label":"소주 의뢰를 위해 "+entry.name,"quest_title":data.title,"goal_id":entry.id,"quest_id":ID,"stage_id":stage()}
 return {}
func snapshot() -> Dictionary:return {"phase":phase,"branch":branch}
func valid(v) -> bool:
 if not v is Dictionary or not v.get("phase") is String or not v.get("branch","") is String:return false
 if v.phase not in ["available","ready","completed","battle"] and not data.steps.has(v.phase):return false
 if v.phase=="battle" and not data.has("encounter"):return false
 var choices=[""]
 for spec in data.steps.values():
  for c in spec.get("choices",[]):choices.append(c.key)
 return v.get("branch","") in choices and (v.phase!="available" or v.get("branch","")=="")
func restore(v: Dictionary) -> void:
 phase=v.get("phase","available");branch=v.get("branch","");pending_phase="";pending_next="";hub.invalidate()
