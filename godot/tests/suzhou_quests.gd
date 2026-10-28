extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("SUZHOU_QUESTS: "+msg)
func q(id: String):return game.suzhou_quests.get_quest("suzhou_"+id)
func same_counts(a: Dictionary,b: Dictionary) -> bool:
 if a.size()!=b.size():return false
 for key in a:
  if not b.has(key) or int(a[key])!=int(b[key]):return false
 return true
func settle() -> void:
 if game.adventure_ui.window.visible and game.adventure_ui.mode=="result":game.adventure_ui.dismiss()
 for i in range(60):
  if game.dialogue_lines.is_empty():break
  game.advance_dialogue();await process_frame
 check(game.dialogue_lines.is_empty(),"dialogue ends")
func talk(id: String,quest_id: String="") -> void:
 game.suzhou_quests.refresh_world()
 var w=game.exploration;var actors=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")==id)
 check(actors.size()==1,"one actor "+id)
 if actors.is_empty():return
 var path=w.path_to(actors[0].position,true);check(not path.is_empty(),"reachable "+id)
 if path.is_empty():return
 w.player.position=path[-1];w.player.stop();await physics_frame;await process_frame
 if game.dialogue_lines.is_empty() and game.state=="explore":
  var k=InputEventKey.new();k.keycode=KEY_F;k.physical_keycode=KEY_F;k.pressed=true;Input.parse_input_event(k);await process_frame
  k=InputEventKey.new();k.keycode=KEY_F;k.physical_keycode=KEY_F;k.pressed=false;Input.parse_input_event(k);await physics_frame
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
func auto_fight() -> void:
 check(game.state=="battle","actual battle begins")
 game.battle.animation_time=.01
 var limit=Time.get_ticks_msec()+20000
 while game.state=="battle" and Time.get_ticks_msec()<limit:
  var b=game.battle
  if b.awaiting_player and not b.busy:
   var plan=preload("res://scripts/grid_tactical_ai.gd").choose(b.grid,0);b.facing=plan.facing;b.commit(plan.id,plan.get("destination",Vector2i(-1,-1)))
  await create_timer(.01).timeout
 await settle();check(game.state=="explore","battle returns to exploration")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("suzhou");game.suzhou_quests.refresh_world();game.money=2000
 game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20};game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""]
 check(game.suzhou_quests.quests.size()==5,"five independent quests")
 var stats=game.progress.stats.duplicate();var inventory=game.progress.inventory.duplicate();var fame=game.progress.fame;var favor=game.progress.faction_favor.duplicate()
 for quest in game.suzhou_quests.quests:check(quest.marker_for(quest.GIVER)=="!","initial giver marker")
 await talk(q("silk").GIVER,"silk");await settle();await choose(false)
 check(q("silk").phase=="available","decline never accepts")
 for id in ["silk","sewing","rumor","quay","balance"]:
  await talk(q(id).GIVER,id);await settle();await choose(true)
  check(q(id).status()=="active","accepted "+id)
 game.adventure_ui.open_journal();check(game.adventure_ui.entries.keys().filter(func(k):return str(k).begins_with("suzhou_")).size()==5,"Q lists all five simultaneous errands");game.adventure_ui.close_menu()
 check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"all accepted quests persist")
 game.quest_navigation.track("suzhou_rumor",q("rumor").stage());game.exploration.load_area("nanjing_suzhou_road")
 check(game.quest_navigation.get_goal(game.exploration).goal_id=="travel:suzhou","cross-map quest guidance leads to Suzhou")
 check(game.save_system.write_slot(8) and game.save_system.load_slot(8),"all five active quests survive saving outside Suzhou")
 game.exploration.load_area("suzhou");game.suzhou_quests.refresh_world()
 # Shared smith still offers commerce while both sewing and sparring are active.
 await talk("sz_smith","sewing");await settle();check(q("sewing").phase=="seamstress" and q("balance").phase=="spar","shared NPC advances only selected errand")
 await talk("sz_smith")
 if not game.dialogue_lines.is_empty():await settle()
 game.suzhou_quests.handle_interaction("sz_smith")
 for b in game.adventure_ui.rows.get_children():
  if b.get_meta("topic","")=="병장기를 살펴본다":b.pressed.emit();break
 await settle();check(game.city_service.visible,"commerce remains available with active quest");game.city_service.close_counter()
 await step("sewing");check(q("sewing").phase=="ready","sewing ends at innkeeper")
 check(q("sewing").marker_for("sz_innkeeper")=="?","report marker follows actual payer")
 var before=game.money;await talk("sz_innkeeper","sewing");check(game.money==before,"no reward before final report line");await settle();check(game.money==before+150,"innkeeper pays150")
 await step("silk");await step("silk");check(q("silk").phase=="decision","silk investigation reaches dilemma")
 check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"stable branch point save")
 await step("silk");await choose(true);check(q("silk").branch=="confess","apprentice confesses branch")
 await step("silk");await step("silk");check(q("silk").phase=="completed","silk report completes")
 await step("rumor");await step("rumor");await step("rumor");await choose(true);await step("rumor")
 check(q("rumor").phase=="completed" and q("rumor").branch=="public","public correction completes")
 await step("quay");game.suzhou_quests.refresh_world();check(game.exploration.ambient_nodes.size()==15,"culprit appears only after confirmation")
 await step("quay");check(game.state=="battle" and q("quay").phase=="battle","confrontation enters lethal fight immediately")
 check(not game.save_system.write_slot(3),"combat saving blocked")
 await auto_fight();check(q("quay").phase=="ready","victory awaits official report")
 await step("quay");check(q("quay").phase=="completed","official pays quay reward")
 check(game.exploration.ambient_nodes.size()==14,"culprit gone after capture")
 await step("balance");await choose(true);check(q("balance").phase=="battle","training enters actual battle")
 game.battle.cancel();game._on_defeat();await settle()
 check(game.state=="explore" and q("balance").phase=="spar","training loss is nonlethal retry")
 await step("balance");await choose(true);await auto_fight();check(q("balance").phase=="ready","training victory awaits smith")
 await step("balance");check(q("balance").phase=="completed","smith pays trial")
 check(game.money==3050,"five rewards total1050 only")
 for quest in game.suzhou_quests.quests:quest._complete()
 check(game.money==3050 and same_counts(game.progress.stats,stats) and same_counts(game.progress.inventory,inventory) and game.progress.fame==fame and game.progress.faction_favor==favor,"rewards once; no implicit stats/items/favor")
 check(game.save_system.write_slot(4) and game.save_system.load_slot(4),"all completed state persists")
 game.suzhou_quests.chatter("sz_apprentice");check(str(game.dialogue_lines[0][1]).contains("먼저"),"post quest chatter changes");await settle()
 # Return to pre-branch point and exercise both alternative choices.
 check(game.save_system.load_slot(2),"reload branch point")
 await step("silk");await choose(false);await step("silk");await step("silk");check(q("silk").branch=="tell" and q("silk").phase=="completed","player tells dyer alternative")
 await step("rumor");await step("rumor");await step("rumor");await choose(false);await step("rumor");await step("rumor")
 check(q("rumor").branch=="explain" and q("rumor").phase=="completed","clerk explanation alternative")
 var legacy=game.save_system.read_slot(1);legacy.erase("suzhou_quests");legacy.navigation={"quest":"","stage":"","completed":[],"facility":""}
 var f=FileAccess.open(game.save_system.path(5),FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close()
 check(game.save_system.load_slot(5) and q("silk").phase=="available","old saves acquire available quests safely")
 var invalid=game.save_system.capture();invalid.suzhou_quests.suzhou_silk.phase="unknown";check(not game.save_system.validate(invalid),"unknown phases rejected")
 # Actual death callback must preserve the existing save.
 check(game.save_system.write_slot(6),"save before dangerous quest")
 var saved=FileAccess.get_file_as_string(game.save_system.path(6));q("quay").phase="confront";q("quay")._start_battle();game.battle.cancel();game._on_defeat()
 check(game.state=="game_over" and not game.save_system.write_slot(7),"quay loss is death and cannot save")
 check(saved==FileAccess.get_file_as_string(game.save_system.path(6)),"death never overwrites progress")
 game.reset();await create_timer(.8).timeout
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("SUZHOU_QUESTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
