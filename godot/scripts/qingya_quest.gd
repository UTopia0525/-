extends Node
## Optional two-way village incident; rewards and abandoned-village state are persistent.
const ID="qingya_village"
const GIVER="qy_ren_shoutian"
const UI=preload("res://scripts/ui.gd")
const STAGES=["available","investigate","confront","camp","decision","fight_sentry","fight_chief","ready","reward","completed"]
const RESIDENTS=["qy_ren_shoutian","qy_liang_boan","qy_zhou_guiniang","qy_shi_xiaoman"]
const INVESTIGATORS={"qy_liang_boan":"elder","qy_zhou_guiniang":"woman","qy_shi_xiaoman":"young"}
const POINTS={"qy_ren_shoutian":[920,625],"qy_liang_boan":[660,330],"qy_zhou_guiniang":[1010,620],"qy_shi_xiaoman":[605,825],"qy_ren_shouyi":[1195,655],"qy_hou_liu":[840,445],"qy_ding_kui":[935,835],"qy_ma_yunpiao":[770,455]}
const RUINS={"store":[560,250],"home":[1210,855],"place":[920,625]}
var game
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/qingya_quest.json"))
var people: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/qingya_characters.json"))
var phase="available"
var heard: Array=[]
var admitted=false
var captive_heard=false
var branch=""
var reward_stat=""
var departed=false
var ruined=false
var ruin_intro=false
var ruin_checks: Array=[]
var regret_seen=false
var nodes: Array[Node]=[]
var signature=""
func _ready() -> void:
	var stages={}
	for id in ["offer","investigate","confront","camp","decision","report","reward","completed"]:
		stages[id]={"goals":[],"label":{"offer":"삼거리 산촌에서 임수전에게 사정 묻기","investigate":"양백안·주계랑·석소만에게 마을 사정 듣기","confront":"북쪽 길로 찾아온 징수 산적 후육과 대면","camp":"청애채 문지기·붙잡힌 주민을 만나고 채주에게 가기","decision":"마운표에게 토벌 또는 현상 유지의 뜻 전하기","report":"산촌 임수전에게 돌아가 결과 전하기","reward":"임수전에게 보상받을 능력치 고르기","completed":"마을에서 내린 선택을 돌아본다"}[id]}
	game.quest_navigation.definitions[ID]={"title":data.title,"stages":stages}
func reset() -> void:
	clear_world();phase="available";heard=[];admitted=false;captive_heard=false;branch="";reward_stat="";departed=false;ruined=false;ruin_intro=false;ruin_checks=[];regret_seen=false;signature=""
func status() -> String:return "ready" if phase in ["ready","reward"] else "completed" if phase=="completed" else "available" if phase=="available" else "active"
func stage() -> String:return {"available":"offer","fight_sentry":"confront","fight_chief":"decision","ready":"report"}.get(phase,phase)
func reward_label() -> String:return "토벌:200문 + 근력/기민/근골 중1종+5 · 미토벌:오성+5 (상한100)"
func marker_for(id: String) -> String:return ("!" if phase=="available" else "?" if phase in ["ready","reward"] else "") if id==GIVER and not ruined else ""
func track() -> void:game.quest_navigation.update_quest(ID,stage())
func in_battle() -> bool:return phase in ["fight_sentry","fight_chief"]
func targets() -> Array:
	match phase:
		"available","ready","reward":return [GIVER]
		"investigate":return INVESTIGATORS.keys().filter(func(id):return id not in heard)
		"confront","fight_sentry":return ["qy_hou_liu"]
		"camp":return ["qy_ding_kui"] if not admitted else ["qy_ren_shouyi"] if not captive_heard else ["qy_ma_yunpiao"]
		"decision","fight_chief":return ["qy_ma_yunpiao"]
	return []
