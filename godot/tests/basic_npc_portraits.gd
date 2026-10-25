extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("BASIC_PORTRAITS: "+message)
func run() -> void:
	var cast=preload("res://scripts/dialogue_portraits.gd").new();root.add_child(cast)
	check(cast.basic_portraits.size()==18,"18 existing reusable pictures")
	check(cast.COMMON_POOL.male.size()==10 and cast.COMMON_POOL.female.size()==8,"male 10 / female 8")
	var paths: Array=[]
	for id in cast.basic_portraits:
		var entry=cast.basic_portraits[id]
		check(ResourceLoader.exists(entry.path) and entry.path not in paths,"existing unique asset: "+id)
		check(cast.framing.profiles.has(entry.path),"existing face framing retained")
		check(cast.texture_for({"basic_portrait":id}).resource_path==entry.path,"stable shared ID resolves: "+id)
		paths.append(entry.path)
	for gender in ["male","female"]:
		var participants: Array=[]
		for i in range(cast.COMMON_POOL[gender].size()):participants.append({"name":"ordinary resident "+str(i),"extra":gender+"_middle"})
		var allocated=cast.allocate_portraits(participants);var chosen: Array=[]
		for actor in allocated:
			check(not actor.get("portrait_unavailable",false) and actor.portrait not in chosen,"same-gender conversation stays unique across expanded pool")
			chosen.append(actor.portrait)
		check(chosen.any(func(p):return "/wuchang/" in p),"Wuchang images participate in reuse")
	for id in cast.ACTORS:
		if str(id).begins_with("wc_") and cast.ACTORS[id].has("portrait"):check(cast.texture_for(cast.ACTORS[id]).resource_path==cast.ACTORS[id].portrait,"original Wuchang identity retains its illustration")
	check(cast.texture_for(cast.ACTORS.wc_jin_munsu).resource_path==cast.basic_portraits.male_common_b.path,"new civilian reuses existing basic image")
	var qingya=JSON.parse_string(FileAccess.get_file_as_string("res://data/qingya_characters.json"))
	check(qingya.npcs.size()==8,"five villagers, two bandits and existing chief registered")
	var qingya_paths: Array=[]
	for npc in qingya.npcs:
		check(cast.ACTORS.has(npc.id) and cast.ACTORS[npc.id].name==npc.name,"Qingya dialogue identity: "+npc.id)
		var texture=cast.texture_for(cast.ACTORS[npc.id])
		check(texture!=null,"Qingya texture loads: "+npc.id)
		if texture==null:continue
		check(texture.resource_path not in qingya_paths,"all Qingya cast have distinct images")
		check(cast.framing.profiles.has(texture.resource_path),"Qingya framing exists")
		qingya_paths.append(texture.resource_path)
		for line in npc.dialogue:check(cast.ACTORS.has(line[0]) and not str(line[1]).is_empty(),"valid dialogue speaker and text")
	check(cast.texture_for(cast.ACTORS.qy_hou_liu).resource_path==cast.texture_for(cast.ACTORS.bandit_raider).resource_path,"existing bandit illustration reused without changing old actor")
	for group in [["hero","qy_ren_shoutian","qy_liang_boan","qy_zhou_guiniang"],["hero","qy_shi_xiaoman","qy_ren_shouyi"],["hero","qy_hou_liu","qy_ding_kui","qy_ma_yunpiao"]]:
		var participants: Array=[]
		for id in group:
			var actor: Dictionary=cast.ACTORS[id].duplicate();actor.id=id;participants.append(actor)
		cast.set_participants(participants)
		var unique: Dictionary={}
		for path in cast.portrait_choices.values():unique[path]=true
		check(unique.size()==group.size() and not unique.has(""),"Qingya staged conversation has unique visible portraits")
		cast.set_speaker(group[1])
		for id in group:check(cast.portraits[id].self_modulate==(Color.WHITE if id==group[1] else cast.DIM),"Qingya active speaker is highlighted")
	cast.queue_free();await process_frame
	print("GODOT_BASIC_PORTRAITS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
