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
		if str(id).begins_with("wc_"):check(cast.texture_for(cast.ACTORS[id]).resource_path==cast.ACTORS[id].portrait,"original Wuchang identity retains its illustration")
	cast.queue_free();await process_frame
	print("GODOT_BASIC_PORTRAITS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
