extends SceneTree
var world
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("ISO_ERRAND: "+message)
func frames(n: int) -> void:
 for i in range(n):await physics_frame
func key(code: int,down: bool,echo=false) -> void:
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;e.echo=echo;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame;await process_frame
func tap(code: int) -> void:await key(code,true);await key(code,false)
func click(button: Button) -> void:
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=button.get_global_rect().get_center();e.pressed=down;Input.parse_input_event(e);await process_frame;await process_frame
func start_offer() -> void:
 await tap(KEY_F);await tap(KEY_F);await tap(KEY_F);await tap(KEY_F)
func front_giver() -> void:
 world.npcs[0].set_logical(Vector2(3.12,9.7));world.npcs[1].set_logical(Vector2(19,15));world.actor.set_logical(Vector2(3.12,9));await frames(2)
func enter() -> void:
 world.actor.set_logical(Vector2(14.605814,11.562791));await frames(2);await key(KEY_F,true);await world.passage.completed;await key(KEY_F,false);await frames(2)
func leave() -> void:
 world.passage.room.actor.set_logical(Vector2(3.7,5.35));await frames(2);await key(KEY_F,true);await world.passage.completed;await key(KEY_F,false);await frames(2)
func run() -> void:
 create_timer(120).timeout.connect(func():push_error("ERRAND watchdog");quit(2))
 root.size=Vector2i(1280,720)
 world=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(world);await frames(3);world.patrols_enabled=false
 var q=world.errand
 check(world.actor.speed==4.8 and world.npcs.all(func(n):return n.speed==4.8),"active trial speed rolled back; NPC unchanged")
 await front_giver();check(q.phase=="available" and q.marker.text=="!","initial offer marker")
 await enter();check(not q.inspect_offer() and q.phase=="available","cannot investigate before accepting");await leave();await front_giver()
 await start_offer();check(world.dialogue.choosing and q.phase=="available","offer needs explicit choice")
 await key(KEY_F,true);await key(KEY_F,true,true);check(world.dialogue.choosing and q.phase=="available","held F cannot accept");await key(KEY_F,false)
 await tap(KEY_2);await tap(KEY_F);check(q.phase=="available" and not world.dialogue.active,"decline stays available")
 await start_offer();await tap(KEY_1);check(q.phase=="available","accept commits after acknowledgement")
 await tap(KEY_F);await tap(KEY_F);check(q.phase=="active" and q.navigation.quest_id=="iso_errand","accepted with shared tracking")
 check(q.navigation.get_script().get_base_script().resource_path=="res://scripts/quest_navigation.gd","shared navigation logic reused")
 await tap(KEY_Q);check(paused and q.journal.visible,"Q journal opens")
 await click(q.track_button);check(q.navigation.quest_id=="" and q.phase=="active","tracking can stop independently")
 await click(q.track_button);check(q.navigation.quest_id=="iso_errand","tracking resumes")
 await tap(KEY_F);check(not world.dialogue.active,"F blocked while journal open")
 await tap(KEY_Q);check(not paused and not q.journal.visible,"Q journal closes cleanly")
 await tap(KEY_F);check(world.dialogue.dialogue_lines[0][1].contains("짐이 아직"),"active NPC reminder")
 while world.dialogue.active:await tap(KEY_F)
 check(q.phase=="active","talking again cannot skip investigation")
 await enter();var room=world.passage.room
 check(room.actor.speed==4.8,"room player rolled back")
 room.actor.set_logical(Vector2(2.7,1.2));await frames(2);check(not q.inspect_offer(),"cannot investigate through table")
 room.actor.set_logical(Vector2(2.7,2.8));await frames(2);check(q.inspect_offer(),"front reachable table offers F")
 var table=room.props.filter(func(p):return p.spec.id=="table")[0];var table_id=table.get_instance_id();var collider_count=table.get_child_count()
 await key(KEY_F,true);check(room.dialogue.active and q.phase=="active","F starts inspection without completing early")
 await key(KEY_F,true,true);check(room.dialogue.dialogue_index==0,"held F cannot skip inspection")
 await key(KEY_F,false);await tap(KEY_H);check(paused and room.dialogue.dialogue_history.visible,"existing history reused for solo hero inspection");await tap(KEY_ESCAPE)
 await tap(KEY_F);await tap(KEY_F);check(q.phase=="ready" and q.navigation.stage_id=="report","inspection completion sets report stage")
 check(table.get_instance_id()==table_id and table.get_child_count()==collider_count,"investigation does not remove item art or collision")
 await leave();await frames(2);check(q.phase=="ready" and q.marker.text=="?","outside return shows report marker")
 await enter();check(q.phase=="ready" and not q.inspect_offer(),"room recreation preserves completed investigation");await leave()
 await front_giver();await tap(KEY_F);await tap(KEY_F);await tap(KEY_F)
 check(q.phase=="ready","report completes only at final line")
 await tap(KEY_F);check(q.phase=="completed" and q.completion_count==1 and not q.tracked,"one completion with no reward system")
 await tap(KEY_F)
 while world.dialogue.active:await tap(KEY_F)
 check(q.completion_count==1 and q.phase=="completed","post-completion dialogue cannot duplicate completion")
 await tap(KEY_Q);check(q.body.text.contains("완료"),"journal records completion")
 world.queue_free();await process_frame;await process_frame;check(not paused,"removing journal restores pause")
 world=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(world);await frames(2)
 check(world.errand.phase=="available" and world.errand.navigation.quest_id=="","new session has no persisted quest state")
 world.queue_free();await process_frame;await process_frame;check(not InputMap.has_action("iso_interact"),"trial inputs cleaned up")
 print("ISOMETRIC_ERRAND: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
