extends Node
## Optional follow-up. All durable changes happen at conversation boundaries.
const ID="blackguild_story"
const GIVER="cy_manager"
const UI=preload("res://scripts/ui.gd")
var game
var phase="available"
var branch=""
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/blackguild_story.json"))
var owned: Array[Node]=[]
var signature=""
func _ready() -> void:
 for n in data.characters:
  var actor={"name":n.name,"extra":n.get("basic_portrait","male_middle")}
  if n.has("portrait"):actor.portrait=n.portrait
  game.PORTRAITS.ACTORS[n.id]=actor
 var stages={}
 for key in data.stages:stages[key]={"label":data.stages[key][2],"goals":[]}
 game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func eligible() -> bool:return game.cuiyue_incident.phase=="completed"
func status() -> String:
 if not eligible():return "locked"
 return phase if phase in ["available","completed"] else "ready" if phase=="report" else "active"
func stage() -> String:return phase
func target() -> String:return data.stages[phase][0]
func reward_label() -> String:return "취월루의 거래 회복 · 별도 수치 보상 없음"
func marker_for(id: String) -> String:
 if not eligible():return ""
 if phase=="available" and id==GIVER:return "!"
 if phase=="report" and id==GIVER:return "?"
 return ""
func is_target(id: String) -> bool:return eligible() and phase not in ["available","completed"] and id==target()
func track() -> void:
 game.quest_navigation.update_quest(ID,phase);signature=""
func topics(id: String) -> Array:
 if not eligible() or phase=="completed":return []
 if id==target():return [[("의뢰 · " if phase=="available" else "진행 · ")+data.title,present]]
 if id==GIVER:return [["진행 확인 · "+data.title,func():game.say([[GIVER,data.stages[phase][2]+". 서두르지 말고 살펴 주세요."]])]]
 return []
func handle_interaction(id: String) -> bool:
 if id not in ["bg_wi","bg_officer","bg_supplier","bg_guard_w","bg_guard_e","cy_tak","cy_eunsowol"]:return false
 if not eligible():return false
 if phase!="completed" and id==target():present();return true
 if phase=="completed" and data.post[branch].has(id):game.say(data.post[branch][id]);return true
 if id.begins_with("bg_"):
  var n=_character(id)
  game.say(n.get("dialogue",[[id,"볼일이 남았다면 먼저 약속한 일을 마치시오."]]));return true
 return false
func present() -> void:
 if not eligible() or phase in ["completed","battle"]:return
 if phase=="available":game.say(data.scenes.available,_offer);return
 if phase=="choice":game.say(data.scenes.choice,_choose);return
 if phase=="audience":game.say(data.scenes["audience_"+branch],_advance.bind("report"));return
 if phase=="report":game.say(data.scenes["report_"+branch],_complete);return
 var next={"fish":"artisan","artisan":"waiter","waiter":"proposal","proposal":"consult","consult":"warehouse","papers":"choice"}
 game.say(data.scenes[phase],_fight if phase=="warehouse" else _advance.bind(next.get(phase,phase)))
func _offer() -> void:
 game.adventure_ui.choose(data.title,"거래처의 사정을 조사합니다. 창고에서 실전 전투가 있으며 패배하면 사망합니다.\n별도의 금전·능력치 보상은 없습니다.","사정을 알아보겠소",accept,"지금은 어렵겠소",func():game.say([[GIVER,"다른 볼일부터 보세요. 급한 마음에 더 큰 일을 만들고 싶지는 않아요."]]))
func accept() -> void:
 if phase!="available" or not eligible():return
 phase="fish";track();game.say(data.scenes.accept);game.adventure_ui.notify("의뢰 수락 · "+data.title,"quest")
func _advance(next: String) -> void:
 phase=next;track();refresh_world();game.adventure_ui.notify("의뢰 갱신 · "+data.stages[phase][2],"quest")
func _choose() -> void:
 game.adventure_ui.choose(data.title,"잘못을 드러내는 일과 생업을 지키는 일, 어디까지 요구할 것인가.","당사자들에게 사실을 모두 밝힌다",_select.bind("public"),"피해 회복을 조건으로 비공개 합의한다",_select.bind("agreement"))
func _select(value: String) -> void:
 if phase!="choice" or value not in ["public","agreement"]:return
 # Commit only after the selected dialogue ends; the choice window can be saved.
 game.say(data.scenes[value],_branch_committed.bind(value))
func _branch_committed(value: String) -> void:branch=value;_advance("audience")
func _fight() -> void:
 if phase!="warehouse":return
 phase="battle";track();game.start_battle(data.encounter)
