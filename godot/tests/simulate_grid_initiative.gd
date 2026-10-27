extends SceneTree
## Analysis fixture only. Production battle rules/data remain untouched.
const Combat=preload("res://scripts/combat_actions.gd")
const BEAT=100.0/30.0 # reference agility20: one action opportunity per shared beat
const EPS=.0000001
const DIRS=[Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN]
var combat=Combat.new()
var source: Dictionary
func _initialize() -> void:run.call_deferred()
func xy(p: Vector2i) -> Array:return [p.x+1,p.y+1]
func position_of(a: Array) -> Vector2i:return Vector2i(a[0]-1,a[1]-1)
func md(a: Vector2i,b: Vector2i) -> int:return absi(a.x-b.x)+absi(a.y-b.y)
func in_range(a: Vector2i,b: Vector2i,id: String) -> bool:
 var d=b-a
 # Paak's grid pattern is not canon: this fixture assumes a forward three-cell fan.
 return maxi(absi(d.x),absi(d.y))==1 if id=="paak" else md(a,b)==1
func path_to_target(start: Vector2i,target: Vector2i,id: String) -> Array:
 var queue=[start];var paths={start:[]};var best=start
 while not queue.is_empty():
  var point: Vector2i=queue.pop_front();var path: Array=paths[point]
  if in_range(point,target,id):return path
  if md(point,target)<md(best,target):best=point
  if path.size()==2:continue
  for d in DIRS:
   var next: Vector2i=point+d
   if next.x<0 or next.x>=7 or next.y<0 or next.y>=5 or next==target or paths.has(next):continue
   paths[next]=path+[next];queue.append(next)
 return paths[best]
func snapshot(actors: Array) -> Array:
 var out=[]
 for a in actors:out.append({"name":a.name,"hp":a.hp,"max_hp":a.max_hp,"qi":a.qi,"gauge":snappedf(a.gauge,.001),"pos":xy(a.pos),"guard":a.guard})
 return out
func simulate(profile: String,layout: Dictionary,hp_scale: int=1,recovery: String="clock",control: bool=false) -> Dictionary:
 var stats={"strength":20,"agility":50,"constitution":20,"inner":20,"insight":20}
 if profile=="strength":stats.strength=50;stats.agility=20
 var actors=[
  {"name":"도원","stats":stats,"hp":300,"max_hp":300,"qi":stats.inner,"speed":24 if control else 10+stats.agility,"gauge":0.0,"guard":0,"pos":position_of(layout.player),"weapon":"thickback_saber","actions":0,"attacks":0,"skills":0,"basics":0,"moved":0},
  {"name":source.name,"stats":source.stats.duplicate(),"hp":int(source.max_hp)*hp_scale,"max_hp":int(source.max_hp)*hp_scale,"qi":int(source.stats.inner),"speed":10+int(source.stats.agility),"gauge":0.0,"guard":0,"pos":position_of(layout.enemy),"weapon":source.weapon,"actions":0,"attacks":0,"skills":0,"basics":0,"moved":0}
 ]
 var frames=[{"kind":"start","beat":0,"actor":-1,"action":"시작","damage":0,"path":[],"state":snapshot(actors)}]
 var time=0.0;var next_pulse=BEAT;var winner=-1;var events=0
 while winner<0 and events<500:
  events+=1
  var dt=minf(maxf(0,(100.0-actors[0].gauge)/actors[0].speed),maxf(0,(100.0-actors[1].gauge)/actors[1].speed))
  if recovery=="clock":dt=minf(dt,maxf(0,next_pulse-time))
  time+=dt
  for a in actors:a.gauge+=a.speed*dt
  if recovery=="clock" and time+EPS>=next_pulse:
   for a in actors:a.qi=mini(500,a.qi+int(a.stats.inner))
   frames.append({"kind":"recovery","beat":snappedf(time/BEAT,.001),"actor":-1,"action":"공통 박자 · 양쪽 내기 회복","damage":0,"path":[],"state":snapshot(actors)})
   next_pulse+=BEAT
  var ready=[]
  for i in range(2):
   if actors[i].gauge+EPS>=100:ready.append(i)
  if ready.is_empty():continue
  var i: int=ready[0]
  if ready.size()==2 and actors[1].stats.agility>actors[0].stats.agility:i=1
  var a: Dictionary=actors[i];var target: Dictionary=actors[1-i]
  a.gauge=maxf(0,a.gauge-100);a.actions+=1
  var id="paak" if i==0 and a.qi>=combat.action("paak",a.stats,a.weapon).cost else "basic_attack"
  if i==1:id=combat.enemy_plan(a.stats,a.weapon,source.skills,a.qi,a.actions)
  var path=[];var a0=combat.action(id,a.stats,a.weapon)
  if a0.raw>0:
   path=path_to_target(a.pos,target.pos,id)
   for p in path:a.pos=p
   a.moved+=path.size()
   if not in_range(a.pos,target.pos,id):id="basic_defense"
  var action=combat.action(id,a.stats,a.weapon)
  assert(not action.is_empty() and a.qi>=action.cost)
  var cost: int=action.cost;a.qi-=cost
  var hit=0
  if action.raw>0:
   hit=combat.damage(action.raw,target.stats.constitution,target.weapon,target.guard)
   target.hp=maxi(0,target.hp-hit);a.attacks+=1
   if id=="paak":a.skills+=1
   elif id=="basic_attack":a.basics+=1
  a.guard=maxi(a.guard,int(action.guard));target.guard=0
  if recovery=="per_action":a.qi=mini(500,a.qi+int(a.stats.inner))
  var serialized=[]
  for p in path:serialized.append(xy(p))
  frames.append({"kind":"action","beat":snappedf(time/BEAT,.001),"actor":i,"action":action.name,"id":id,"damage":hit,"raw":action.raw,"cost":cost,"path":serialized,"state":snapshot(actors)})
  if target.hp<=0:winner=i
 return {"profile":profile,"control":control,"layout":layout,"hp_scale":hp_scale,"recovery":recovery,"beats":snappedf(time/BEAT,.001),"winner":winner,"player_hp":actors[0].hp,"player_actions":actors[0].actions,"enemy_actions":actors[1].actions,"player_attacks":actors[0].attacks,"enemy_attacks":actors[1].attacks,"player_skills":actors[0].skills,"player_basics":actors[0].basics,"player_moved":actors[0].moved,"stats":stats,"frames":frames}
