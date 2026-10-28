extends Node
const ID="namgung_campaign"
const GIVER="namgung_seojin"
const PHASES=["available","preparing","camp","battle","report","return","completed"]
var game
var phase="available"
var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/namgung_campaign.json"))
var nodes: Array=[]
var signature=""
var gate_warned=false
var favor_reward_granted=false
var warrior_visual: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/namgung_warrior.json"))
func _ready() -> void:
 game.PORTRAITS.ACTORS[GIVER]={"name":"남궁서진","portrait":"res://assets/portraits/namgung/seojin.png"}
 game.PORTRAITS.ACTORS["ng_gatekeeper"]={"name":"남궁 문지기","portrait":warrior_visual.portrait}
 for i in range(1,5):game.PORTRAITS.ACTORS["ng_guard_"+str(i)]={"name":"남궁 무사","portrait":warrior_visual.portrait}
 var stages={}
 for s in PHASES:stages[s]={"label":{"available":"남궁세가 정문의 남궁서진에게 토벌 이야기 듣기","preparing":"정비한 뒤 남궁서진과 출정","camp":"남궁 무사들과 청애채 안쪽의 마운표에게 접근","battle":"남궁서진의 지원을 받아 마운표 제압","report":"산채 해체를 확인하고 남궁세가의 서진에게 보상 받기","return":"삼거리 산촌에서 돌아온 임수전과 대화","completed":"돌아온 주민들의 생활 확인"}[s],"goals":[]}
 game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func eligible() -> bool:return game.qingya_quest.regret_seen and game.waterfront_quest.phase=="completed" and int(game.progress.faction_favor.get("namgung",0))>=10
func status() -> String:return ("available" if eligible() else "locked") if phase=="available" else "completed" if phase=="completed" else "ready" if phase=="report" else "active"
func stage() -> String:return phase
func journal_items() -> Array:return [{"id":"namgung_cheongcheon_pill","name":"창천보원단 · 오성 제외 각+3"}]
func reward_label() -> String:return "1,000문 · 창천보원단1개 · 남궁 호의도+30 (영약: 오성 제외 각+3)"
func marker_for(id: String) -> String:return "!" if id==GIVER and status()=="available" else "?" if id==GIVER and phase=="report" else ""
func is_target(id: String) -> bool:return id==("qy_ma_yunpiao" if phase in ["camp","battle"] else "qy_ren_shoutian" if phase=="return" else GIVER)
func estate_open() -> bool:return phase in ["return","completed"]
func restored() -> bool:return phase in ["return","completed"]
func camp_open() -> bool:return phase in ["camp","battle","report","return","completed"]
func reset() -> void:clear_world();phase="available";signature="";gate_warned=false;favor_reward_granted=false
func track() -> void:game.quest_navigation.update_quest(ID,phase)
func handle_interaction(id: String) -> bool:
 if id=="ng_gatekeeper":
  _gate_dialogue();return true
 if id==GIVER:
  if game.exploration.area_name=="namgung_estate":
   if phase=="available":game.say(data.scenes.intro,_offer) if eligible() else game.say(data.scenes.locked)
   elif phase=="preparing":game.adventure_ui.choose("남궁 · 청애채 토벌","남궁서진과 무사4명이 함께 출정합니다.\n마운표와의 전투에서 패배하면 사망합니다. 출정 전 저장과 장비를 확인하세요.","준비됐소. 함께 갑시다",_march,"아직 정비할 일이 있소",Callable())
   elif phase=="report":game.say(data.scenes.reward,_paid)
   else:game.say([[GIVER,"산채의 길은 우리 무사들이 지키고 있소. 주민들의 삶이 돌아오는 것까지 살펴 주시오."]])
  else:game.say(data.scenes.camp)
  return true
 if id=="qy_ma_yunpiao" and game.exploration.area_name=="qingya_camp" and phase=="camp":
  game.adventure_ui.choose("청애채 · 채주와 결전","남궁서진이 공격과 방어를 지원합니다.\n패배하면 사망합니다. 지금은 돌아가 정비할 수도 있습니다.","마운표와 맞선다",_confront,"잠시 물러난다",Callable());return true
 if restored() and game.exploration.area_name=="qingya_hamlet" and str(id).begins_with("qy_"):
  if id=="qy_ren_shoutian" and phase=="return":game.say(data.scenes.return,_complete)
  else:
   var words={"qy_ren_shoutian":"곳간은 아직 수리 중이오. 그래도 오늘은 품을 들인 만큼 내일이 나아질 것 같소.","qy_liang_boan":"집은 무너져도 다시 세울 수 있지. 이번에는 우리를 내쫓을 산채가 없다는 말을 믿어 보려 하네.","qy_zhou_guiniang":"먼저 우물부터 치웠어요. 돌아온 사람들이 함께 물을 길으니 마을 같은 소리가 나네요.","qy_shi_xiaoman":"지붕에 쓸 나무를 옮기는 중이오. 이제 산길을 갈 때 곡식부터 빼앗길 걱정은 덜었소.","qy_ren_shouyi":"이번에는 형님과 함께 곳간을 고치고 있소. 다시 이곳에서 겨울을 날 수 있겠지요."}
   game.say([[id,words.get(id,"돌아와 지낼 곳이 생겼소. 고맙소.")]])
  return true
 if str(id).begins_with("ng_guard_"):game.say(data.scenes.guard);return true
 return false
