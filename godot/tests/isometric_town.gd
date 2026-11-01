extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var world
var q
var failed=false
var checks=0
var walked=0
var trace=[]
var loop_frames=0
var npc_review={}
var trace_output=""
func record(label: String) -> void:
 trace.append({"event":label,"quests":q.phases.duplicate(),"tracked":q.navigation.quest_id,"money":q.money,"owned":q.progress.inventory.bear_strength_pill,"completions":q.completions.duplicate()})
func quest_snapshot() -> Array:
 return [q.phases.duplicate(),q.completions.duplicate(),q.navigation.quest_id,q.navigation.stage_id,q.selected_quest,q.money,q.progress.inventory.duplicate(true)]
func reinitialize() -> void:
 var before=quest_snapshot()
 check(q.initialize_quests() and quest_snapshot()==before,"reinitialization preserves progress/counts/tracking/selection/wallet/inventory")
func indicators() -> void:
 await frames(2)
 for id in q.definitions:
  var label: Label=q.marker_nodes[id].label
  check(label.visible==(q.phases[id] in ["available","ready"]),"marker visibility follows its own quest "+id)
  if label.visible:check(label.text==("!" if q.phases[id]=="available" else "?"),"correct offer/report marker "+id)
 await tap(KEY_Q)
 for id in q.definitions:
  var state={"available":"수락 가능","active":"진행 중","ready":"보고 가능","completed":"완료"}[q.phases[id]]
  check(q.quest_buttons[id].text==q.definitions[id].title+" · "+state,"Q row follows its own quest "+id)
 await tap(KEY_Q)
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):trace_output=arg.trim_prefix("--out=")
 run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failed=true;push_error("ISO_TOWN: "+message)
func frames(n: int) -> void:
 for i in range(n):await physics_frame
func key(code: int,down: bool,echo=false) -> void:
 var e=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=down;e.echo=echo;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame;await process_frame
func tap(code: int) -> void:await key(code,true);await key(code,false)
func click(button: Button) -> void:
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=button.get_global_rect().get_center();e.pressed=down;Input.parse_input_event(e);await process_frame;await process_frame
func finish_dialogue() -> void:
 for i in range(8):
  if not world.passage.active_world().dialogue.active:break
  if world.passage.active_world().dialogue.choosing:break
  await tap(KEY_F)
func approach(npc_id: String) -> void:
 for npc in world.npcs:
  if npc.patrol!=null:npc.patrol.pause=100
  npc.set_logical(Vector2(22.6,16+npc.traffic_rank*.5))
 # Let the physics server flush parked bodies before reusing their old spot.
 await frames(2)
 var npc
 for person in world.npcs:
  if str(person.name)==npc_id:npc=person
 npc.set_logical(Vector2(8.1,10.7));world.actor.set_logical(Vector2(8.1,11.45));world.interaction.invalidate();await frames(3)
 check(world.interaction.choose_target()==npc,"reachable target "+npc_id)
func accept(id: String,yes=true) -> void:
 await approach(q.definitions[id].giver);await tap(KEY_F);await finish_dialogue()
 check(world.dialogue.choosing,"choice shown "+id)
 await key(KEY_F,true);await key(KEY_F,true,true);await frames(3)
 check(world.dialogue.choosing and q.phases[id]=="available","held/repeated F cannot accept or skip choice")
 await key(KEY_F,false)
 await tap(KEY_1 if yes else KEY_2);await finish_dialogue()
 check(q.phases[id]==("active" if yes else "available"),"accept/decline phase "+id)
func enter() -> void:
 world.actor.set_logical(Vector2(14.605814,11.562791));world.interaction.invalidate();await frames(3)
 check(world.passage.offer(),"entry available")
 await key(KEY_F,true);await world.passage.completed;await key(KEY_F,false);await frames(3)
func leave() -> void:
 world.passage.room.actor.set_logical(Vector2(3.7,5.35));await frames(3)
 await key(KEY_F,true);await world.passage.completed;await key(KEY_F,false);await frames(3)
func inspect(id: String) -> void:
 var host=world.passage.active_world()
 host.actor.set_logical(Vector2(2.7,1.3) if id=="iso_errand" else Vector2(6.325,4.8));await frames(3)
 check(q.inspect_id()=="","cannot inspect from behind furniture/cargo")
 host.actor.set_logical(Vector2(2.7,2.8) if id=="iso_errand" else Vector2(6.325,6.05));await frames(3)
 check(q.inspect_id()==id,"appropriate investigation "+id)
 await tap(KEY_F);await finish_dialogue();check(q.phases[id]=="ready","investigate completes only after lines "+id)
