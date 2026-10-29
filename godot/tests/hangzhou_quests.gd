extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("HANGZHOU_QUESTS: "+msg)
func q(id: String):return game.hangzhou_quests.get_quest("hangzhou_"+id)
func press_f() -> void:
 for pressed in [true,false]:
  var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=pressed;Input.parse_input_event(e);await process_frame;await physics_frame
func settle() -> void:
 if game.adventure_ui.window.visible and game.adventure_ui.mode=="result":game.adventure_ui.dismiss()
 for i in range(60):
  if game.dialogue_lines.is_empty():break
  game.advance_dialogue();await process_frame
 check(game.dialogue_lines.is_empty(),"dialogue ends")
func talk(id: String,quest_id: String="") -> void:
 game.hangzhou_quests.refresh_world()
 var w=game.exploration
 var area="cuiyue_hall" if id.begins_with("cy_") else "hangzhou"
 if w.area_name!=area:
  var exit_id="travel:hall_entry" if area=="cuiyue_hall" else "travel:hall_exit"
  var exits=w.travel_exits.filter(func(e):return e.id==exit_id)
  check(exits.size()==1,"connecting portal "+exit_id)
  if exits.is_empty():return
  w.player.position=exits[0].position;w.player.stop();await physics_frame;await press_f();check(w.area_name==area,"actual F city/hall travel")
 var actors=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==id)
 check(actors.size()==1,"one actor "+id)
 if actors.is_empty():return
 var path=w.path_to(actors[0].position,true);check(not path.is_empty(),"reachable "+id)
 if path.is_empty():return
 w.player.position=path[-1];w.player.stop();await physics_frame;await process_frame
 if game.dialogue_lines.is_empty() and game.state=="explore":
  await press_f()
 if game.adventure_ui.window.visible and game.adventure_ui.mode=="topics":
  var title=q(quest_id).data.title if not quest_id.is_empty() else "일상 이야기"
  var selected=false
  for b in game.adventure_ui.rows.get_children():
   if str(b.get_meta("topic","")).ends_with(title):b.pressed.emit();selected=true;break
  check(selected,"requested topic remains selectable "+title)
func step(quest_id: String) -> void:
 var quest=q(quest_id);await talk(quest.target(),quest_id);await settle()
