extends "res://scripts/suzhou_errand.gd"
## Independent, nonlethal exchange: family privilege is questioned without hidden intrigue.
var battle_step="opening"
func status() -> String:return "dormant" if phase=="available" and not eligible() else super.status()
func eligible() -> bool:return hub.get_quest("suzhou_balance").phase=="completed"
func marker_for(id: String) -> String:
 if phase=="available" and not eligible():return ""
 return super.marker_for(id)
func present() -> void:
 if phase=="available" and not eligible():
  game.say([["sz_instructor","먼저 손에 맞는 병장기 의뢰를 마치고 진 장인에게 보고하시오. 그 뒤 소개할 자리가 있소."]]);return
 if phase in ["opening","trial"]:
  game.adventure_ui.choose(data.title,"힘을 제한하는 비살상 대련입니다. 승패와 관계없이 복기를 이어갑니다.","대련을 시작한다",_fight_dialogue,"나중에 준비해서 온다",func():game.say([["mr_heir","준비되면 말씀하십시오. 재촉하지 않겠습니다."]]));return
 if phase=="decide":
  game.adventure_ui.choose(data.title,"진석우의 생업과 실전을 고려하여 수련을 검증할 방법을 정합니다.",data.steps.decide.choices[0].label,_select_branch.bind(0),data.steps.decide.choices[1].label,_select_branch.bind(1));return
 super.present()
func fight_step() -> String:return battle_step if phase=="battle" else phase if phase in ["opening","trial"] else "opening"
func _fight_dialogue() -> void:
 battle_step=phase
 super._fight_dialogue()
func _start_battle() -> void:
 if phase not in ["opening","trial"]:return
 battle_step=phase;phase="battle";track()
 var encounter=data.encounter.duplicate(true)
 if battle_step=="trial" and branch=="narrow":encounter.field={"width":7,"height":3,"player_spawn":[1,1],"enemy_spawn":[5,1],"blocked":[[0,0],[0,2],[6,0],[6,2]]}
 game.start_battle(encounter)
func _ended(win: bool) -> void:
 if phase!="battle":return
 var first=battle_step=="opening"
 phase="hear" if first else "review";pending_phase="";pending_next=""
 game.battle.hide();game.state="explore";game.exploration.show();game.exploration.camera.enabled=true;game.exploration.camera.snap_to_player()
 game.top_hud.show();game.bottom_hint.text=preload("res://scripts/ui.gd").EXPLORATION_HINT;game.bottom_hint.show();game.music.play_track("dock")
 track()
 game.say([["mr_heir","여기까지 하시지요. 승패보다 초식이 쓰이는 사정을 함께 살피고 싶습니다." if win else "여기서 거두겠습니다. 힘을 제한한 대련이니 마음 쓰지 마십시오. 이긴 쪽도 배울 것은 있습니다."],["mr_heir","객방 앞의 진석우 소협이 후원을 사양하고 떠난다더군요. 무슨 사정인지 함께 들어 주시겠습니까?" if first else "진석우 소협과 방금 확인한 것을 복기하지요."]])
func _complete() -> void:
 if phase!="ready":return
 game.progress.add_favor("murong",10)
 super._complete()
func reward_label() -> String:return "보수500문 · 모용세가 호의도+10"
func snapshot() -> Dictionary:
 var v=super.snapshot();v.battle_step=battle_step;return v
func valid(v) -> bool:return super.valid(v) and v.get("battle_step","opening") in ["opening","trial"]
func restore(v: Dictionary) -> void:
 battle_step=v.get("battle_step","opening");super.restore(v)
func reset() -> void:super.reset();battle_step="opening"
func goal(world) -> Dictionary:
 if phase=="completed":return {}
 var area="suzhou" if phase=="available" else "murong_estate"
 var label: String=game.quest_navigation.definitions[ID].stages[stage()].label
 if world.area_name==area:
  for npc in world.ambient_nodes:
   if npc.get_meta("npc_id")==target():return {"position":npc.position,"label":label,"quest_title":data.title,"goal_id":target(),"quest_id":ID,"stage_id":stage()}
 var portal="travel:murong" if world.area_name=="suzhou" else "travel:suzhou" if world.area_name=="murong_estate" else ""
 for entry in world.travel_exits:
  if entry.id==portal:return {"position":entry.position,"label":entry.name,"quest_title":data.title,"goal_id":entry.id,"quest_id":ID,"stage_id":stage()}
 return super.goal(world)