func report(id: String) -> void:
 await approach(q.definitions[id].giver);await tap(KEY_F);await finish_dialogue()
 check(q.phases[id]=="completed" and q.completions[id]==1,"report exactly once "+id)
 await tap(KEY_F);await finish_dialogue();check(q.completions[id]==1,"repeat report harmless "+id)
func steer(direction: Vector2) -> void:
 var p=Space.project(direction).normalized()
 for pair in [["iso_left",maxf(0,-p.x)],["iso_right",maxf(0,p.x)],["iso_up",maxf(0,-p.y)],["iso_down",maxf(0,p.y)]]:
  Input.action_release(pair[0])
  if pair[1]>0:Input.action_press(pair[0],pair[1])
func walk_to(point: Vector2) -> void:
 for i in range(600):
  if world.actor.logical.distance_to(point)<.09:break
  steer(point-world.actor.logical);await physics_frame;walked+=1
  check(world.depth_cycles==0,"acyclic sort during traversal")
  for prop in world.props:
   for rect in prop.physical_footprints:check(world.actor.logical.distance_to(world.actor.logical.clamp(rect.position,rect.end))>=.142,"walk clears "+str(prop.name))
 steer(Vector2.ZERO);await physics_frame;check(world.actor.logical.distance_to(point)<.12,"keyboard reaches "+str(point))
func start() -> void:
 world=load("res://prototypes/isometric/changsha.tscn").instantiate();root.add_child(world);q=world.errand;await frames(4);world.patrols_enabled=false
func park_npcs() -> void:
 for npc in world.npcs:npc.set_logical(Vector2(22.6,16+npc.traffic_rank*.5))
 await frames(2);world.interaction.invalidate()
func investigation_priority() -> void:
 await park_npcs()
 q.giver("iso_cargo").set_logical(Vector2(6.9,6.05));world.actor.set_logical(Vector2(6.325,6.05));world.interaction.invalidate();await frames(3)
 check(world.interaction.visible and not q.inspect_hint.visible and not world.passage.caption.visible,"NPC beats overlapping investigation, one F caption")
 await tap(KEY_F);await finish_dialogue();check(q.phases.iso_cargo=="active","progress dialogue doesn't investigate")
 await park_npcs();await frames(3);check(q.inspect_id()=="iso_cargo","investigation returns after NPC leaves")
func target_checks() -> void:
 await park_npcs();world.npcs[0].set_logical(Vector2(14.9,11.9));world.actor.set_logical(Vector2(14.605814,11.562791));world.interaction.invalidate();await frames(3)
 check(world.interaction.visible and not world.passage.caption.visible and not q.inspect_hint.visible,"NPC/door overlap has exactly one F caption")
 await tap(KEY_F);check(world.dialogue.active and not is_instance_valid(world.passage.room),"overlapping F talks, does not enter");await finish_dialogue()
 await park_npcs();world.npcs[0].set_logical(Vector2(3.8,5));world.actor.set_logical(Vector2(4.6,5));world.interaction.invalidate();await frames(3)
 check(world.interaction.choose_target()==null,"wall blocks closer NPC")
 await tap(KEY_F);check(not world.dialogue.active and not is_instance_valid(world.passage.room),"blocked F cannot trigger a hidden action")
 await park_npcs();world.npcs[0].set_logical(Vector2(8.1,10.7));world.npcs[1].set_logical(Vector2(8.8,11.45));world.actor.set_logical(Vector2(8.1,11.45));world.interaction.invalidate();await frames(3)
 var held=world.interaction.choose_target();check(held!=null,"distance tie has a valid target")
 for i in range(10):
  world.actor.set_logical(Vector2(8.1+(.015 if i%2==0 else -.015),11.45));world.interaction.invalidate();await frames(2)
  check(world.interaction.choose_target()==held,"small distance ties do not flicker")
