extends RefCounted
## Deterministic action clock and transactions shared by both sides; no rendering/timers.
const DIRECTIONS=[Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
const MOVE_COST=20
const READY=100
const SPEED_BASE=10
const MAX_GAUGE=1000
var field=preload("res://scripts/battle_field.gd").new()
var combat=preload("res://scripts/combat_actions.gd").new()
var tactics=preload("res://scripts/martial_tactics.gd").new()
var units: Array=[]
var tick=0
var last_actor=1
var winner=-1
var continuation=-1
var support: Dictionary={}
func setup(config: Dictionary,player: Dictionary,enemy: Dictionary) -> void:
 field.configure(config);units=[];tick=0;last_actor=1;winner=-1;continuation=-1
 support=config.get("support",{}).duplicate(true)
 for index in range(2):
  var data=(player if index==0 else enemy).duplicate(true)
  data.position=field.player_spawn if index==0 else field.enemy_spawn
  data.facing=Vector2i.RIGHT if index==0 else Vector2i.LEFT
  data.resource=preload("res://scripts/inner_qi.gd").new();data.resource.start(int(data.stats.inner))
  data.gauge=0;data.qi=data.resource.amount;data.guard=0;data.actions=0;data.ready={};data.observed_skills=[];data.last_action=""
  units.append(data)
func next_actor() -> int:
 if winner>=0:return -1
 if continuation>=0 and units[continuation].gauge>=READY:return continuation
 continuation=-1
 for safety in range(10001):
  var available=[]
  for index in range(2):
   if units[index].hp>0 and units[index].gauge>=READY:available.append(index)
  if not available.is_empty():
   if available.size()==1:return available[0]
   if units[0].gauge==units[1].gauge:return 1-last_actor
   return 0 if units[0].gauge>units[1].gauge else 1
  tick+=1
  for unit in units:unit.gauge=mini(MAX_GAUGE,unit.gauge+int(unit.stats.agility)+SPEED_BASE)
 return -1
func rotated(offset: Vector2i,facing: Vector2i) -> Vector2i:
 return facing*offset.x+Vector2i(-facing.y,facing.x)*offset.y
func profile(id: String) -> Dictionary:
 if tactics.entries.has(id):return tactics.get_tactics(id)
 # Existing enemy arts receive explicit shared grid footprints without changing their damage.
 var offsets=[[1,0]];var cost=60
 if id=="soemok":offsets=[[1,0],[2,0]];cost=65
 if id=="bandit_heavy_chop":cost=80
 return {"action_cost":cost,"attack_offsets":offsets,"advance":0,"retreat":0,"push":0,"target":"대상 1명","shape":"custom"}
func cost(id: String) -> int:return MOVE_COST if id in ["move","wait"] else int(profile(id).action_cost)
func free_cell(p: Vector2i,index: int) -> bool:return field.walkable(p) and p!=units[1-index].position
func footprint(index: int,id: String,facing: Vector2i) -> Dictionary:
 var unit=units[index];var data=profile(id);var caster=unit.position+facing*int(data.advance)
 var attacks: Array[Vector2i]=[]
 for value in data.get("attack_offsets",[]):
  var point=caster+rotated(Vector2i(int(value[0]),int(value[1])),facing)
  if field.inside(point) and field.sight(caster,point):attacks.append(point)
 return {"caster":caster,"attacks":attacks,"self":data.get("shape")=="self"}
func problem(index: int,id: String,facing: Vector2i,destination: Vector2i=Vector2i(-1,-1)) -> String:
 if winner>=0:return "교전이 끝났습니다."
 var unit=units[index]
 if facing not in DIRECTIONS:return "방향을 고르세요."
 if unit.gauge<READY:return "행동력100 이상에서 행동할 수 있습니다."
 if unit.gauge<cost(id):return "행동력이 부족합니다."
 if id=="wait":return ""
 if id=="move":
  if absi(destination.x-unit.position.x)+absi(destination.y-unit.position.y)!=1:return "한 걸음씩 이동하세요."
  return "" if free_cell(destination,index) else "지나갈 수 없는 자리입니다."
 if id not in unit.skills and id not in ["basic_attack","basic_defense"]:return "익히지 않은 무공입니다."
 var action=combat.action(id,unit.stats,unit.weapon)
 if action.is_empty():return "무기 종류가 맞지 않습니다."
 if int(unit.ready.get(id,0))>unit.actions:return "재사용까지 %d행동 남았습니다." % (int(unit.ready[id])-unit.actions)
 if action.cost>unit.qi:return "내기가 부족합니다."
 var model=footprint(index,id,facing)
 for step in range(1,int(profile(id).advance)+1):
  if not free_cell(unit.position+facing*step,index):return "파고들 자리가 막혀 있습니다."
 if not model.self and units[1-index].position not in model.attacks:return "상대가 공격 범위 밖에 있습니다."
 return ""
func perform(index: int,id: String,facing: Vector2i,destination: Vector2i=Vector2i(-1,-1)) -> Dictionary:
 var reason=problem(index,id,facing,destination)
 if not reason.is_empty():return {"ok":false,"reason":reason}
 var unit=units[index];var foe=units[1-index];var before=unit.position
 unit.resource.restore(int(unit.stats.inner),int(unit.qi))
 # Only a committed action expires guard. Selection, ticks and invalid attempts never do.
 unit.last_action=id
 if id not in ["move","wait"] and id not in foe.observed_skills:foe.observed_skills.append(id)
 unit.guard=0;unit.facing=facing;unit.gauge-=cost(id);unit.actions+=1;last_actor=index;continuation=index
 var event={"ok":true,"actor":index,"id":id,"damage":0,"qi_cost":0,"guard_used":foe.guard,"before":before}
 if id=="move":unit.position=destination
 elif id!="wait":
  var action=combat.action(id,unit.stats,unit.weapon);var data=profile(id)
  unit.resource.spend(int(action.cost));event.qi_cost=int(action.cost)
  unit.position=footprint(index,id,facing).caster
  var damage=0
  if action.raw>0:damage=combat.damage(action.raw,float(foe.stats.constitution),foe.weapon,int(foe.guard))
  if index==1 and not support.is_empty() and damage>0:
   var reduced=floori(damage*(1.0-float(support.get("intercept_percent",0))/100.0))
   event.support_blocked=damage-reduced;damage=reduced
  foe.hp=maxi(0,foe.hp-damage);event.damage=damage
  unit.guard=int(action.guard)
  combat.commit_support(action,unit.resource,unit.ready,unit.actions-1)
  for step in range(int(data.get("push",0))):
   var point=foe.position+facing
   if field.walkable(point) and point!=unit.position:foe.position=point
   else:break
  for step in range(int(data.get("retreat",0))):
   var point=unit.position-facing
   if free_cell(point,index):unit.position=point
   else:break
 if index==0 and id!="wait" and not support.is_empty() and foe.hp>0 and absi(unit.position.x-foe.position.x)+absi(unit.position.y-foe.position.y)<=3:
  event.support_damage=combat.damage(float(support.get("attack_raw",0)),float(foe.stats.constitution),foe.weapon,int(foe.guard))
  foe.hp=maxi(0,foe.hp-int(event.support_damage))
 unit.resource.recover_turn();unit.qi=unit.resource.amount
 if foe.hp==0:winner=index
 return event
func enemy_choice() -> Dictionary:
 return preload("res://scripts/grid_tactical_ai.gd").choose(self,1)
