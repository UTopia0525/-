extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("MURONG: "+msg)
func drain() -> void:
 for i in range(80):
  if game.dialogue_lines.is_empty():break
  game.advance_dialogue()
func talk(id: String) -> void:
 var w=game.exploration
 var npcs=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==id)
 check(npcs.size()==1,"NPC "+id)
 if npcs.is_empty():return
 var path=w.path_to(npcs[0].position,true);check(not path.is_empty(),"path to "+id)
 if path.is_empty():return
 w.player.position=path[-1];w.player.stop();await physics_frame;await process_frame
 var event=InputEventKey.new();event.keycode=KEY_F;event.physical_keycode=KEY_F;event.pressed=true;Input.parse_input_event(event);await process_frame
 event=InputEventKey.new();event.keycode=KEY_F;event.physical_keycode=KEY_F;event.pressed=false;Input.parse_input_event(event);await process_frame
func auto_fight() -> void:
 game.battle.animation_time=.01
 var limit=Time.get_ticks_msec()+25000
 while game.state=="battle" and Time.get_ticks_msec()<limit:
  var b=game.battle
  if b.awaiting_player and not b.busy:
   var plan=preload("res://scripts/grid_tactical_ai.gd").choose(b.grid,0);b.facing=plan.facing;b.commit(plan.id,plan.get("destination",Vector2i(-1,-1)))
  await create_timer(.01).timeout
 if game.adventure_ui.window.visible and game.adventure_ui.mode=="result":game.adventure_ui.dismiss()
 drain();check(game.state=="explore","actual spar returns to exploration")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_wuchang()
 game.options.seen.append_array(["city","dialogue","trade","battle"])
 var hub=game.suzhou_quests;var q=hub.get_quest("suzhou_murong");var w=game.exploration
 check(q.status()=="dormant" and q.marker_for(q.GIVER)=="","introduction hidden before civilian training report")
 hub.get_quest("suzhou_balance").phase="completed"
 check(q.marker_for(q.GIVER)=="!","introduction becomes available")
 w.load_area("suzhou");await process_frame
 q.accept();drain();check(q.phase=="welcome","accept")
 # Real F portal entry.
 for exit in w.travel_exits:
  if exit.id=="travel:murong":w.player.position=exit.position;w.player.stop()
 await physics_frame;game.interact();await process_frame
 check(w.area_name=="murong_estate","F travel into estate")
 check(w.ambient_nodes.size()==5,"two guards and three named participants")
 for npc in w.ambient_nodes:
  check(not w.blockers.any(func(r):return r.grow(w.CITIZEN_RADIUS).has_point(npc.position)),"NPC feet clear "+str(npc.name))
  check(not w.path_to(npc.position,true).is_empty(),"NPC reachable "+str(npc.name))
 check(game.save_system.write_slot(7) and game.save_system.load_slot(7),"estate exploration save roundtrip")
 await talk("mr_heir");drain();check(q.phase=="opening","welcome advances at last line")
 await talk("mr_heir");check(game.adventure_ui.window.visible,"opening spar choice")
 game.adventure_ui.primary_action();drain();await process_frame
 check(game.state=="battle" and q.in_battle(),"real opening battle")
 check(not game.save_system.write_slot(8),"cannot save in spar")
 q.after_defeat();drain();check(q.phase=="hear" and game.state=="explore","nonlethal loss advances")
 await talk("mr_guest");drain();check(q.phase=="decide","livelihood conversation")
 check(game.save_system.write_slot(8),"save before branch")
 var money=game.money
 for first in [true,false]:
  check(game.save_system.load_slot(8),"rewind branch")
  await talk("mr_heir");check(game.adventure_ui.window.visible,"branch choice")
  if first:game.adventure_ui.primary_action()
  else:game.adventure_ui.secondary_action()
  drain();check(q.phase=="trial","branch commits")
  check(game.save_system.write_slot(9) and game.save_system.load_slot(9),"chosen branch persists")
  await talk("mr_heir");game.adventure_ui.primary_action();drain();await process_frame
  check(game.state=="battle","trial battle")
  check(game.battle.grid.field.height==(3 if first else 5),"branch changes field geometry")
  if first:await auto_fight()
  else:q.after_victory();drain()
  check(q.phase=="review","trial advances regardless of outcome")
  await talk("mr_guest");drain();check(q.phase=="ready" and q.marker_for("mr_patriarch")=="?","report marker")
  await talk("mr_patriarch");check(game.money==money,"no early payment");drain()
  check(q.phase=="completed" and game.money==money+500 and game.progress.favor_for("murong")==10,"money and favor once")
  q._complete();check(game.money==money+500 and game.progress.favor_for("murong")==10,"no duplicate rewards")
  check(game.save_system.write_slot(10) and game.save_system.load_slot(10),"completion persists")
 for exit in w.travel_exits:
  if exit.id=="travel:suzhou":w.player.position=exit.position;w.player.stop()
 await physics_frame;game.interact();await process_frame
 check(w.area_name=="suzhou" and q.phase=="completed","F return preserves completed quest")
 var old=game.save_system.capture();old.suzhou_quests.erase(q.ID);check(game.save_system.validate(old),"old saves without exchange accepted")
 game.reset();await create_timer(.2).timeout;game.queue_free();await process_frame
 print("MURONG: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