func run() -> void:
 create_timer(240).timeout.connect(func():push_error("TOWN watchdog");quit(2))
 root.size=Vector2i(1280,720);await start()
 check(q.phases=={"iso_errand":"available","iso_cargo":"available"} and q.completions=={"iso_errand":0,"iso_cargo":0} and q.selected_quest==q.definitions.keys()[0] and q.navigation.quest_id=="","fresh initial state/selection/empty tracking")
 await indicators();reinitialize()
 check(world.map_size==Vector2(24,20) and world.props.filter(func(p):return p.spec.kind=="building").size()==6,"bounded six-building scene")
 check(world.access_errors.is_empty(),"all doors/gates/aprons have reachable paths: "+str(world.access_errors))
 check(world.npcs.size()==3 and world.npcs.all(func(n):return n.speed==4.8) and world.actor.speed==4.8,"two walkers and one stationary merchant retain4.8")
 world.reset_trial();await frames(2)
 for npc in world.npcs:npc.set_logical(Vector2(22.6,16+npc.traffic_rank*.5))
 await frames(3)
 # Actual keyboard loop, courtyard/warehouse gateways, and both new shop fronts.
 await walk_to(Vector2(5.2,19.4));await walk_to(Vector2(5.2,17.5))
 var loop_start=walked
 for point in world.data.review_loop:await walk_to(Vector2(point[0],point[1]))
 loop_frames=walked-loop_start
 for point in [[4.72,7.7],[3.12,7.7],[3.12,5.3],[3.6,3.35],[3.12,7.7],[4.72,7.7],[4.72,3.45],[6.12,3.45],[6.12,4.6],[6.12,3.45],[4.72,3.45],[4.72,7.7]]:await walk_to(Vector2(point[0],point[1]))
 # Authored NPC paths still complete trips and yield to an obstructing player.
 world.reset_trial();world.patrols_enabled=true;world.actor.set_logical(Vector2(4.72,4.8));await frames(100)
 world.actor.set_logical(Vector2(21,16))
 for frame in range(600):
  await physics_frame
  check(world.depth_cycles==0,"acyclic NPC crossings")
  for person in world.npcs:
   for prop in world.props:
    for rect in prop.physical_footprints:check(person.logical.distance_to(person.logical.clamp(rect.position,rect.end))>=.142,"NPC clears "+str(prop.name))
  for i in range(world.npcs.size()):
   for j in range(i+1,world.npcs.size()):check(world.npcs[i].logical.distance_to(world.npcs[j].logical)>=.292,"NPCs do not overlap")
 check(world.npcs[0].patrol.arrivals>2 and world.npcs[1].patrol.arrivals>2,"both NPCs continue authored trips")
 check(world.npcs[1].patrol.yields>0,"obstructed NPC yields and resumes")
 for npc in world.npcs:
  if npc.patrol!=null:npc_review[str(npc.name)]={"arrivals":npc.patrol.arrivals,"yields":npc.patrol.yields,"retreats":npc.patrol.retreats}
 world.patrols_enabled=false
 # Denial leaves both quests available. Reaccept and accept the independent second quest.
 await accept("iso_cargo",false);await accept("iso_errand",false);check(q.phases.iso_errand=="available","decline doesn't affect other quest")
 await accept("iso_errand");await accept("iso_cargo");record("both_accepted")
 check(q.navigation.quest_id=="iso_errand","second acceptance doesn't steal tracking")
 reinitialize();await indicators()
 await tap(KEY_Q);check(q.journal.visible and paused,"Q opens shared paper journal")
 await click(q.quest_buttons.iso_cargo);await click(q.track_button);check(q.navigation.quest_id=="iso_cargo","mouse selects other tracked quest")
 await click(q.track_button);check(q.navigation.quest_id=="" and q.phases.iso_cargo=="active","untracking keeps phase")
 await click(q.quest_buttons.iso_errand);await click(q.track_button);await tap(KEY_Q)
 await investigation_priority()
 await inspect("iso_cargo");record("untracked_cargo_investigated");check(q.navigation.quest_id=="iso_errand","untracked investigation allowed")
 var cargo=world.props.filter(func(p):return p.spec.id=="urn")[0];check(cargo.physical_footprints.size()==1,"cargo artwork/collider retained")
 await enter();await inspect("iso_errand");await leave()
 record("both_ready_after_room")
 check(q.phases.iso_cargo=="ready" and q.phases.iso_errand=="ready","both ready survive room transitions")
 reinitialize();await indicators()
 await report("iso_errand");record("tracked_report_clears_only_tracking");check(q.navigation.quest_id=="" and q.phases.iso_cargo=="ready","completion clears only current tracking")
 reinitialize();await indicators()
 # Merchant F dialogue hands off to actual service UI, with isolated money/progress.
 await approach("TownMerchant");await tap(KEY_F);await finish_dialogue()
 check(q.shop.visible and paused and q.money==300,"F conversation opens shop with300mun")
 var before=world.actor.logical;await key(KEY_W,true);await tap(KEY_F);await frames(8)
 check(world.actor.logical==before and not world.dialogue.active,"shop blocks movement/background F")
 await click(q.shop.action);record("first_purchase");check(q.money==200 and q.progress.inventory.bear_strength_pill==1,"real purchase exactly100mun and one item")
 await process_frame;q.shop.transact();q.shop.transact();check(q.money==100 and q.progress.inventory.bear_strength_pill==2,"same-frame duplicate purchase rejected")
 await process_frame;await click(q.shop.action);check(q.money==0 and q.progress.inventory.bear_strength_pill==3 and q.shop.action.disabled,"third purchase and insufficient funds UI")
 await process_frame;q.shop.transact();record("three_purchases_then_insufficient_funds");check(q.money==0 and q.progress.inventory.bear_strength_pill==3,"insufficient-funds API cannot spend")
 await tap(KEY_ESCAPE);check(not q.shop.visible and not paused,"ESC closes shop/unpauses")
 await frames(6);check(world.actor.logical==before,"held W cannot cause closing jump")
 await key(KEY_W,false);await frames(2)
 await approach("TownMerchant");await tap(KEY_F);await finish_dialogue();check(q.money==0 and q.progress.inventory.bear_strength_pill==3,"shop reentry retains funds/inventory")
 await tap(KEY_ESCAPE);await enter();await leave();check(q.money==0 and q.progress.inventory.bear_strength_pill==3 and q.phases.iso_cargo=="ready","room roundtrip preserves trade and other quest")
 var before_reset=quest_snapshot();await tap(KEY_R)
 check(quest_snapshot()==before_reset,"R resets position without changing quests/counts/tracking/selection/wallet/inventory")
 reinitialize()
 await report("iso_cargo");record("both_completed_no_rewards");check(q.money==0 and q.progress.stats==q.progress.RULES.STARTING_STATS,"quests grant no money or stats")
 await target_checks()
 # History still uses shared UI and closing it doesn't skip a quest step.
 await approach("RearPorter");await tap(KEY_F);await tap(KEY_H);check(world.dialogue.dialogue_history.visible and paused,"H history remains usable");await tap(KEY_ESCAPE);await finish_dialogue()
 world.queue_free();await process_frame;await process_frame;check(not paused,"cleanup restores pause")
 # Reverse acceptance/report order in a fresh session. Nothing is persisted.
 await start();record("new_session_reset");check(q.money==300 and q.progress.inventory.bear_strength_pill==0 and q.phases=={"iso_errand":"available","iso_cargo":"available"} and q.completions=={"iso_errand":0,"iso_cargo":0} and q.navigation.quest_id=="","new run resets all trial states")
 await accept("iso_cargo");await accept("iso_errand");await inspect("iso_cargo");await report("iso_cargo")
 record("reverse_order_cargo_completed")
 check(q.phases.iso_errand=="active","reverse completion preserves other active quest")
 await enter();await inspect("iso_errand");await leave();await report("iso_errand")
 record("reverse_order_both_completed")
 check(q.completions=={"iso_errand":1,"iso_cargo":1},"both completion orders work")
 reinitialize();await indicators()
 world.queue_free();await process_frame;await process_frame;check(not paused and not physics_interpolation,"all scopes restored")
 await start();await tap(KEY_Q);check(paused,"journal exit test starts paused")
 world.queue_free();await process_frame;await process_frame;check(not paused and not physics_interpolation,"scene exit while journal open restores scopes")
 await start();q.open_shop();check(paused,"shop exit test starts paused")
 world.queue_free();await process_frame;await process_frame;check(not paused and not physics_interpolation,"scene exit while shop open restores scopes")
 if trace_output!="":
  var file=FileAccess.open(trace_output,FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify({"checks":checks,"keyboard_frames":walked,"loop_frames":loop_frames,"loop_simulated_seconds":loop_frames/60.0,"npc_review":npc_review,"events":trace},"  "));file.close()
 print("ISOMETRIC_TOWN: "+("FAIL" if failed else "PASS")+" | checks="+str(checks)+" | keyboard_frames="+str(walked));quit(1 if failed else 0)
