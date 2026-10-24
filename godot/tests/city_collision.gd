extends SceneTree
var failed := false
var game
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
 if not ok: failed = true; push_error("CITY_COLLISION: " + message)
func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_city()
 await physics_frame
 await physics_frame
 var city = game.exploration
 var player = city.player
 var tested := {}
 var objects: Array = city.city_data.scenery_objects.duplicate(true)
 for obstacle in objects:
  if tested.has(obstacle.kind): continue
  var block: Rect2 = city._city_rect(obstacle.bounds)
  for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
   var extent: Vector2 = block.size / 2 + Vector2(32, 32)
   var start: Vector2 = block.get_center() + direction * extent
   if not city.can_stand(start): continue
   var motion: Vector2 = block.get_center() - start
   var hit := KinematicCollision2D.new()
   check(player.test_move(Transform2D(0, start), motion, hit), "player stopped by " + obstacle.kind)
   check(hit.get_collider() is StaticBody2D and hit.get_collider().collision_layer == 2, "native scenery body for " + obstacle.kind)
   var actor: CharacterBody2D = city.ambient_nodes[0]
   check(actor.test_move(Transform2D(0, start), motion), "NPC stopped by " + obstacle.kind)
   tested[obstacle.kind] = true
   break
 for kind in ["building", "wall", "tree", "cargo", "well", "pond", "stall", "gate"]:
  if tested.has(kind): continue
  # Some water is enclosed by banks: its center must still be solid in physics.
  for obstacle in objects:
   if obstacle.kind != kind: continue
   var query := PhysicsPointQueryParameters2D.new()
   query.position = city._city_rect(obstacle.bounds).get_center()
   query.collision_mask = 2
   var hits: Array = city.get_world_2d().direct_space_state.intersect_point(query)
   check(not hits.is_empty() and not city.can_stand(query.position), "enclosed scenery blocks feet: " + kind)
   tested[kind] = true
   break
  check(tested.has(kind), "physics sample for " + kind)
 var citizen_tested := false
 for actor in city.ambient_nodes:
  var start: Vector2 = actor.position + Vector2(65, 0)
  if not city.can_stand(start): continue
  var hit := KinematicCollision2D.new()
  var stopped: bool = player.test_move(Transform2D(0, start), Vector2(-65, 0), hit)
  if stopped and hit.get_collider() == actor:
   citizen_tested = true
   break
 check(citizen_tested, "player cannot walk through residents")
 # A character standing beside an NPC must still be able to click away.
 var saved_position: Vector2 = player.position
 var departure_tested := false
 for actor in city.ambient_nodes:
  for offset in [Vector2(24, 0), Vector2(-24, 0), Vector2(0, 24), Vector2(0, -24)]:
   var edge: Vector2 = actor.position + offset
   var cell := Vector2i(edge / 20)
   if not city.can_stand(edge) or not city.astar.is_point_solid(cell): continue
   player.position = edge
   check(not city.path_to(saved_position).is_empty(), "click away from occupied containing cell")
   departure_tested = true
   break
  if departure_tested: break
 check(departure_tested, "tested movement beside resident collision edge")
 player.position = saved_position
 for actor in city.ambient_nodes:
  var path: PackedVector2Array = city.path_to(actor.position, true)
  check(not path.is_empty(), "approach NPC: " + str(actor.name))
  if not path.is_empty():
   check(path[-1].distance_to(actor.position) < 78 and path[-1].distance_to(actor.position) > 23, "path ends beside NPC within interaction range")
   for point in path: check(city.can_stand(point), "click path avoids scenery and NPC feet")
 # A pre-redesign save inside a new obstacle recovers to safe ground.
 var inside: Vector2 = city.blockers[0].get_center()
 player.position = inside
 check(game.save_system.write_slot(1), "old-location save accepted")
 check(game.save_system.load_slot(1), "old-location save loads")
 check(city.can_stand(player.position) and player.position.distance_to(inside) > 11, "old save moved out of scenery")
 game.reset()
 await create_timer(1.0).timeout
 for voice in game.music.players: voice.stop(); voice.stream = null
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 print("GODOT_CITY_COLLISION: " + ("FAIL" if failed else "PASS — scenery, NPC bodies, approach paths, old saves"))
 quit(1 if failed else 0)
