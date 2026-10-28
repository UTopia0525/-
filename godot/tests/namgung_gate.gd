extends SceneTree
var game
var failed=false
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("NAMGUNG_GATE: "+msg)
func _initialize() -> void:run.call_deferred()
func finish_dialogue() -> void:
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"]);game.start_wuchang()
 var q=game.namgung_campaign;q._travel("namgung_estate",[768,900]);var w=game.exploration
 var inside=w.city_point([768,550]);var outside=w.city_point([768,900])
 check(not w.regional_map.data.admission_open,"initial gate closed")
 check(w.regional_map.path_to(outside,inside).is_empty(),"gate collision and navigation block admission")
 check(w.regional_map.path_to(w.city_point([100,550]),inside).is_empty(),"side-wall bypass blocked")
 check(w.safe_player_position(inside).y>=830*3,"old interior position moved to entrance")
 w.player.position=w.city_point([768,860]);Input.action_press("move_up");q._process(0);Input.action_release("move_up")
 check(not game.dialogue_lines.is_empty() and game.dialogue_lines[0][0]=="ng_gatekeeper","walking toward gate triggers keeper")
 finish_dialogue();q.gate_warned=true;w.player.position=w.city_point([768,850]);w.set_active(true)
 Input.action_press("move_up");await create_timer(.9).timeout;Input.action_release("move_up")
 check(w.player.position.y>=830*3,"real keyboard movement cannot pass closed gate")
 check(game.save_system.write_slot(1),"outside save valid")
 var d=game.save_system.read_slot(1);d.world.position=[2304,1650]
 var f=FileAccess.open(game.save_system.path(2),FileAccess.WRITE);f.store_string(JSON.stringify(d));f.close()
 check(game.save_system.load_slot(2) and w.player.position.y>=830*3,"legacy inside save exits safely")
 q=game.namgung_campaign
 for phase in ["preparing","report","return"]:
  q.phase=phase;w.load_area("namgung_estate");check(not w.regional_map.data.admission_open,"still closed until reunion: "+phase)
 q.phase="completed";w.load_area("namgung_estate")
 check(w.regional_map.data.admission_open and not w.regional_map.path_to(outside,inside).is_empty(),"completed quest opens courtyard")
 check(w.safe_player_position(inside)==inside,"completed visitor remains inside")
 check(q.handle_interaction("ng_gatekeeper"),"keeper remains interactive after completion");finish_dialogue()
 game.reset();await create_timer(.8).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame
 print("NAMGUNG_GATE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
