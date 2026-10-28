extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("SUZHOU_MAPS: "+msg)
func travel(id: String) -> void:
 var w=game.exploration
 var exits=w.travel_exits.filter(func(e):return e.id==id)
 check(exits.size()==1,"one exit "+id)
 if exits.is_empty():return
 w.player.position=exits[0].position;w.player.stop()
 await physics_frame;await process_frame
 var key=InputEventKey.new();key.keycode=KEY_F;key.physical_keycode=KEY_F;key.pressed=true
 Input.parse_input_event(key);await process_frame
 key=InputEventKey.new();key.keycode=KEY_F;key.physical_keycode=KEY_F;key.pressed=false
 Input.parse_input_event(key);await physics_frame
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("nanjing")
 var w=game.exploration
 check(w.can_stand(w.city_point([1470,995])),"Nanjing east exit on walkable ground")
 await travel("travel:suzhou_road");check(w.area_name=="nanjing_suzhou_road","F exits Nanjing to pass")
 check(w.ambient_nodes.is_empty() and w.npcs.is_empty(),"road has no NPCs")
 var path=w.path_to(w.city_point([1500,570]));check(not path.is_empty(),"entire mountain pass connected")
 for p in path:check(w.can_stand(p),"mountain path avoids blocked cliffs/trees")
 print("SUZHOU_ROAD_PATH: "+str(path.size())+" waypoints")
 check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"road save/load")
 await travel("travel:suzhou");check(w.area_name=="suzhou","F enters Suzhou west")
 check(w.ambient_nodes.size()==14 and w.npcs.is_empty() and w.city_data.services.size()==3,"Suzhou civilian population and services")
 check(w.player.display_height==140 and w.player.speed==360,"shared character size and speed")
 check(not w.can_stand(w.city_point([768,400])),"canal water blocks walking")
 for y in w.city_data.bridges:
  var a=w.city_point([660,y]);var b=w.city_point([870,y]);var route=w.regional_map.path_to(a,b)
  check(not route.is_empty(),"bridge connected at "+str(y))
  check(w.can_stand(w.city_point([768,y])),"bridge middle walkable")
  var collision=KinematicCollision2D.new()
  check(not w.player.test_move(Transform2D(0,a),b-a,collision),"physical bridge crossing clear")
 for point in [[380,245],[400,512],[1000,275],[1100,512],[1100,788],[1000,860]]:
  check(not w.path_to(w.city_point(point)).is_empty(),"district reachable "+str(point))
 for node in w.scenery_nodes:
  if node.get_meta("kind")=="building":check(not w.can_stand(node.collision_rects[0].get_center()),"building collision "+str(node.name))
 game.toggle_city_map();check(game.city_overview.visible,"Tab map supports Suzhou");game.toggle_city_map()
 check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"Suzhou save/load")
 await travel("travel:suzhou_road");check(w.area_name=="nanjing_suzhou_road","Suzhou returns to road")
 await travel("travel:nanjing");check(w.area_name=="nanjing","road returns to Nanjing")
 game.reset();await create_timer(.8).timeout
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("SUZHOU_MAPS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
