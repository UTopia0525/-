extends "res://tests/isometric_town.gd"
## Synthetic definitions exercise UI capacity only; real gameplay remains two quests.
const Errands=preload("res://prototypes/isometric/iso_town_errands.gd")
func wheel(scroll: ScrollContainer) -> void:
 var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_WHEEL_DOWN;event.pressed=true;event.position=scroll.get_global_rect().get_center()
 Input.parse_input_event(event);await frames(2)
 event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await frames(2)
func replace_memory_quests(count: int,source: Dictionary) -> void:
 var old=q;old.get_parent().remove_child(old);old.free()
 q=Errands.new();q.definitions={}
 for i in range(count):
  var id="memory_%02d" % i;var data: Dictionary=source.duplicate(true)
  data.title="메모리 의뢰 %02d" % i;data.objectives={"outside":"바깥 확인 · "+id,"room":"실내 확인 · "+id};q.definitions[id]=data
 world.errand=q;q.setup(world,world.passage);world.passage.add_child(q);await frames(3)
func real_guards() -> void:
 await start()
 for id in q.definitions:
  check(q.target_label_for(id)==q.definitions[id].objectives.outside,"real outside objective "+id)
 await park_npcs();await enter()
 for id in q.definitions:check(q.target_label_for(id)==q.definitions[id].objectives.room,"real room objective "+id)
 await leave()
 q.resolve_for("iso_errand","accept");q.select_quest("iso_errand");var before=quest_snapshot()
 q.select_quest("missing")
 check(quest_snapshot()==before,"invalid selection preserves selection/progress/tracking")
 check(not q.navigation.track("missing","inspect") and quest_snapshot()==before,"invalid navigation request preserves tracking")
 check(q.target_label_for("missing")=="" and q.giver("missing")==null and q.lines_for("missing").is_empty(),"invalid guide/giver/dialogue IDs are safe")
 check(not world.dialogue.inspect_quest("missing"),"invalid investigation ID is safe")
 q.selected_quest="missing";q.refresh_journal();q.toggle_track()
 check(q.track_button.disabled and q.body.text=="의뢰를 선택하세요." and q.navigation.quest_id=="iso_errand","stale selection cannot track or borrow another quest detail")
 q.select_quest("iso_errand");q.navigation.quest_id="missing";q.refresh_objective();q.refresh_journal()
 check(q.objective.text=="" and q.tracked_caption.text=="추적 중인 의뢰 없음","stale tracked ID cannot display another quest guide")
 q.navigation.clear();q.resolve_for("iso_cargo","accept");q.select_quest("iso_errand")
 await frames(2)
 q.open_journal();await frames(3)
 check(q.journal.visible and paused,"real journal opens after interaction release")
 check(q.tracked_caption.text.contains(q.definitions.iso_cargo.title) and q.body.text.begins_with(q.definitions.iso_errand.title),"selected detail and tracked quest are distinct")
 if "--capture" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  check(root.get_texture().get_image().save_png("res://screenshots/isometric-town-journal.png")==OK,"actual two-quest journal capture")
 q.close_journal();world.queue_free();await frames(2)