func is_target(id: String) -> bool:return id in targets() and phase!="available"
func play(id: String,done: Callable=Callable()) -> void:game.say(data.scenes[id],done)
func handle_interaction(id: String) -> bool:
	if id.begins_with("qingya_ruin:") and ruined:
		var key=id.trim_prefix("qingya_ruin:")
		if RUINS.has(key):play("ruin_"+key,_ruin_checked.bind(key));return true
	if not id.begins_with("qy_"):return false
	if id==GIVER:
		match phase:
			"available":play("intro",_offer)
			"ready":play("report_"+branch,_report_done)
			"reward":_choose_stat()
			"completed":game.say([[GIVER,"받은 은혜는 잊지 않겠소. 먼 길 조심하시오." if branch=="assault" else "올해도 어떻게든 버텨봐야겠지요."]])
			_:game.say([[GIVER,"아우도 걱정이지만…… 마을 사람들의 이야기도 들어주시오."]])
		return true
	if branch=="assault" and phase in ["ready","reward","completed"]:
		var aftermath={"qy_liang_boan":"수고했네. 이제 이곳에 남은 우리가 앞날을 살펴야겠지.","qy_zhou_guiniang":"오늘은 솥에 물만 끓이지 않아도 되겠어요. 수전네에도 밥 한 그릇 가져다주려 해요.","qy_shi_xiaoman":"장작을 팔면 어머니 약부터 지을 거요. 우리 몫을 온전히 쥐는 게 얼마 만인지 모르겠소.","qy_ren_shouyi":"돌아왔소. 형님 얼굴을 보니 이제야 다리에 힘이 풀리는군요. 고맙소."}
		if aftermath.has(id):game.say([[id,aftermath[id]]]);return true
	if branch=="maintain" and phase=="completed":
		var aftermath={"qy_liang_boan":"소협을 탓하지 않네. 모두를 대신해 짊어질 수 있는 일은 아니었지.","qy_zhou_guiniang":"저녁 지을 시간은 다가오는데…… 남은 곡식부터 다시 세어봐야겠어요.","qy_shi_xiaoman":"내일도 고갯길에 올라야지. 빼앗길 몫까지 벌려면 일찍 나서야 하니까."}
		if aftermath.has(id):game.say([[id,aftermath[id]]]);return true
	if phase=="investigate" and INVESTIGATORS.has(id):play(INVESTIGATORS[id],_heard.bind(id));return true
	if id=="qy_hou_liu" and phase=="confront":play("confront",_confront_choice);return true
	if id=="qy_ding_kui" and phase in ["camp","decision"]:play("gate",_admit);return true
	if id=="qy_ren_shouyi" and phase in ["camp","decision"]:
		if admitted:play("captive",_captive_done)
		else:game.say([["hero","먼저 문지기에게 용건을 밝혀야겠다."]])
		return true
	if id=="qy_ma_yunpiao":
		if phase in ["camp","decision"] and admitted and captive_heard:play("chief",_decision)
		elif phase in ["available","investigate","confront"]:game.say([[id,"산촌에서 왔다고? 먼저 그곳 사람들과 이야기를 해보게."]])
		else:game.say([["hero","문지기와 붙잡힌 주민에게 먼저 사정을 듣자."]])
		return true
	for person in people.npcs:
		if person.id==id:game.say(person.dialogue);return true
	return true
func _offer() -> void:game.adventure_ui.choose(data.title,"주민들의 사정을 듣고 도울지 결정합니다. 다른 의뢰와 함께 진행할 수 있습니다.","도울 방법을 찾아보겠소",accept,"지금은 발길을 멈추기 어렵소",decline)
func accept() -> void:
	if phase!="available":return
	phase="investigate";track();refresh_world();game.adventure_ui.notify("의뢰 수락 · "+data.title,"quest");play("accept")
func decline() -> void:play("decline")
func _heard(id: String) -> void:
	if phase!="investigate":return
	if id not in heard:heard.append(id)
	if heard.size()==3:phase="confront";game.adventure_ui.notify("북쪽 길로 징수 산적이 찾아왔다.","quest")
	track();refresh_world()
