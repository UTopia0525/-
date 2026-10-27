extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("EXPLORATION_HUD: "+msg)
func settle() -> void:
 await process_frame;await process_frame;game.exploration_hud.refresh()
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_city();game.chapter_number=1;await settle()
 check(game.objective.text=="장사를 탐사하세요" and not game.chapter_goal.visible,"no side quest: main objective only")
 game.quest_navigation.track("changsha_cloth","deliver");await settle()
 check(game.chapter_goal.visible and game.chapter_goal.text.contains("장사를 탐사하세요") and game.quest_heading.text.contains("맡겨 둔 옷감"),"main story subdued above tracked quest")
 check(not game.objective.text.contains("영약 거래"),"HUD keeps next action, Q retains full stage wording")
 check(game.objective_meta.text.contains("Q") and not game.bottom_hint.visible,"metadata and compact help replace full key bar")
 check(game.compact_toolbar.get_children().filter(func(n):return n is Button).size()==1,"one compact help button")
 var w=game.exploration;var actor=w.ambient_nodes[0];w.player.position=actor.position+Vector2(0,50);w.camera.snap_to_player();await settle()
 check(w.hint.visible and w.hint.text.contains(str(w.nearest().name)) and w.hint.text.begins_with("F ·"),"F target name and action")
 var tag: Label=actor.get_meta("nameplate_label");check(tag.visible,"near target name visible")
 var mark: Label=game.ordinary_quests.marks[actor.get_meta("npc_id")]
 if mark.visible:check(not mark.get_global_rect().intersects(tag.get_global_rect()),"head symbol separate from name")
 for other in w.ambient_nodes:
  if other.position.distance_to(w.player.position)>240:check(not other.get_meta("nameplate_label").visible,"distant names hidden")
 check(game.ordinary_quests.marks.values().any(func(n):return n.text=="!" and n.visible and n.global_position.distance_to(w.player.global_position)>240),"distant available quest symbol kept")
 # An active, untracked investigation remains playable but loses its diamond.
 game.ordinary_quests.records.changsha_waterway={"status":"active","done":[],"branch":""};game.ordinary_quests.refresh_world();await settle()
 var goal_nodes=game.ordinary_quests.goal_nodes.duplicate();check(not goal_nodes.is_empty(),"investigation objectives exist")
 for node in goal_nodes:
  for child in node.get_children():
   if child is Label and child.text=="◆":check(not child.visible,"untracked investigation marker hidden")
 game.quest_navigation.track("changsha_waterway",game.ordinary_quests.stage_for("changsha_waterway"));await settle()
 check(game.exploration_hud.rendered_badges.any(func(n):return n.text=="◆"),"tracked investigation diamond visible")
 check(game.ordinary_quests.records.changsha_waterway.status=="active" and w.objectives.size()>0,"display filtering preserves quest state and interaction objects")
 game.quest_navigation.clear();game.exploration.load_area("wuchang");
 for npc in w.ambient_nodes:
  if npc.get_meta("npc_id","")==game.herbalist_quest.GIVER:w.player.position=w.safe_player_position(npc.position+Vector2(0,55));break
 await settle();game.minimap.refresh()
 check(game.minimap.quest_badges.any(func(n):return n.symbol=="!"),"minimap retains available quests")
 game.minimap.quest_badges.assign([{"position":Vector2(50,50),"symbol":"!"},{"position":Vector2(54,53),"symbol":"!"}])
 check(game.minimap.badge_groups().size()==1 and game.minimap.badge_groups()[0].count==2,"nearby minimap symbols group with count")
 game.herbalist_quest.phase="search";game.herbalist_quest.refresh_world();game.quest_navigation.track(game.herbalist_quest.ID,"search");await settle()
 check(game.objective_meta.text.contains("다른 지역") and game.minimap.quest_active,"cross-region next exit remains guided")
 game.adventure_ui.open_journal();await settle();check(not game.compact_toolbar.visible and game.exploration_hud.rendered_names.is_empty(),"paused menu suppresses field labels and key hint")
 game.adventure_ui.close_menu();await settle()
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide();game.adventure_ui.notification_waiting=false
 game.say([["hero","길을 살펴보자."]]);game.adventure_ui.notify("검사 알림");await settle()
 check(not game.adventure_ui.toast.visible and game.adventure_ui.notification_waiting,"notification waits outside dialogue")
 game.advance_dialogue();await settle();check(game.adventure_ui.toast.visible and game.adventure_ui.toast.text=="검사 알림","queued notification resumes in exploration")
 check(game.adventure_ui.toast.get_global_rect().end.x<game.quest_heading.get_global_rect().position.x,"notification avoids goal panel")
 game.queue_free();await process_frame;print("EXPLORATION_HUD: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
