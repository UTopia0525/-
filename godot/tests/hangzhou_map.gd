extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("HANGZHOU: "+msg)
func travel(id: String) -> void:
 var w=game.exploration
 var exits=w.travel_exits.filter(func(e):return e.id==id);check(exits.size()==1,"one portal "+id)
 if exits.is_empty():return
 w.player.position=exits[0].position;w.player.stop();await physics_frame;await process_frame
 var k=InputEventKey.new();k.keycode=KEY_F;k.physical_keycode=KEY_F;k.pressed=true;Input.parse_input_event(k);await process_frame
 k=InputEventKey.new();k.keycode=KEY_F;k.physical_keycode=KEY_F;k.pressed=false;Input.parse_input_event(k);await physics_frame
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_wuchang();game.exploration.load_area("suzhou_hangzhou_canal")
 var w=game.exploration
 check(not w.path_to(w.city_point([1270,930])).is_empty(),"canal end reachable")
 await travel("travel:hangzhou");check(w.area_name=="hangzhou","F enters Hangzhou")
 check(w.map_bounds.size==Vector2(5888,5632),"expanded city and short exterior approach")
 check(w.ambient_nodes.size()==10 and w.city_data.services.size()==2,"two reused commercial NPCs; no instructor")
 check(not w.can_stand(w.city_point([200,1050])),"lake not walkable")
 for o in w.city_data.objects:
  if not str(o.prefab).begins_with("hz_"):continue
  var r=o.rect;var front=w.city_point([r[0]+r[2]/2,r[1]+r[3]+18]);var path=w.path_to(front)
  check(not path.is_empty(),"front of "+o.id+" reachable")
 for road in w.city_data.roads:
  var a=w.city_point(road.points[0]);var b=w.city_point(road.points[1])
  for i in range(1,20):check(w.can_stand(a.lerp(b,i/20.0)),"clear street "+road.id)
 check(not w.city_data.prefabs.has("hz_martial"),"no martial school")
 for npc in w.ambient_nodes.filter(func(n):return not str(n.get_meta("service_id","")).is_empty()):
  var path=w.path_to(npc.position,true);check(not path.is_empty(),"service NPC reachable")
  if path.is_empty():continue
  w.player.position=path[-1];w.player.stop();await physics_frame;game.interact()
  if game.adventure_ui.window.visible and game.adventure_ui.mode=="topics":
   for button in game.adventure_ui.rows.get_children():
    if button.get_meta("topic","")==("병장기를 살펴본다" if npc.get_meta("service_id")=="city_artisan" else "영약을 살펴본다"):button.pressed.emit();break
  for i in range(20):
   if game.dialogue_lines.is_empty():break
   game.advance_dialogue()
  check(game.city_service.visible and game.state=="service","service opens through conversation")
  game.city_service.close_counter()
 game.toggle_city_map();check(game.city_overview.visible,"TAB map");game.toggle_city_map()
 w.player.position=w.safe_player_position(w.city_point([1080,860]));var pos=w.player.position
 check(game.save_system.write_slot(8) and game.save_system.load_slot(8),"new city save/load")
 check(w.area_name=="hangzhou" and w.player.position.distance_to(pos)<1,"restore city position")
 game.quest_navigation.track("suzhou_silk","offer");check(game.quest_navigation.get_goal(w).goal_id=="travel:canal","quest points back north")
 await travel("travel:canal");check(w.area_name=="suzhou_hangzhou_canal","F returns to canal")
 await travel("travel:suzhou");check(w.area_name=="suzhou","canal returns to Suzhou")
 game.queue_free();await process_frame;print("HANGZHOU: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