func memory_case(count: int,source: Dictionary) -> void:
 await start();await replace_memory_quests(count,source)
 var ids=q.definitions.keys()
 check(q.phases.size()==count and q.completions.size()==count and q.marker_nodes.size()==count and q.quest_buttons.size()==count and q.navigation.definitions.size()==count,"exact definition/view registrations count="+str(count))
 var marker_ids={}
 for id in ids:marker_ids[q.marker_nodes[id].label.get_instance_id()]=true
 check(marker_ids.size()==count,"independent marker nodes count="+str(count))
 if count>0:
  var id=ids[-1]
  for state in ["available","active","ready","completed"]:
   q.phases[id]=state;q._process(0)
   var label: Label=q.marker_nodes[id].label
   check(label.visible==(state in ["available","ready"]) and (not label.visible or label.text==("!" if state=="available" else "?")),"synthetic ID marker state "+state)
  q.phases[id]="available"
 q.open_journal();await frames(4)
 if count==0:
  check(q.selected_quest=="" and q.body.text=="표시할 의뢰가 없습니다." and q.track_button.disabled,"empty list has safe detail/action")
  for code in [KEY_DOWN,KEY_END,KEY_ENTER]:await tap(code)
  check(q.navigation.quest_id=="" and q.selected_quest=="","empty navigation does not create tracking")
 else:
  check(q.selected_quest==ids[0] and q.navigation.quest_id=="","first selection does not track")
  for i in range(count):
   var id=ids[i];q.phases[id]=["available","active","ready","completed"][i%4]
  q.refresh_journal()
  for id in ids:
   q.select_quest(id)
   var state={"available":"수락 가능","active":"진행 중","ready":"보고 가능","completed":"완료"}[q.phases[id]]
   check(q.body.text.begins_with(q.definitions[id].title) and q.body.text.contains("상태: "+state) and q.quest_buttons[id].get_meta("selected",false),"matching row/detail/state "+id)
   check(q.track_button.disabled==(q.phases[id] not in ["active","ready"]),"track eligibility "+id)
   check(q.quest_buttons[id].size.x<=q.quest_scroll.size.x,"row remains in list width "+id)
  # Distinct explicit objectives work for IDs that are not the two real IDs.
  q.phases[ids[-1]]="active";q.select_quest(ids[-1])
  check(q.body.text.contains("바깥 확인 · "+ids[-1]) and q.target_label_for(ids[-1])==q.definitions[ids[-1]].objectives.outside,"synthetic ID uses its own objective")
  q.toggle_track();check(q.navigation.quest_id==ids[-1],"selected active quest can be tracked")
  await tap(KEY_ENTER);check(q.navigation.quest_id=="" and q.phases[ids[-1]]=="active","Enter untracks without cancelling quest")
  await tap(KEY_ENTER);check(q.navigation.quest_id==ids[-1],"Enter tracks selected active quest")
  await tap(KEY_HOME);check(q.selected_quest==ids[0] and q.navigation.quest_id==ids[-1],"keyboard selection preserves tracking")
  await tap(KEY_END);await frames(3)
  var button: Button=q.quest_buttons[ids[-1]]
  check(q.selected_quest==ids[-1] and q.quest_scroll.get_global_rect().has_point(button.get_global_rect().get_center()),"End reaches visible last entry")
  if count>1:
   await tap(KEY_UP);check(q.selected_quest==ids[-2] and q.navigation.quest_id==ids[-1],"arrow selection preserves tracking")
  if count>=10:
   await tap(KEY_HOME);await frames(2);await wheel(q.quest_scroll)
   check(q.quest_scroll.scroll_vertical>0,"actual mouse wheel scrolls long list")
   q.quest_scroll.scroll_vertical=int(q.quest_scroll.get_v_scroll_bar().max_value);await frames(3)
   await click(button);check(q.selected_quest==ids[-1],"scrolled last row accepts actual mouse click")
   q.definitions[ids[-1]].objectives.outside="긴 안내\n".repeat(60);q.select_quest(ids[-1]);await frames(3)
   check(q.detail_scroll.get_v_scroll_bar().max_value>q.detail_scroll.get_v_scroll_bar().page,"long detail can scroll")
   await wheel(q.detail_scroll);check(q.detail_scroll.scroll_vertical>0,"actual mouse wheel scrolls detail")
   q.select_quest(ids[0]);check(q.detail_scroll.scroll_vertical==0,"new selection resets detail scroll")
  if count>=3:
   # State-level transitions only, not new playable content.
   for id in ids:q.phases[id]="available";q.completions[id]=0
   q.navigation.clear();q.resolve_for(ids[0],"accept");q.resolve_for(ids[1],"accept");q.resolve_for(ids[2],"accept")
   q.resolve_for(ids[1],"inspect");q.resolve_for(ids[1],"report");q.resolve_for(ids[1],"report")
   check(q.navigation.quest_id==ids[0] and q.phases[ids[0]]=="active" and q.completions[ids[1]]==1,"other acceptance/progress/completion does not steal tracking")
   q.resolve_for(ids[0],"inspect");q.resolve_for(ids[0],"report")
   check(q.navigation.quest_id=="" and q.phases[ids[2]]=="active","tracked completion does not auto-select remaining active quest")
  var before=quest_snapshot();q.select_quest("unknown");check(quest_snapshot()==before,"bad selection leaves populated list state intact")
 await tap(KEY_ESCAPE);check(not paused and not q.journal.visible,"journal closes and restores pause count="+str(count))
 world.queue_free();await frames(2);check(not paused and not physics_interpolation,"scene cleanup count="+str(count))
func run() -> void:
 create_timer(120).timeout.connect(func():push_error("JOURNAL watchdog");quit(2))
 root.size=Vector2i(1280,720)
 var original=FileAccess.get_file_as_string("res://prototypes/isometric/town-quests.json")
 var source: Dictionary=JSON.parse_string(original).values()[0]
 await real_guards()
 for count in [0,1,3,10,30]:await memory_case(count,source)
 check(FileAccess.get_file_as_string("res://prototypes/isometric/town-quests.json")==original,"memory cases leave real two-quest JSON unchanged")
 print("ISOMETRIC_TOWN_JOURNAL: "+("FAIL" if failed else "PASS")+" | checks="+str(checks));quit(1 if failed else 0)