func run() -> void:
 source=JSON.parse_string(FileAccess.get_file_as_string("res://data/qingya_quest.json")).encounters[0]
 assert(source.name=="정괴" and source.max_hp==280)
 var layouts=[
  {"id":"centre","title":"중앙 직선","player":[2,3],"enemy":[6,3]},
  {"id":"near","title":"인접 시작","player":[3,3],"enemy":[4,3]},
  {"id":"diagonal","title":"대각 접근","player":[2,4],"enemy":[6,2]},
  {"id":"far","title":"반대 모서리","player":[1,5],"enemy":[7,1]},
  {"id":"reverse","title":"진영 반전","player":[6,3],"enemy":[2,3]}
 ]
 var cases=[]
 for hp_scale in [1,4]:
  for layout in layouts:
   for profile in ["agility","strength"]:cases.append(simulate(profile,layout,hp_scale))
   cases.append(simulate("agility",layout,hp_scale,"clock",true))
 # The alternative recovery rule is deliberately a sensitivity test, not production behaviour.
 cases.append(simulate("agility",layouts[0],4,"per_action"))
 var data={"source_enemy":source,"player_weapon":"thickback_saber","player_art":"paak","beat_reference_agility":20,"gauge_threshold":100,"speed_base":10,"width":7,"height":5,"move_limit":2,"cases":cases}
 var out=ProjectSettings.globalize_path("res://").path_join("../prototypes/grid-initiative-simulation/data.json")
 var file=FileAccess.open(out,FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(data,"  "));file.close()
 for c in cases:
  if c.layout.id=="centre":print("GRID_CASE ",JSON.stringify({"profile":c.profile,"control":c.control,"hp_scale":c.hp_scale,"recovery":c.recovery,"winner":c.winner,"hp":c.player_hp,"beats":c.beats,"actions":[c.player_actions,c.enemy_actions],"attacks":[c.player_attacks,c.enemy_attacks],"skills":c.player_skills,"basics":c.player_basics}))
 assert(cases.size()==31)
 for c in cases:
  assert(c.winner>=0)
  for f in c.frames:
   for a in f.state:assert(a.qi>=0 and a.qi<=500 and a.pos[0]>=1 and a.pos[0]<=7 and a.pos[1]>=1 and a.pos[1]<=5)
   assert(f.state[0].pos!=f.state[1].pos and f.path.size()<=2)
 print("GRID_INITIATIVE_SIMULATION: PASS / ",cases.size()," deterministic cases");quit()