func choose(first: bool) -> void:
 check(game.adventure_ui.window.visible and game.adventure_ui.mode=="choice","choice displayed")
 if first:game.adventure_ui.primary_action()
 else:game.adventure_ui.secondary_action()
 await settle()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("hangzhou");game.money=2000
 var w=game.exploration;var hub=game.hangzhou_quests
 var before=game.progress.snapshot();var ids=["after_song","fresh_fish","golden_rail","silk_light","first_wage"]
 check(hub.quests.size()==5,"five independent quests")
 game.adventure_ui.open_journal();game.adventure_ui.set_filter("available")
 check(game.adventure_ui.entries.keys().filter(func(k):return str(k).begins_with("hangzhou_")).size()==5,"Q lists all five before arrival at givers")
 game.adventure_ui.close_menu()
 for id in ids:check(q(id).phase=="available" and q(id).marker_for(q(id).GIVER)=="!","not auto accepted; giver available")
 await talk("cy_waiter","after_song");await settle();await choose(false);check(q("after_song").phase=="available","decline leaves quest available")
 for id in ids:
  await talk(q(id).GIVER,id);await settle();await choose(true);check(q(id).status()=="active","concurrent acceptance "+id)
 game.adventure_ui.open_journal();check(game.adventure_ui.entries.keys().filter(func(k):return str(k).begins_with("hangzhou_")).size()==5,"Q lists five active")
 game.adventure_ui.close_menu()
 check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"all accepted quests save together")
 game.quest_navigation.track(q("after_song").ID,q("after_song").stage())
 await step("fresh_fish");check(q("fresh_fish").phase=="boat","selected manager topic advances fish only")
 check(q("golden_rail").phase=="wine" and q("silk_light").phase=="cloth","shared manager leaves other quests untouched")
 check(game.quest_navigation.quest_id==q("after_song").ID,"other quest never replaces explicit tracking")
 game.exploration.load_area("suzhou");check(game.quest_navigation.get_goal(w).goal_id=="travel:canal","Suzhou guides south to Hangzhou")
 check(game.save_system.write_slot(8) and game.save_system.load_slot(8),"active quests persist outside region")
 w.load_area("hangzhou")
 check(game.quest_navigation.get_goal(w).goal_id=="travel:hall_entry","love quest enters hall, not north canal")
 await step("after_song");check(q("after_song").phase=="noodles","Soa conversation")
 check(game.quest_navigation.get_goal(w).goal_id=="travel:hall_exit","city target directs out of hall")
 await step("after_song");check(q("after_song").phase=="decision","learned personal tastes before decision")
 check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"stable love branch point")
 await step("after_song");await choose(true);check(q("after_song").branch=="invite","invite path")
 await step("after_song");check(q("after_song").phase=="ready","response before report")
 check(q("after_song").marker_for("cy_waiter")=="?","actual report giver gets question mark")
 hub.refresh_world()
 var report_marks=hub.owned.filter(func(n):return is_instance_valid(n) and n is Label and n.get_parent().get_meta("npc_id","")=="cy_waiter")
 check(report_marks.size()==1 and report_marks[0].text=="?","visible overhead report marker")
 var waiter=w.decorations.get_node("cy_waiter");w.player.position=w.safe_player_position(waiter.position+Vector2(100,0));w.camera.snap_to_player();game.minimap.refresh()
 check(game.minimap.quest_badges.any(func(b):return b.symbol=="?"),"minimap report icon")
 var money=game.money;await talk("cy_waiter","after_song");check(game.money==money,"report has no early payment")
 check(not game.save_system.write_slot(7),"dialogue save remains blocked");await settle();check(game.money==money+100,"love pays100 after last line")
 for id in ["fresh_fish","golden_rail","first_wage"]:
  for i in range(8):
   if q(id).phase=="completed":break
   check(q(id).valid(q(id).snapshot()),"reachable phase validated "+id)
   check(game.save_system.write_slot(3) and game.save_system.load_slot(3),"per-step save "+id)
   await step(id)
  check(q(id).phase=="completed","complete "+id)
 # Existing artisan commerce remains accessible during or after the errand.
 await talk("hz_artisan")
 if game.adventure_ui.mode=="topics":
  for b in game.adventure_ui.rows.get_children():
   if b.get_meta("topic","")=="병장기를 살펴본다":b.pressed.emit();break
 await settle();check(game.city_service.visible,"shared artisan commerce kept");game.city_service.close_counter()
 await step("silk_light");await step("silk_light");check(q("silk_light").phase=="decision","costume options reached")
 check(game.save_system.write_slot(4),"costume branch save")
 await step("silk_light");await choose(true);await step("silk_light")
 check(q("silk_light").phase=="completed" and q("silk_light").branch=="lining","lining branch completes")
 check(game.money==2700,"five quests total700")
 for quest in hub.quests:quest._complete();check(quest.marker_for(quest.GIVER)=="","completed markers removed")
 check(game.money==2700 and JSON.parse_string(JSON.stringify(game.progress.snapshot()))==JSON.parse_string(JSON.stringify(before)),"exactly once money; no insight/fame/favor/items")
 hub.chatter("cy_waiter");check(str(game.dialogue_lines[0][1]).contains("곡 이야기"),"optional changed chatter");await settle()
 check(game.save_system.write_slot(5) and game.save_system.load_slot(5),"all completed restores")
 check(game.save_system.load_slot(4),"reload alternate costume path")
 await step("silk_light");await choose(false);await step("silk_light");check(q("silk_light").branch=="mend","mend branch")
 check(game.save_system.load_slot(2),"reload alternate love path")
 await step("after_song");await choose(false);await step("after_song");await step("after_song");check(q("after_song").phase=="completed" and q("after_song").branch=="meal","warm meal alternative")
 var invalid=game.save_system.capture();invalid.hangzhou_quests.hangzhou_after_song={"phase":"soa","branch":"invite"};check(not game.save_system.validate(invalid),"unreachable branch rejected")
 invalid=game.save_system.capture();invalid.hangzhou_quests.hangzhou_fresh_fish.phase="battle";check(not game.save_system.validate(invalid),"no invented battle state")
 var legacy=game.save_system.read_slot(1);legacy.erase("hangzhou_quests");legacy.navigation={"quest":"","stage":"","completed":[],"facility":""}
 var f=FileAccess.open(game.save_system.path(6),FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close()
 check(game.save_system.load_slot(6),"old saves without new hub load")
 for quest in hub.quests:check(quest.phase=="available","old save defaults available")
 game.queue_free();await process_frame;print("HANGZHOU_QUESTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
