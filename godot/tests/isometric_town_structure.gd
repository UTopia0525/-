extends "res://tests/isometric_town.gd"
## Focused negative cases. Existing traversal/quest/transaction happy paths are reused separately.
var audit_rows=[]
func audit(ok: bool,label: String) -> void:
 audit_rows.append({"check":label,"pass":ok});check(ok,label)
func discard(expected_pause=false) -> void:
 var room_id=world.passage.room.get_instance_id() if is_instance_valid(world.passage.room) else 0
 world.queue_free();await process_frame;await process_frame
 audit(paused==expected_pause,"scene removal restores pause")
 audit(not physics_interpolation and not InputMap.has_action("iso_interact"),"scene removal restores interpolation/input map")
 if room_id!=0:audit(not is_instance_id_valid(room_id),"room sibling removed with district")
 paused=false
 for code in [KEY_F,KEY_W,KEY_D]:await key(code,false)
func snapshot() -> Dictionary:
 return {"phases":q.phases.duplicate(),"completions":q.completions.duplicate(),"tracked":q.navigation.quest_id,"money":q.money,"inventory":q.progress.inventory.duplicate(),"stats":q.progress.stats.duplicate()}
func mouse(button: int,down: bool) -> void:
 var e=InputEventMouseButton.new();e.button_index=button;e.position=Vector2(1100,600);e.pressed=down;Input.parse_input_event(e);await process_frame;await process_frame