func _confront_choice() -> void:game.adventure_ui.choose("징수 산적과 대면","여기서의 대응은 최종 해결 방향을 정하지 않습니다.","채주에게 직접 듣겠소",_pass,"그 자루에서 손을 떼시오",_fight_sentry)
func _pass() -> void:play("pass",_enter_camp)
func _enter_camp() -> void:phase="camp";track();refresh_world()
func _fight_sentry() -> void:
	if phase!="confront":return
	phase="fight_sentry";game.start_battle(data.encounters[0])
func _admit() -> void:admitted=true;track();refresh_world()
func _captive_done() -> void:captive_heard=true;track();refresh_world()
func _decision() -> void:
	phase="decision";track();refresh_world()
	game.adventure_ui.choose("떠나는 자, 남는 자","청애채를 토벌할지, 개입을 거두고 현상을 유지할지 선택합니다. 결정을 내리기 전 창을 닫고 정비·저장한 뒤 다시 대화할 수 있습니다.","청애채를 토벌한다",_confirm_assault,"개입을 거두고 돌아간다",_confirm_maintain)
func _confirm_assault() -> void:game.adventure_ui.choose("토벌 확인","승리하면 청애채의 징수는 중단됩니다. 도원이 떠난 뒤까지 지켜줄 수 있는지는 알 수 없습니다.","토벌한다",_assault,"더 생각한다",_later)
func _confirm_maintain() -> void:game.adventure_ui.choose("현상 유지 확인","싸움을 거두면 청애채와 주민들의 관계는 그대로 남습니다.","칼을 거둔다",_maintain,"더 생각한다",_later)
func _later() -> void:game.say([["hero","섣불리 정할 일은 아니다. 마음을 정리한 뒤 다시 오자."]])
func _assault() -> void:
	if phase!="decision":return
	play("assault",_fight_chief)
func _fight_chief() -> void:phase="fight_chief";game.start_battle(data.encounters[1])
func _maintain() -> void:
	if phase!="decision":return
	branch="maintain";play("stand_down",_ready_report)
func _ready_report() -> void:phase="ready";track();refresh_world()
func after_victory() -> void:
	var chief=phase=="fight_chief"
	phase="ready" if chief else "camp"
	if chief:branch="assault"
	_resume();play("chief_win" if chief else "sentry_win",_after_battle)
func after_defeat() -> void:
	phase="decision" if phase=="fight_chief" else "confront"
	_resume();play("loss",_after_battle)
func _resume() -> void:
	game.battle.hide();game.state="explore";game.exploration.show();game.exploration.camera.enabled=true;game.exploration.camera.snap_to_player();game.top_hud.show();game.music.play_track("voyage")
func _after_battle() -> void:track();refresh_world()
func _report_done() -> void:
	if phase!="ready":return
	if branch=="maintain":
		game.progress.stats.insight=mini(100,int(game.progress.stats.insight)+5);_complete();game.adventure_ui.notify("의뢰 완료 · 오성+5 (상한100)","quest")
	else:phase="reward";track();refresh_world();_choose_stat()
func _choose_stat() -> void:game.adventure_ui.choose("토벌 보상 · 능력치 선택","200문과 함께 근력·기민·근골 중 하나를5 올립니다. 선택과 지급은 한 번만 적용됩니다. (상한100)","근력+5",_grant.bind("strength"),"기민 또는 근골",_other_stats)
func _other_stats() -> void:game.adventure_ui.choose("토벌 보상 · 능력치 선택","근력은 앞선 선택에서 고를 수 있습니다. 창을 닫았다면 임수전에게 다시 말하세요.","기민+5",_grant.bind("agility"),"근골+5",_grant.bind("constitution"))
func _grant(stat: String) -> void:
	if phase!="reward" or stat not in ["strength","agility","constitution"]:return
	reward_stat=stat;game.money+=200;game.progress.stats[stat]=mini(100,int(game.progress.stats[stat])+5);_complete();game.adventure_ui.notify("의뢰 완료 · 200문 · 선택 능력치+5 (상한100)","quest")
