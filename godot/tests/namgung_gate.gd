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
 var q=game.namgung_campaign;q._travel("namgung_estate",[1152,1485]);var w=game.exploration
 var inside=w.city_point([1152,750]);var outside=w.city_point([1152,1485])
 check(not w.regional_map.data.admission_open,"initial gate closed")
 var motif=Rect2(w.city_data.courtyard_motif_bounds[0],w.city_data.courtyard_motif_bounds[1],w.city_data.courtyard_motif_bounds[2],w.city_data.courtyard_motif_bounds[3])
 for spec in w.city_data.objects:
  if spec.prefab in ["ng_main","ng_residence","ng_training","ng_gate"]:
   check(not motif.intersects(Rect2(spec.rect[0],spec.rect[1],spec.rect[2],spec.rect[3])),"building never covers central motif: "+spec.id)
 # Shared wall art must retain the Wuchang world-unit scale, even on the wider estate.
 for spec in w.city_data.objects:
  if spec.prefab=="wall_h":
   check(spec.rect[2]*3<=280.1 and is_equal_approx(float(spec.rect[3])*3,168.0),"horizontal wall uses city scale")
  if spec.prefab=="wall_v":
   check(absf(float(spec.rect[2])*3-92.0)<0.02 and spec.rect[3]*3<=232.1,"vertical wall uses city scale")
 var guard=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")=="ng_gatekeeper")[0]
 check(guard.get_child(1).texture.atlas.resource_path==q.warrior_visual.sprite,"gatekeeper uses dedicated Namgung map sprite")
 check(game.PORTRAITS.ACTORS.ng_gatekeeper.portrait==q.warrior_visual.portrait,"gatekeeper uses dedicated portrait")
 check(w.regional_map.path_to(outside,inside).is_empty(),"gate collision and navigation block admission")
 check(w.regional_map.path_to(w.city_point([100,750]),inside).is_empty(),"side-wall bypass blocked")
 check(w.safe_player_position(inside).y>=1435*3,"old interior position moved to entrance")
 w.player.position=w.city_point([1152,1460]);Input.action_press("move_up");q._process(0);Input.action_release("move_up")
 check(not game.dialogue_lines.is_empty() and game.dialogue_lines[0][0]=="ng_gatekeeper","walking toward gate triggers keeper")
 finish_dialogue();q.gate_warned=true;w.player.position=w.city_point([1152,1448]);w.set_active(true)
 Input.action_press("move_up");await create_timer(.9).timeout;Input.action_release("move_up")
 check(w.player.position.y>=1435*3,"real keyboard movement cannot pass closed gate")
 check(game.save_system.write_slot(1),"outside save valid")
 var d=game.save_system.read_slot(1);d.world.position=[2304,1650];d.world.layout_version=1
 var f=FileAccess.open(game.save_system.path(2),FileAccess.WRITE);f.store_string(JSON.stringify(d));f.close()
 check(game.save_system.load_slot(2) and w.player.position.y>=1435*3,"legacy inside save exits safely")
 q=game.namgung_campaign
 for phase in ["preparing","report"]:
  q.phase=phase;w.load_area("namgung_estate");check(not w.regional_map.data.admission_open,"closed before payout: "+phase)
 q.phase="return";w.load_area("namgung_estate")
 check(w.regional_map.data.admission_open and not w.regional_map.path_to(outside,inside).is_empty(),"rewarded quest opens courtyard before reunion")
 check(w.safe_player_position(inside)==inside,"rewarded visitor remains inside")
 check(q.handle_interaction("ng_gatekeeper"),"keeper remains interactive after completion");finish_dialogue()
 game.reset();await create_timer(.8).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame
 print("NAMGUNG_GATE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