func _offer() -> void:
 if phase=="available" and eligible():game.adventure_ui.choose("의뢰 · "+data.title,"남궁서진과 함께 청애채를 해체하고 주민들의 귀환을 확인하세요.\n보상: "+reward_label(),"이번에는 끝까지 함께하겠소",accept,"조금 더 생각하겠소",Callable())
func accept() -> void:
 if phase!="available" or not eligible():return
 phase="preparing";track();signature="";game.adventure_ui.notify("의뢰 수락 · "+data.title,"quest");game.say(data.scenes.accepted)
func _march() -> void:
 if phase!="preparing":return
 game.say(data.scenes.march,_arrive)
func _arrive() -> void:
 if phase!="preparing":return
 phase="camp";track();_travel("qingya_camp",[768,710]);game.say(data.scenes.camp)
func _travel(area: String,arrival: Array) -> void:
 preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":area,"arrival":arrival}})
func _confront() -> void:
 if phase=="camp":game.say(data.scenes.boss,_fight)
func _fight() -> void:
 if phase!="camp":return
 phase="battle";track();game.start_battle(data.encounter)
func in_battle() -> bool:return phase=="battle"
func after_victory() -> void:
 if not in_battle():return
 phase="report";game.battle.hide();game.state="explore";game.exploration.show();game.exploration.set_active(false)
 game.say(data.scenes.victory,_clear)
func _clear() -> void:game.say(data.scenes.clear,_cleared)
func _cleared() -> void:
 if phase!="report":return
 game.exploration.camera.enabled=true;game.top_hud.show();game.bottom_hint.text=preload("res://scripts/ui.gd").EXPLORATION_HINT;game.bottom_hint.show();game.music.play_track("voyage")
 track();signature="";game.exploration.load_area("qingya_camp");game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([768,610]));game.exploration.camera.snap_to_player();game.exploration.set_active(true)
 game.adventure_ui.notify("청애채 해체 · 남궁세가로 돌아가 서진에게 보고","quest")
func _paid() -> void:
 if phase!="report":return
 phase="return";game.money+=int(data.reward.money);game.progress.inventory[data.reward.elixir]+=int(data.reward.count)
 game.progress.add_favor(str(data.reward.faction),int(data.reward.favor));favor_reward_granted=true
 game.progress.progress_changed.emit({"event":"reward","id":data.reward.elixir})
 track();signature=""
 if game.exploration.area_name=="namgung_estate":
  var point=game.exploration.player.position;game.exploration.load_area("namgung_estate");game.exploration.player.position=game.exploration.safe_player_position(point);game.exploration.camera.snap_to_player()
 game.adventure_ui.notify("남궁 사례 · 1,000문 · 창천보원단 · 호의+30 · 외원 개방","coin")
func _complete() -> void:
 if phase!="return":return
 phase="completed"
 if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
 signature="";game.adventure_ui.notify("의뢰 완료 · 돌아올 터전","quest")
func goal(world) -> Dictionary:
 var target="qy_ma_yunpiao" if phase in ["camp","battle"] else "qy_ren_shoutian" if phase=="return" else GIVER
 for npc in world.ambient_nodes:
  if npc.get_meta("npc_id")==target:return {"position":npc.position,"label":game.quest_navigation.definitions[ID].stages[phase].label,"quest_title":data.title,"quest_id":ID,"stage_id":phase,"goal_id":target}
 var destination="qingya_camp" if phase=="camp" else "qingya_hamlet" if phase=="return" else "namgung_estate"
 var route={"namgung_estate":"travel:nanjing","nanjing":"travel:hamlet" if destination!="namgung_estate" else "travel:namgung","qingya_hamlet":"travel:camp" if destination=="qingya_camp" else "travel:nanjing","qingya_camp":"travel:hamlet","wuchang":"travel:qingya","alliance_office":"travel:office_exit","mountain_road":"travel:wuchang","changsha":"travel:road_east"}.get(world.area_name,"")
 for entry in world.travel_exits:
  if entry.id==route:return {"position":entry.position,"label":entry.name,"quest_title":data.title,"quest_id":ID,"stage_id":phase,"goal_id":route}
 return {}