func _complete() -> void:
	phase="completed"
	if game.quest_navigation.quest_id==ID:game.quest_navigation.clear()
	refresh_world()
func before_travel(source: String,destination: String) -> void:
	if phase=="completed" and branch=="assault" and source=="qingya_hamlet" and destination!="qingya_hamlet":departed=true
func on_arrive(destination: String) -> void:
	if phase=="completed" and branch=="assault" and departed and destination=="qingya_hamlet":ruined=true;signature=""
func _ruin_checked(key: String) -> void:
	if key not in ruin_checks:ruin_checks.append(key)
	if ruin_checks.size()==3 and not regret_seen:play("regret",_regret_done)
func _regret_done() -> void:regret_seen=true;game.adventure_ui.notify("마을에 남겨진 흔적을 돌아보았다.","quest")
func goal(world) -> Dictionary:
	var point=Vector2.ZERO;var label=game.quest_navigation.definitions[ID].stages[stage()].label
	var destination="qingya_hamlet" if phase in ["available","investigate","confront","fight_sentry","ready","reward","completed"] else "qingya_camp"
	if world.area_name==destination:
		var best=INF
		for npc in world.ambient_nodes:
			if npc.get_meta("npc_id","") not in targets():continue
			var dist=world.player.position.distance_squared_to(npc.position)
			if dist<best:best=dist;point=npc.position
	else:
		var exit_id="travel:qingya" if world.area_name=="wuchang" else "travel:hamlet" if world.area_name=="qingya_camp" else "travel:camp" if world.area_name=="qingya_hamlet" else "travel:wuchang" if world.area_name=="mountain_road" else "travel:office_exit" if world.area_name=="alliance_office" else "travel:road_east"
		for entry in world.travel_exits:
			if entry.id==exit_id:point=entry.position;label=entry.name+" · 산촌 의뢰를 따라 이동";break
	if point==Vector2.ZERO:return {}
	return {"position":point,"label":label,"quest_title":data.title,"goal_id":stage(),"quest_id":ID,"stage_id":stage()}
func clear_world() -> void:
	for node in nodes:
		if not is_instance_valid(node):continue
		game.exploration.ambient_nodes.erase(node);node.free()
	nodes.clear()
	game.exploration.objectives=game.exploration.objectives.filter(func(o):return not str(o.id).begins_with("qingya_ruin:"))
func refresh_world() -> void:
	var world=game.exploration
	var next_signature="%d:%s:%s:%s:%s:%s:%s" % [world.load_revision,world.area_name,phase,heard,admitted,captive_heard,ruined]
	if signature==next_signature:return
	signature=next_signature;clear_world()
	if world.area_name not in ["qingya_hamlet","qingya_camp"]:return
	if world.area_name=="qingya_hamlet" and ruined:
		for key in RUINS:
			var node=Node2D.new();node.position=world.safe_player_position(world.city_point(RUINS[key]));world.decorations.add_child(node);nodes.append(node)
			var mark=UI.label(node,"◆ 조사",Rect2(-70,-65,140,35),24,UI.GOLD);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			world.objectives.append({"id":"qingya_ruin:"+key,"goal_id":key,"name":{"store":"불탄 공동 창고","home":"열린 빈집","place":"임수전을 만났던 자리"}[key],"node":node,"position":node.position,"frame":-1})
	else:
		var ids: Array=RESIDENTS.duplicate() if world.area_name=="qingya_hamlet" else ["qy_ding_kui","qy_ma_yunpiao"]
		if world.area_name=="qingya_hamlet" and phase in ["confront","fight_sentry"]:ids.append("qy_hou_liu")
		if world.area_name=="qingya_hamlet" and branch=="assault":ids.append("qy_ren_shouyi")
		if world.area_name=="qingya_camp":
			if branch=="assault":ids=[]
			elif admitted:ids.append("qy_ren_shouyi")
		for id in ids:
			var person: Dictionary={}
			for spec in people.npcs:
				if spec.id==id:person=spec.duplicate(true);break
			person.point=[1050,820] if id=="qy_ren_shouyi" and world.area_name=="qingya_hamlet" else POINTS[id]
			person.role={"qy_ren_shoutian":"농부","qy_liang_boan":"마을 어른","qy_zhou_guiniang":"주민","qy_shi_xiaoman":"나무꾼","qy_ren_shouyi":"붙잡힌 주민","qy_hou_liu":"징수 산적","qy_ding_kui":"문지기","qy_ma_yunpiao":"채주"}[id]
			person.post=person.role
			person.quest_actor=true;person.character_profile={};person.allow_road_post=true
			world._populate_residents([person]);var npc=world.ambient_nodes.back();nodes.append(npc)
			var tag=world.occlusion_roots.pop_back();tag.reparent(npc);tag.position=Vector2.ZERO
			var marker=marker_for(id)
			if not marker.is_empty():
				var mark=UI.label(npc,marker,Rect2(-40,-world.Metrics.CITIZEN_HEIGHT-105,80,92),68,Color("ffe14b"));mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mark.z_index=6
				mark.add_theme_color_override("font_outline_color",Color("2b2614"));mark.add_theme_constant_override("outline_size",5)
	world.regional_map.resident_positions.assign(world.ambient_nodes.map(func(n):return n.position));world.regional_map._build_navigation();world.astar=world.regional_map.astar
