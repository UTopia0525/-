extends RefCounted
## Reads committed public state and techniques already witnessed, never UI selection.
static func damage_at(g,index: int,point: Vector2i,known_only: bool=false) -> Dictionary:
 var unit=g.units[index];var foe=g.units[1-index];var old=unit.position;unit.position=point
 var best={"id":"","facing":unit.facing,"damage":0,"score":-1.0}
 var skills=g.units[1-index].observed_skills if known_only else unit.skills
 for id in ["basic_attack"]+skills:
  for facing in g.DIRECTIONS:
   var action=g.combat.action(id,unit.stats,unit.weapon)
   if action.is_empty() or action.raw<=0:continue
   if not known_only and unit.gauge<maxi(g.READY,g.cost(id)):continue
   if int(unit.ready.get(id,0))>unit.actions or action.cost>unit.qi:continue
   var model=g.footprint(index,id,facing);var open=true
   for step in range(1,int(g.profile(id).advance)+1):
    if not g.free_cell(point+facing*step,index):open=false;break
   if not open or foe.position not in model.attacks:continue
   var damage=g.combat.damage(action.raw,foe.stats.constitution,foe.weapon,foe.guard)
   var score=damage*(.55+27.0/g.cost(id))
   # A finishing blow matters more than long-term action efficiency.
   if damage>=foe.hp:score=10000-g.cost(id)*2-float(action.cost)
   score+=float(action.guard)*.3
   if score>best.score:best={"id":id,"facing":facing,"damage":damage,"score":score}
 unit.position=old
 return best
static func incoming(g,index: int,point: Vector2i) -> int:
 var unit=g.units[index];var old=unit.position;unit.position=point
 var attack=damage_at(g,1-index,g.units[1-index].position,true)
 unit.position=old;return int(attack.damage)
static func choose(g,index: int) -> Dictionary:
 var unit=g.units[index];var foe=g.units[1-index];var facing=unit.facing
 var best=damage_at(g,index,unit.position)
 var threat=incoming(g,index,unit.position)
 var gentle=unit.get("ai",{}).get("style","")=="tutorial"
 if best.damage>=foe.hp and best.id!="":return {"id":best.id,"facing":best.facing}
 # Retreat from a witnessed lethal technique or an opponent's active guard.
 # Limit consecutive defensive choices so guarding cannot stall the fight forever.
 var defensive=unit.last_action not in ["move","basic_defense","wait","josik_suwon"]
 if not gentle and defensive and threat>0 and (threat>=unit.hp or (foe.guard>0 and unit.hp<float(unit.max_hp)*.6)):
  var safe=unit.position;var least=threat
  for direction in g.DIRECTIONS:
   var point=unit.position+direction
   if not g.free_cell(point,index):continue
   var danger=incoming(g,index,point)
   if danger<least:safe=point;least=danger
  if safe!=unit.position:return {"id":"move","facing":safe-unit.position,"destination":safe}
  if unit.guard==0:return {"id":"basic_defense","facing":facing}
 # Recovery is valued only when costly known techniques actually need qi.
 if not gentle and unit.last_action!="josik_suwon":
  var wanted=0
  for id in unit.skills:
   var action=g.combat.action(id,unit.stats,unit.weapon)
   if not action.is_empty() and action.raw>0:wanted=maxi(wanted,int(action.cost))
  if unit.qi<wanted:
   for id in unit.skills:
    var action=g.combat.action(id,unit.stats,unit.weapon)
    if not action.is_empty() and action.get("qi_restore",0)>0 and g.problem(index,id,facing).is_empty():return {"id":id,"facing":facing}
 # A step can open a stronger technique's minimum range (e.g. advancing fist).
 # Never sacrifice an immediate finish and do not keep repositioning every action.
 if not gentle and unit.last_action!="move" and best.id!="":
  var spacing_score=best.score*1.6+10.0;var spacing=unit.position
  for direction in g.DIRECTIONS:
   var point=unit.position+direction
   if not g.free_cell(point,index):continue
   var attack=damage_at(g,index,point)
   if attack.damage>best.damage and attack.score>spacing_score and incoming(g,index,point)<=threat:
    spacing_score=attack.score;spacing=point
  if spacing!=unit.position:return {"id":"move","facing":spacing-unit.position,"destination":spacing}
 if best.id!="":
  # Use an inexpensive strike against guard rather than wasting a heavy technique.
  if foe.guard>0:
   for direction in g.DIRECTIONS:
    if g.problem(index,"basic_attack",direction).is_empty():return {"id":"basic_attack","facing":direction}
  return {"id":best.id,"facing":best.facing}
 # Seek the closest legal attack position. Among equally short routes prefer safety
 # and good weapon spacing; never walk onto the opponent or through an obstacle.
 var queue=[unit.position];var first={unit.position:unit.position};var distance={unit.position:0};var cursor=0
 var goal_distance=100000;var goal_score=-INF;var goal_step=unit.position
 while cursor<queue.size():
  var point=queue[cursor];cursor+=1
  if distance[point]>goal_distance:break
  if point!=unit.position:
   var attack=damage_at(g,index,point)
   if attack.id!="":
    var value=attack.score-float(incoming(g,index,point))*.3
    if value>goal_score:goal_distance=distance[point];goal_score=value;goal_step=first[point]
  if distance[point]>=goal_distance:continue
  for direction in g.DIRECTIONS:
   var next=point+direction
   if g.free_cell(next,index) and not first.has(next):
    first[next]=next if point==unit.position else first[point];distance[next]=distance[point]+1;queue.append(next)
 if goal_step!=unit.position:return {"id":"move","facing":goal_step-unit.position,"destination":goal_step}
 return {"id":"wait","facing":facing}