func clear_world() -> void:
 for node in nodes:
  if is_instance_valid(node):game.exploration.ambient_nodes.erase(node);node.free()
 nodes.clear()
func _person(id: String,name: String,point: Array,frame: int,role: String) -> void:
 var w=game.exploration
 var spec={"id":id,"name":name,"point":point,"frame":frame,"role":role,"post":role,"quest_actor":true,"character_profile":{},"allow_road_post":true}
 if id=="ng_gatekeeper" or id.begins_with("ng_guard_"):
  spec.sprite_texture=warrior_visual.sprite;spec.sprite_region=warrior_visual.sprite_region
 w._populate_residents([spec])
 var npc=w.ambient_nodes.back();nodes.append(npc);var tag=w.occlusion_roots.pop_back();tag.reparent(npc);tag.position=Vector2.ZERO
 var marker=marker_for(id)
 if marker!="":
  var label=preload("res://scripts/ui.gd").label(npc,marker,Rect2(-40,-w.Metrics.CITIZEN_HEIGHT-105,80,92),68,Color("ffe14b"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_color_override("font_outline_color",Color("2b2614"));label.add_theme_constant_override("outline_size",5)
func refresh_world() -> void:
 var w=game.exploration;var sig=str(w.load_revision)+w.area_name+phase+str(eligible())
 if sig==signature:return
 signature=sig;clear_world()
 if w.area_name=="namgung_estate":
  gate_warned=false
  _person(GIVER,"남궁서진",w.city_data.story_posts.seojin,4,"남궁세가 소가주")
  _person("ng_gatekeeper","남궁 문지기",w.city_data.story_posts.gatekeeper,4,"정문 경비")
 elif w.area_name=="qingya_camp" and phase in ["camp","battle"]:
  _person(GIVER,"남궁서진",[920,710],4,"토벌 지휘")
  _person("qy_ma_yunpiao","마운표",[780,450],4,"청애채 채주")
 elif w.area_name=="qingya_camp" and camp_open():_person("ng_guard_1","남궁 무사",[800,710],4,"해체된 산채 경비")
 if (w.area_name=="namgung_estate" and phase=="preparing") or (w.area_name=="qingya_camp" and phase in ["camp","battle"]):
  for i in range(4):_person("ng_guard_"+str(i+1),"남궁 무사",w.city_data.story_posts.troops[i] if w.area_name=="namgung_estate" else [530+i*110,675],4,"토벌대")
 if is_instance_valid(w.regional_map):w.regional_map.resident_positions.assign(w.ambient_nodes.map(func(n):return n.position));w.regional_map._build_navigation();w.astar=w.regional_map.astar
func _gate_dialogue() -> void:
 gate_warned=true
 var text="내원은 아직 손님을 받지 않습니다. 용무가 있으시면 정문 밖의 소가주께 여쭈십시오."
 if phase in ["preparing","camp","battle","report"]:text="소가주께서 토벌 보고를 받으시기 전까지 내원 출입을 삼가 주십시오. 소가주께서도 정문 밖에서 뵙겠다고 하셨습니다."
 elif estate_open():text="소가주께서 길을 열라 명하셨습니다. 청애채 토벌에 힘써 주신 은혜를 잊지 않겠습니다. 외원으로 드시지요."
 game.say([["ng_gatekeeper",text]])
func _process(_delta: float) -> void:
 refresh_world()
 var w=game.exploration
 if w.area_name!="namgung_estate" or estate_open():return
 if w.player.position.y>w.city_data.outside_spawn[1]*3:gate_warned=false
 var approach=w.regional_map.rect(w.city_data.gate_approach).has_point(w.player.position)
 if not gate_warned and approach and Input.is_action_pressed("move_up") and w.active and game.state=="explore" and game.dialogue_lines.is_empty() and not game.adventure_ui.window.visible:
  _gate_dialogue()
func snapshot() -> Dictionary:return {"phase":phase,"favor_reward_granted":favor_reward_granted}
func valid(value) -> bool:
 if not value is Dictionary or value.get("phase") not in PHASES:return false
 if value.has("favor_reward_granted") and not value.favor_reward_granted is bool:return false
 return not value.get("favor_reward_granted",false) or value.phase in ["return","completed"]
func restore(value: Dictionary) -> void:
 phase=value.get("phase","available");favor_reward_granted=value.get("favor_reward_granted",false)
 # Loading an old paid save starts from its stored favor and adds the newly granted reward once.
 if estate_open() and not favor_reward_granted:
  game.progress.add_favor(str(data.reward.faction),int(data.reward.favor));favor_reward_granted=true
 signature="";refresh_world()
