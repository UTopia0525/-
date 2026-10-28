extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("SUZHOU_RESIDENTS: "+msg)
func drain() -> void:
 for i in range(20):
  if game.dialogue_lines.is_empty():return
  game.advance_dialogue()
 check(false,"dialogue terminates")
func press_f() -> void:
 var k=InputEventKey.new();k.keycode=KEY_F;k.physical_keycode=KEY_F;k.pressed=true;Input.parse_input_event(k);await process_frame
 k=InputEventKey.new();k.keycode=KEY_F;k.physical_keycode=KEY_F;k.pressed=false;Input.parse_input_event(k);await physics_frame
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("suzhou");await physics_frame;await physics_frame
 var w=game.exploration
 check(w.ambient_nodes.size()==14 and w.city_data.residents.size()==14,"fourteen unique residents")
 check(w.city_data.services.size()==3,"three existing service types")
 var quests=game.ordinary_quests.snapshot();var intro=game.trade_intro.snapshot();var balance=game.money;var progression=game.progress.snapshot()
 var portraits=[];var placement={};var npcs=[]
 for entry in w.city_data.residents:
  var npc=w.decorations.get_node(entry.id);npcs.append(npc)
  placement[entry.id]=[npc.position.x/3,npc.position.y/3]
  var visual=Rect2(npc.position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
  for bounds in w.scenery_bounds:check(not visual.grow(6).intersects(bounds),"full body avoids scenery "+entry.name)
  for road in w.city_data.road_centers:check(not Rect2(road[0]*3,road[1]*3,road[2]*3,road[3]*3).has_point(npc.position),"feet out of main road "+entry.name)
  check(not entry.quest_actor and not npc.get_meta("story_actor"),"no faction or quest actor added")
  var texture=game.dialogue_cast.texture_for(game.PORTRAITS.ACTORS[entry.id])
  check(texture.resource_path==game.dialogue_cast.basic_portraits[entry.basic_portrait].path,"existing portrait reused "+entry.name)
  check(texture.resource_path not in portraits,"distinct local portrait "+entry.name);portraits.append(texture.resource_path)
  var path=w.path_to(npc.position,true);check(not path.is_empty(),"reachable talk position "+entry.name)
  if path.is_empty():continue
  w.player.position=path[-1];w.player.stop();await physics_frame
  check(w.nearest().get("id")==entry.id,"F selects intended resident "+entry.name)
  await press_f()
  check(game.dialogue_cast.active_actor==entry.id and game.dialogue_name.text==entry.name,"correct speaker and name "+entry.name)
  check(game.dialogue_backdrop.visible,"conversation dims city")
  check(not game.save_system.blocked_reason().is_empty(),"dialogue saving remains blocked")
  drain()
  if entry.has("service_id"):
   check(game.state=="service" and game.city_service.visible,"greeting opens trade "+entry.name)
   check(game.city_service.service.actor_id==entry.id,"trade uses same identity")
   check(game.city_service.rows.get_child_count()>0,"existing catalog displayed")
   game.city_service.close_counter()
  check(w.active and game.dialogue_lines.is_empty(),"exploration restored")
 for i in range(npcs.size()):
  for j in range(i):
   var a=Rect2(npcs[i].position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
   var b=Rect2(npcs[j].position+w.CITIZEN_BOUNDS.position,w.CITIZEN_BOUNDS.size)
   check(not a.grow(8).intersects(b),"resident silhouettes separated")
 print("SUZHOU_PLACEMENT "+JSON.stringify(placement))
 check(game.ordinary_quests.snapshot()==quests and game.trade_intro.snapshot()==intro,"talk never completes old quests")
 check(game.money==balance and game.progress.snapshot()==progression,"chatter creates no rewards or stat changes")
 for service in w.city_data.services:
  game.quest_navigation.facility_id=service.id
  check(game.quest_navigation.get_goal(w).label.begins_with(service.name),"facility guide targets local resident")
 game.quest_navigation.clear()
 check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"populated city save/load")
 check(w.ambient_nodes.size()==14,"reload has no duplicates")
 w.load_area("nanjing_suzhou_road");check(w.ambient_nodes.is_empty(),"mountain pass stays empty")
 w.load_area("suzhou");check(w.ambient_nodes.size()==14,"revisit restores residents once")
 game.reset();await create_timer(.8).timeout
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("SUZHOU_RESIDENTS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