func _process(_delta: float) -> void:
	refresh_world()
	if ruined and not ruin_intro and game.exploration.area_name=="qingya_hamlet" and game.exploration.active and game.state=="explore" and game.dialogue_lines.is_empty() and not game.get_tree().paused:
		ruin_intro=true;play("ruin_intro")
func snapshot() -> Dictionary:return {"phase":phase,"heard":heard.duplicate(),"admitted":admitted,"captive_heard":captive_heard,"branch":branch,"reward_stat":reward_stat,"departed":departed,"ruined":ruined,"ruin_intro":ruin_intro,"ruin_checks":ruin_checks.duplicate(),"regret_seen":regret_seen}
func valid(v) -> bool:
	if not v is Dictionary or v.get("phase") not in STAGES:return false
	for key in ["admitted","captive_heard","departed","ruined","ruin_intro","regret_seen"]:
		if not v.get(key) is bool:return false
	if v.get("branch") not in ["","assault","maintain"] or v.get("reward_stat") not in ["","strength","agility","constitution"]:return false
	for pair in [["heard",INVESTIGATORS.keys()],["ruin_checks",RUINS.keys()]]:
		if not v.get(pair[0]) is Array:return false
		for id in v[pair[0]]:
			if id not in pair[1] or v[pair[0]].count(id)!=1:return false
	if v.phase in ["confront","camp","decision","fight_sentry","fight_chief","ready","reward","completed"] and v.heard.size()!=3:return false
	if v.phase in ["decision","fight_chief"] and (not v.admitted or not v.captive_heard):return false
	if v.phase in ["ready","reward","completed"] and v.branch=="":return false
	if v.phase=="reward" and v.branch!="assault":return false
	if v.phase=="completed" and (v.reward_stat=="")!=(v.branch=="maintain"):return false
	if v.phase!="completed" and (not v.reward_stat.is_empty() or v.departed or v.ruined):return false
	if v.departed and v.branch!="assault":return false
	if v.captive_heard and not v.admitted:return false
	if v.ruined and (not v.departed or v.branch!="assault"):return false
	if (v.ruin_intro or not v.ruin_checks.is_empty() or v.regret_seen) and not v.ruined:return false
	if v.regret_seen and v.ruin_checks.size()!=3:return false
	return true
func restore(value: Dictionary) -> void:
	phase=value.phase;heard=value.heard.duplicate();admitted=value.admitted;captive_heard=value.captive_heard;branch=value.branch;reward_stat=value.reward_stat;departed=value.departed;ruined=value.ruined;ruin_intro=value.ruin_intro;ruin_checks=value.ruin_checks.duplicate();regret_seen=value.regret_seen;signature=""
