extends "res://tests/cuiyue_incident.gd"
func speak(id: String) -> void:
 var w=game.exploration;var actors=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==id)
 check(actors.size()==1,"one interactive actor "+id)
 if actors.is_empty():return
 var path=w.path_to(actors[0].position,true);check(not path.is_empty(),"reachable "+id)
 if path.is_empty():return
 w.player.position=path[-1];w.player.stop();await frames();await press_f()
 if game.adventure_ui.window.visible and game.adventure_ui.mode=="topics":
  var found=false
  for b in game.adventure_ui.rows.get_children():
   if str(b.get_meta("topic","")).ends_with(game.blackguild_story.data.title):b.pressed.emit();found=true;break
  check(found,"quest coexists in shared NPC topics")
func travel_to(area: String) -> void:
 var w=game.exploration
 var exits=w.travel_exits.filter(func(e):return e.travel.area==area)
 check(not exits.is_empty(),"portal to "+area)
 if exits.is_empty():return
 check(w.can_stand(exits[0].position),"portal physically reachable "+area)
 w.player.position=exits[0].position;w.player.stop();await frames();await press_f();await frames();check(w.area_name==area,"F travels to "+area)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
 var q=game.blackguild_story;var w=game.exploration
 check(q.status()=="locked","prerequisite locks quest")
 prepare_prereqs();game.cuiyue_incident.phase="completed";game.cuiyue_incident.referral_seen=true;game.progress.add_favor("haomun",20)
 game.progress.stats={"strength":65,"agility":65,"constitution":65,"inner":65,"insight":65};game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""]
 w.load_area("cuiyue_hall");await frames()
 check(q.status()=="available" and q.marker_for("cy_manager")=="!","optional marked offer, no auto start")
 await speak("cy_manager");await settle();check(game.adventure_ui.mode=="choice","accept choice opens")
 game.adventure_ui.secondary_action();await settle();check(q.phase=="available","decline preserves availability")
 await speak("cy_manager");await settle();game.adventure_ui.primary_action();await settle();check(q.phase=="fish","accepted")
 await travel_to("hangzhou")
 for pair in [["hz_fishseller","artisan"],["hz_artisan","waiter"]]:
  await speak(pair[0]);await settle();check(q.phase==pair[1],"investigation advances "+pair[0])
 await travel_to("cuiyue_hall");await speak("cy_waiter");await settle();await travel_to("hangzhou");await speak("cy_tak");await settle()
 check(q.phase=="consult","Tak delivers message regardless prior victory/loss")
 await travel_to("cuiyue_hall");await speak("cy_eunsowol");await settle();await travel_to("hangzhou");await travel_to("blackguild_warehouse")
 check(game.save_system.write_slot(7) and game.save_system.load_slot(7),"warehouse save roundtrip")
 await frames();check(w.city_data.objects.size()==18 and w.city_data.objects.all(func(o):return o.prefab=="cargo"),"warehouse contains18 cargo piles and no office furniture");await speak("bg_officer");await settle();check(q.phase=="battle","F starts fight")
 check(not game.save_system.write_slot(8),"battle cannot save")
 game.battle.animation_time=.01
 var deadline=Time.get_ticks_msec()+30000
 while game.state=="battle" and Time.get_ticks_msec()<deadline:
  var b=game.battle
  if b.awaiting_player and not b.busy:
   var plan=preload("res://scripts/grid_tactical_ai.gd").choose(b.grid,0);b.facing=plan.facing;b.commit(plan.id,plan.get("destination",Vector2i(-1,-1)))
  await create_timer(.01).timeout
 check(q.phase=="papers","actual tactical fight returns to papers")
 await settle();await speak("bg_supplier");await settle();check(q.phase=="choice","papers examined")
 await travel_to("hangzhou");await travel_to("cuiyue_hall")
 check(game.save_system.write_slot(8),"save before branch")
 var initial_money=game.money;var initial_stats=game.progress.stats.duplicate(true);var initial_favor=game.progress.favor_for("haomun")
 for branch in ["public","agreement"]:
  if branch=="agreement":check(game.save_system.load_slot(8),"rewind to other branch");await frames()
  await speak("cy_eunsowol");await settle()
  check(game.adventure_ui.mode=="choice" and q.branch=="","choice has no early commitment")
  if branch=="public":
   check(not game.save_system.write_slot(1),"choice popup keeps existing menu save restriction")
   game.adventure_ui.close_menu()
   check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"closing choice preserves a saveable decision point")
   await frames();await speak("cy_eunsowol");await settle()
  if branch=="public":game.adventure_ui.primary_action()
  else:game.adventure_ui.secondary_action()
  check(not game.save_system.write_slot(9),"branch dialogue cannot save")
  await settle();check(q.phase=="audience" and q.branch==branch,"branch committed "+branch)
  await travel_to("hangzhou");await travel_to("blackguild_hall")
  check(game.save_system.write_slot(9) and game.save_system.load_slot(9),"hall and branch restore")
  await frames();await speak("bg_wi");await settle();check(q.phase=="report","actual leader audience")
  await travel_to("hangzhou");await travel_to("cuiyue_hall");await speak("cy_manager")
  while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue();await process_frame
  check(q.phase=="report" and game.money==initial_money and game.progress.favor_for("haomun")==initial_favor,"no reward before final report line ends")
  game.advance_dialogue();await settle()
  check(q.phase=="completed" and q.marker_for("cy_manager")=="","final report completes")
  q._complete();check(game.money==initial_money+500 and game.progress.stats==initial_stats and game.progress.favor_for("haomun")==initial_favor+30,"500 mun and 30 favor exactly once on either branch")
  check(game.save_system.write_slot(10) and game.save_system.load_slot(10),"completion persists")
  q._complete();check(game.money==initial_money+500 and game.progress.favor_for("haomun")==initial_favor+30,"loading and repeated completion cannot grant again")
 var bad=q.snapshot();bad.branch="";check(not q.valid(bad),"reject impossible branch")
 var old=game.save_system.capture();old.erase("blackguild_story");old.world.area="hangzhou";old.world.position=[2200,2000]
 check(game.save_system.validate(old),"old save without quest compatible")
 # Real death policy uses common end screen and preserves prior slots.
 var previous=FileAccess.get_file_as_string(game.save_system.path(10))
 q.phase="battle";q.branch="";game.start_battle(q.data.encounter)
 game._on_defeat();check(game.state=="game_over" and game.death_screen.visible,"new real fight uses death screen")
 check(not game.save_system.write_slot(2) and previous==FileAccess.get_file_as_string(game.save_system.path(10)),"death preserves saves")
 game.reset();await frames();check(q.phase=="available" and q.branch=="","new game reset")
 game.queue_free();await process_frame;print("BLACKGUILD_STORY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