func run() -> void:
 create_timer(120).timeout.connect(func():push_error("STRUCTURE watchdog");quit(2))
 root.size=Vector2i(1280,720)
 await start()
 var ids={}
 for prop in world.props:ids[prop.spec.id]=true
 audit(ids.size()==world.props.size(),"instantiated object IDs remain unique")
 ids.clear()
 for npc in world.npcs:ids[str(npc.name)]=true
 audit(ids.size()==world.npcs.size(),"runtime NPC IDs remain unique")
 audit(q.phases.size()==q.definitions.size() and q.completions.size()==q.definitions.size(),"quest definitions and state keys agree")
 for id in q.definitions:audit(q.giver(id)!=null and world.dialogue.PORTRAITS.ACTORS.has(q.definitions[id].actor),"runtime giver/portrait references exist "+id)
 audit(typeof(q.money)==TYPE_INT and q.money==300 and q.progress.inventory[q.shop.ITEM]==0,"money/quantity are nonnegative integers at startup")
 var initial=snapshot()
 for id in q.definitions:
  q.resolve_for(id,"report");q.resolve_for(id,"inspect")
 audit(snapshot()==initial,"unaccepted inspection/report rejected without progress/rewards")
 q.resolve_for("missing","report");audit(snapshot()==initial,"unknown quest report rejected")
 q.resolve_for("iso_errand","accept");var active=snapshot();q.resolve_for("iso_errand","accept")
 audit(snapshot()==active,"duplicate acceptance is idempotent")
 await accept("iso_cargo",false)
 audit(q.phases.iso_errand=="active" and q.navigation.quest_id=="iso_errand","decline preserves other active quest/tracking")
 q.resolve_for("iso_errand","inspect");q.resolve_for("iso_errand","report");var done=snapshot()
 q.resolve_for("iso_errand","report");q.resolve_for("iso_errand","inspect")
 audit(snapshot()==done,"repeated completion and invalid backward transition cannot reward")
 await frames(3);await approach("GatePorter");await tap(KEY_F);await finish_dialogue();var after=snapshot();world.dialogue.finish();world.dialogue.finish()
 audit(snapshot()==after,"repeated final dialogue processing does not mutate state")
 await discard()
 await start();q.open_shop();q.open_shop();q.resolve_for("","trade");q.shop.close_counter()
 audit(not paused,"repeated shop open cannot overwrite original pause")
 await discard()
 await start();q.open_shop();q.close_journal()
 audit(paused and q.shop.visible,"late journal close cannot unpause shop")
 q.shop.close_counter();await frames(3);q.open_journal();q.shop.close_counter()
 audit(paused and q.journal.visible,"late shop close cannot unpause journal")
 q.shop.closed.emit();audit(paused,"duplicate closed signal cannot restore an unrelated modal")
 await discard()
 await start();q.open_journal();q.open_shop()
 audit(q.journal.visible and not q.shop.visible,"shop cannot stack over journal")
 await discard()
 await start();await mouse(MOUSE_BUTTON_MIDDLE,true);audit(world.drag,"fixture starts real camera drag")
 await tap(KEY_Q);await mouse(MOUSE_BUTTON_MIDDLE,false);await tap(KEY_Q)
 audit(not world.drag,"journal clears camera drag even if middle release occurs inside modal")
 await discard()
 # A held movement key is neutralized after the journal, and a fresh key works.
 await start();var before_pos=world.actor.logical;await tap(KEY_Q);await key(KEY_W,true);await tap(KEY_F);await tap(KEY_Q);await frames(4)
 audit(world.actor.logical==before_pos and not world.dialogue.active,"journal blocks F and neutralizes held movement on close")
 await key(KEY_W,false);await frames(2);await key(KEY_D,true);await frames(4)
 audit(world.actor.logical.distance_to(before_pos)>.05,"fresh movement resumes after journal")
 await key(KEY_D,false);await discard()
 # The same neutralization applies to the shop.
 await start();q.open_shop();before_pos=world.actor.logical;await key(KEY_W,true);await tap(KEY_F);q.shop.close_counter();await frames(4)
 audit(world.actor.logical==before_pos and not world.dialogue.active,"shop blocks background F and neutralizes held movement")
 await key(KEY_W,false);await frames(2);await key(KEY_D,true);await frames(4)
 audit(world.actor.logical.distance_to(before_pos)>.05,"fresh movement resumes after shop")
 await key(KEY_D,false);await discard()
 # Transaction boundary, complete rollback on rejection, and independent real clicks.
 await start();q.open_shop();var before=snapshot();q.shop.selected_id="missing";q.shop.transact()
 audit(snapshot()==before,"invalid selected item cannot buy previous item")
 audit(not q.progress.purchase("elixir","missing",q) and snapshot()==before,"unknown catalogue purchase rejected atomically")
 q.shop.selected_id=q.shop.ITEM
 await click(q.shop.action);audit(q.money==200 and q.progress.inventory.bear_strength_pill==1,"one real click commits one purchase")
 await process_frame;q.shop.transact();q.shop.transact();audit(q.money==100 and q.progress.inventory.bear_strength_pill==2,"same-frame duplicated requests commit once")
 await process_frame;await click(q.shop.action);before=snapshot();await process_frame;q.shop.transact()
 audit(snapshot()==before and q.money==0 and q.progress.inventory.bear_strength_pill==3,"insufficient funds preserves entire state")
 q.shop.close_counter();q.money=300;before=snapshot();await process_frame;q.shop.transact()
 audit(snapshot()==before,"closed shop cannot purchase")
 await discard()
 # Normal dialogue: Q/background F/movement cannot change the background.
 await start();await approach("GatePorter");await tap(KEY_F);var pos=world.actor.logical
 await key(KEY_W,true);await tap(KEY_Q);await frames(4)
 audit(world.actor.logical==pos and not q.journal.visible and not world.passage.offer(),"dialogue blocks movement/journal/portal")
 await tap(KEY_H);var line=world.dialogue.dialogue_index;await tap(KEY_F);await tap(KEY_Q)
 audit(world.dialogue.dialogue_history.visible and world.dialogue.dialogue_index==line and not q.journal.visible,"history blocks progress and journal")
 await tap(KEY_ESCAPE);await key(KEY_W,false);await finish_dialogue();await tap(KEY_2);await finish_dialogue()
 pos=world.actor.logical;await key(KEY_D,true);await frames(4);audit(world.actor.logical.distance_to(pos)>.05,"movement resumes after dialogue/history")
 await key(KEY_D,false);await discard()
 # Preserve actor pauses owned by a different activity when ending dialogue.
 await start();await approach("GatePorter");world.actor.motion_paused=true;world.npcs[0].motion_paused=true
 world.dialogue.begin(world.npcs[0]);world.dialogue.finish()
 audit(world.actor.motion_paused and world.npcs[0].motion_paused,"dialogue restores previous actor pause flags")
 await discard()
 # Camera drag must not survive a transition while its release is hidden by a modal.
 await start();await park_npcs();world.actor.set_logical(Vector2(14.605814,11.562791));world.interaction.invalidate();await frames(3)
 await mouse(MOUSE_BUTTON_MIDDLE,true);await key(KEY_F,true);await world.passage.completed;await mouse(MOUSE_BUTTON_MIDDLE,false);await key(KEY_F,false);await frames(2)
 audit(not world.drag and not world.passage.room.drag,"entry clears stale camera drag")
 await leave();audit(not world.drag,"returned exterior does not keep camera drag")
 await discard()
 # Removing every modal/room also restores global state without closing it first.
 for mode in ["dialogue","history","journal","shop","room","fade"]:
  await start()
  if mode in ["dialogue","history"]:
   await approach("GatePorter");await tap(KEY_F)
   if mode=="history":await tap(KEY_H)
  elif mode=="journal":q.open_journal()
  elif mode=="shop":q.open_shop()
  elif mode=="room":await enter();q.open_journal()
  else:
   world.actor.set_logical(Vector2(14.605814,11.562791));world.passage.transition();await process_frame
  await discard()
 # Investigation must refer to a real scene object, not only an empty coordinate.
 await start();q.resolve_for("iso_cargo","accept");await park_npcs();world.actor.set_logical(Vector2(6.325,6.05));await frames(3)
 var cargo=world.props.filter(func(p):return p.spec.id=="urn")[0]
 world.actors.remove_child(cargo);world.props.erase(cargo);await frames(3)
 audit(q.inspect_id()=="","missing investigation object cannot offer a ghost interaction")
 cargo.free();await discard()
 # Journal must preserve an external pause just like the shop.
 await start();paused=true;q.open_journal();q.close_journal();audit(paused,"journal restores a pre-existing paused state")
 paused=false;await discard()
 # Existing externally paused host must stay paused when a modal is closed/removed.
 await start();paused=true;q.open_shop();q.shop.close_counter();audit(paused,"shop restores a pre-existing paused state")
 paused=false;await discard()
 if trace_output!="":
  var file=FileAccess.open(trace_output,FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify({"passed":not failed,"checks":audit_rows},"  "));file.close()
 print("ISOMETRIC_TOWN_STRUCTURE: "+("FAIL" if failed else "PASS")+" | audit_checks="+str(audit_rows.size()));quit(1 if failed else 0)