func in_battle() -> bool:return phase=="battle"
func after_victory() -> void:
 if phase!="battle":return
 game.battle.cancel();game.battle.hide();game.state="explore";game.exploration.show();game.exploration.camera.enabled=true;game.exploration.camera.snap_to_player();game.top_hud.show();game.music.play_track("dock")
 phase="papers";track();refresh_world();game.say(data.scenes.won)
func _complete() -> void:
 if phase!="report":return
 phase="completed";signature=""
 if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
 game.adventure_ui.notify("의뢰 완료 · "+data.title,"quest");refresh_world()
func goal(world) -> Dictionary:
 if not eligible() or phase=="completed":return {}
 var destination=data.stages[phase][1];var point=Vector2.ZERO;var goal_id=target();var label=data.stages[phase][2]
 if world.area_name==destination:
  for npc in world.ambient_nodes:
   if npc.get_meta("npc_id")==target():point=npc.position;break
 else:
  var exit_id=""
  if world.area_name in ["blackguild_hall","blackguild_warehouse"]:exit_id="travel:bg_exit"
  elif world.area_name=="cuiyue_hall":exit_id="travel:hall_exit"
  elif world.area_name=="hangzhou":exit_id={"cuiyue_hall":"travel:hall_entry","blackguild_hall":"travel:bg_hall","blackguild_warehouse":"travel:bg_warehouse"}.get(destination,"")
  else:exit_id={"suzhou_hangzhou_canal":"travel:hangzhou","suzhou":"travel:canal","murong_estate":"travel:suzhou","nanjing_suzhou_road":"travel:suzhou","nanjing":"travel:suzhou_road","namgung_estate":"travel:nanjing","qingya_hamlet":"travel:nanjing","qingya_camp":"travel:hamlet","wuchang":"travel:qingya","alliance_office":"travel:office_exit","mountain_road":"travel:wuchang","changsha":"travel:road_east"}.get(world.area_name,"")
  for exit in world.travel_exits:
   if exit.id==exit_id:point=exit.position;goal_id=exit.id;label=exit.name+" · "+label;break
 if point==Vector2.ZERO:return {}
 return {"position":point,"label":label,"quest_title":data.title,"goal_id":goal_id,"quest_id":ID,"stage_id":phase}
func clear_world() -> void:
 var w=game.exploration
 for node in owned:
  if is_instance_valid(node):
   if node is Node2D:w.ambient_nodes.erase(node)
   node.free()
 owned.clear()
func _spawn(spec: Dictionary) -> void:
 var w=game.exploration;w._populate_residents([spec.duplicate(true)])
 var body=w.ambient_nodes.back();owned.append(body)
 var tag=w.occlusion_roots.pop_back();tag.reparent(body);tag.position=Vector2.ZERO
func _character(id: String) -> Dictionary:
 for n in data.characters:
  if n.id==id:return n.duplicate(true)
 for n in game.cuiyue_incident.data.characters:
  if n.id==id:return n.duplicate(true)
 return {}
func refresh_world() -> void:
 var w=game.exploration;var key=str(w.load_revision)+":"+phase+":"+str(eligible())
 if signature==key:return
 signature=key;clear_world()
 if not eligible():return
 if w.area_name=="cuiyue_hall" and phase=="available":_spawn(_character("bg_supplier"))
 if w.area_name=="hangzhou" and phase=="proposal":
  var n=_character("cy_tak");n.point=[550,390];_spawn(n)
 if w.area_name=="blackguild_warehouse":
  _spawn(_character("bg_supplier"))
  if phase in ["warehouse","battle"]:_spawn(_character("bg_officer"))
 if w.area_name=="blackguild_hall":
  _spawn(_character("bg_wi"))
  _spawn(_character("bg_guard_w"));_spawn(_character("bg_guard_e"))
  if phase=="audience":
   var n=_character("cy_eunsowol");n.point=[650,530];_spawn(n)
 for npc in w.ambient_nodes:
  var mark=marker_for(npc.get_meta("npc_id"))
  if mark.is_empty():continue
  var tag=UI.label(npc,mark,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-w.Metrics.QUEST_GAP-w.Metrics.NAME_GAP-46,80,92),68,Color("ffe14b"));tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tag.add_theme_color_override("font_outline_color",Color("2b2614"));tag.add_theme_constant_override("outline_size",5);owned.append(tag)
 if is_instance_valid(w.regional_map):w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _process(_delta: float) -> void:refresh_world()
func reset() -> void:phase="available";branch="";signature="";clear_world()
func snapshot() -> Dictionary:return {"phase":phase,"branch":branch}
func valid(v) -> bool:
 if not v is Dictionary or not data.stages.has(v.get("phase","")) or v.get("branch","") not in ["","public","agreement"]:return false
 return (v.phase in ["audience","report","completed"])==(v.get("branch","")!="")
func restore(v: Dictionary) -> void:phase=v.get("phase","available");branch=v.get("branch","");signature=""
