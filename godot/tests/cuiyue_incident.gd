extends "res://tests/hangzhou_quests.gd"
func prepare_prereqs() -> void:
 for id in ["after_song","fresh_fish","silk_light"]:q(id).phase="completed"
 q("after_song").branch="invite";q("silk_light").branch="lining"
 game.nanjing_relief_quest.phase="completed"
 game.alliance_story.stage_id="completed";game.alliance_story.received_art="hoeryu";game.alliance_visit.phase="closed"
func frames(n: int=3) -> void:
 for i in range(n):await process_frame;await physics_frame
func drain_to(next: String) -> void:
 for i in range(70):
  if game.cuiyue_incident.phase==next:return
  if not game.dialogue_lines.is_empty():game.advance_dialogue()
  await process_frame
 check(false,"reaches phase "+next)
func auto_fight() -> void:
 game.battle.animation_time=.01
 var until=Time.get_ticks_msec()+25000
 while game.state=="battle" and Time.get_ticks_msec()<until:
  var b=game.battle
  if b.awaiting_player and not b.busy:
   var plan=preload("res://scripts/grid_tactical_ai.gd").choose(b.grid,0);b.facing=plan.facing;b.commit(plan.id,plan.get("destination",Vector2i(-1,-1)))
  await create_timer(.01).timeout
 check(game.state=="story" and game.cuiyue_incident.phase=="aftermath","actual victory enters aftermath")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("hangzhou")
 var w=game.exploration;var event=game.cuiyue_incident
 # The victory path uses a grown build; the separate loss path still forces real defeat.
 game.progress.stats={"strength":60,"agility":60,"constitution":60,"inner":60,"insight":61};game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""]
 prepare_prereqs()
 for missing in event.data.prerequisites:
  var other=game.hangzhou_quests.get_quest(missing);var saved=other.phase;other.phase="ready"
  check(not event.eligible(),"requires completed report "+missing);other.phase=saved
 for missing in ["available","ready","inquiry","missing"]:
  game.nanjing_relief_quest.phase=missing;check(not event.eligible(),"Nanjing fully complete required "+missing)
 game.nanjing_relief_quest.phase="completed";check(event.eligible(),"all four conditions")
 await frames();check(event.phase=="dormant","outside hall stays dormant")
 check("haomun" not in game.progress.known_factions,"faction hidden before private reveal")
 check(game.save_system.write_slot(1),"save eligible outside hall")
 # Menus and ongoing conversations block the automatic scene.
 q("silk_light").phase="ready";w.load_area("cuiyue_hall");await frames();check(event.phase=="dormant","only three of four cannot trigger")
 game.player_menu.open_menu("inventory");q("silk_light").phase="completed";await frames();check(event.phase=="dormant","I menu blocks trigger")
 q("silk_light").phase="ready";game.player_menu.close_menu()
 game.adventure_ui.open_journal();q("silk_light").phase="completed";await frames();check(event.phase=="dormant","Q menu blocks trigger")
 q("silk_light").phase="ready";game.adventure_ui.close_menu()
 await talk("cy_dancer","silk_light")
 check(not game.dialogue_lines.is_empty(),"actual F completion conversation opens")
 while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
 await frames();check(event.phase=="dormant" and q("silk_light").phase=="ready","never interrupts final report line")
 game.advance_dialogue();check(q("silk_light").phase=="completed" and event.phase=="dormant","prerequisite report commits before scene")
 var money=game.money;var stats=game.progress.stats.duplicate();var fame=game.progress.fame
 await frames();check(event.phase=="confront" and game.state=="story","auto begins inside after report")
 check(w.ambient_nodes.filter(func(n):return n.name=="cy_tak").size()==1,"one dedicated opponent")
 var tak=w.decorations.get_node("cy_tak");check(tak.get_child(1).texture.atlas.resource_path.ends_with("tak-munho.png"),"unique Tak sprite")
 check(not game.save_system.write_slot(2),"intro save blocked")
 await drain_to("battle");check(game.battle.encounter.id=="cuiyue_tak" and game.battle.scene_image.texture.resource_path.ends_with("cuiyue-hall.png"),"new 7x5 hall battle background")
 check(not game.save_system.write_slot(2),"battle save blocked")
 await auto_fight();check(not game.adventure_ui.window.visible,"result popup does not interrupt aftermath")
 var leader=w.decorations.get_node("cy_eunsowol")
 check(leader.position==w.city_point([768,465]) and leader.z_index==1,"leader visible on center stage above dais")
 check(leader.get_child(1).texture.atlas.resource_path.ends_with("eunsowol.png"),"unique leader sprite")
 check(game.location.text.contains("취월루") and game.objective.text=="취월루주의 수습 지켜보기","story HUD location and goal")
 check(game.progress.favor_for("haomun")==0,"no premature favor")
 await drain_to("private")
 check(w.ambient_nodes.filter(func(n):return n.visible).size()==1,"private scene clears bystanders")
 check(w.ambient_nodes.filter(func(n):return n.name=="cy_tak").is_empty(),"Tak leaves alive; no permanent NPC")
 var text=JSON.stringify(game.dialogue_lines)
 check(text.contains("육소전") and text.contains("구휼") and text.contains("남궁") and text.contains("하오문"),"private dialogue ties Nanjing contact to reveal")
 while game.dialogue_index<game.dialogue_lines.size()-1:game.advance_dialogue()
 check(game.progress.favor_for("haomun")==0 and "haomun" not in game.progress.known_factions,"no reward before final thanks")
 game.advance_dialogue();await frames();check(event.phase=="completed" and game.progress.favor_for("haomun")==20,"final thanks grants20")
 check(game.money==money and game.progress.stats==stats and game.progress.fame==fame,"no extra money/stats/fame")
 check(w.camera.position==Vector2(0,-w.camera.focus_height),"stage camera restores to player")
 check("haomun" in game.progress.known_factions and w.ambient_nodes.size()==7 and w.ambient_nodes.all(func(n):return n.visible),"faction visible; normal hall restored")
 check(not str(w.decorations.get_node("cy_eunsowol").get_meta("nameplate_label").text).contains("하오문"),"nameplate stays civilian")
 event._complete();check(game.progress.favor_for("haomun")==20,"favor awarded once")
 check(game.save_system.write_slot(3) and game.save_system.load_slot(3),"completed event restores")
 check(w.ambient_nodes.size()==7,"no duplicates after load")
 w.load_area("hangzhou");w.load_area("cuiyue_hall");await frames();check(event.phase=="completed" and game.dialogue_lines.is_empty(),"revisit does not replay")
 var leader_now=w.decorations.get_node("cy_eunsowol");var path=w.path_to(leader_now.position,true);check(not path.is_empty(),"leader accessible after event")
 w.player.position=path[-1];w.player.stop();await frames();await press_f();check(game.dialogue_cast.active_actor=="cy_eunsowol","leader F everyday talk");await settle()
 game.adventure_ui.open_favor();check(game.adventure_ui.window.visible,"R favor view");game.adventure_ui.close_menu()
 # New state is optional for old saves, and corrupted states are rejected.
 var invalid=game.save_system.capture();invalid.cuiyue_incident.phase="private";check(not game.save_system.validate(invalid),"transient scene cannot become stable save")
 var legacy=game.save_system.read_slot(1);legacy.erase("cuiyue_incident")
 var f=FileAccess.open(game.save_system.path(4),FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close()
 check(game.save_system.load_slot(4) and event.phase=="dormant","old save loads without new state")
 # Real F entry starts once; loss is interrupted by the owner and rejoins the same story.
 var saved=FileAccess.get_file_as_string(game.save_system.path(1))
 var portal=w.travel_exits.filter(func(e):return e.id=="travel:hall_entry")[0]
 w.player.position=portal.position;w.player.stop();await frames();await press_f();await frames()
 check(event.phase=="confront","eligible revisit through F triggers")
 await drain_to("battle")
 var b=game.battle;b.animation_time=.01
 var deadline=Time.get_ticks_msec()+6000
 while not b.awaiting_player and Time.get_ticks_msec()<deadline:await create_timer(.02).timeout
 b.grid.units[0].position=Vector2i(2,2);b.grid.units[1].position=Vector2i(3,2)
 b.grid.units[0].hp=1;b.player_hp=1;b.grid.units[0].gauge=100;b.grid.units[1].gauge=100
 while game.state=="battle" and Time.get_ticks_msec()<deadline:
  if b.awaiting_player and not b.busy:b.commit("wait")
  await create_timer(.02).timeout
 check(b.player_hp==0,"real enemy strike causes loss")
 check(game.state=="story" and event.phase=="aftermath" and not game.save_system.write_slot(5),"loss enters rescue dialogue, save remains blocked")
 check(not game.death_screen.visible and not game.adventure_ui.window.visible,"loss shows neither death nor result popup")
 check(game.dialogue_lines==event.data.scenes.player_defeated,"loss has dedicated rescue lines")
 check(game.progress.favor_for("haomun")==0,"rescue gives no early reward")
 check(saved==FileAccess.get_file_as_string(game.save_system.path(1)),"rescue preserves previous save")
 await drain_to("private")
 check(JSON.stringify(game.dialogue_lines).contains("육소전"),"loss rejoins private Nanjing contact conversation")
 await drain_to("completed");await frames()
 check(game.state=="explore" and game.progress.favor_for("haomun")==20,"loss finishes with same one-time favor")
 event._complete();check(game.progress.favor_for("haomun")==20,"loss reward cannot duplicate")
 check(game.save_system.write_slot(5) and game.save_system.load_slot(5),"loss completion saves and restores")
 game.reset();await frames();check(event.phase=="dormant","new game resets event")
 game.queue_free();await process_frame;print("CUIYUE_INCIDENT: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
