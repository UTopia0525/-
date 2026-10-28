extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("CANAL: "+msg)
func travel(id: String) -> void:
 var w=game.exploration
 for exit in w.travel_exits:
  if exit.id==id:w.player.position=exit.position;w.player.stop()
 await physics_frame;await process_frame
 var key=InputEventKey.new();key.keycode=KEY_F;key.physical_keycode=KEY_F;key.pressed=true;Input.parse_input_event(key);await process_frame
 key=InputEventKey.new();key.keycode=KEY_F;key.physical_keycode=KEY_F;key.pressed=false;Input.parse_input_event(key);await physics_frame
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_wuchang();game.exploration.load_area("suzhou")
 var w=game.exploration
 check(not w.path_to(w.city_point([1100,990])).is_empty(),"Suzhou south portal reachable")
 await travel("travel:canal");check(w.area_name=="suzhou_hangzhou_canal","F enters canal")
 check(w.ambient_nodes.is_empty() and w.npcs.is_empty(),"no NPCs")
 var path=w.path_to(w.city_point([1270,930]));check(not path.is_empty(),"whole route connected")
 for p in path:check(w.can_stand(p),"path physically clear")
 check(not w.path_to(w.city_point([1030,710])).is_empty(),"small wharf reachable")
 check(not w.can_stand(w.city_point([850,350])) and not w.can_stand(w.city_point([850,680])),"cannot walk on canal")
 check(not w.can_stand(w.city_point([1270,1010])),"south end bounded until Hangzhou added")
 check(w.travel_exits.size()==1 and w.travel_exits[0].travel.area=="suzhou","no dead portal into unimplemented city")
 game.toggle_city_map();check(game.city_overview.visible,"full map opens");game.toggle_city_map()
 w.player.position=w.safe_player_position(w.city_point([1200,800]));var saved=w.player.position
 check(game.save_system.write_slot(8) and game.save_system.load_slot(8),"canal save/load")
 check(w.area_name=="suzhou_hangzhou_canal" and w.player.position.distance_to(saved)<1,"save preserves position")
 game.quest_navigation.track("suzhou_silk","offer")
 check(game.quest_navigation.get_goal(w).goal_id=="travel:suzhou","quest points back to Suzhou")
 await travel("travel:suzhou");check(w.area_name=="suzhou","F returns to Suzhou")
 check(game.save_system.write_slot(9) and game.save_system.load_slot(9),"city save still works")
 game.queue_free();await process_frame;print("CANAL: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
