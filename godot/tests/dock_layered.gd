extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.start_story()
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
 var w=game.exploration
 assert(w.area_name=="dock" and w.scenery_nodes.size()==9 and w.decorations.y_sort_enabled)
 assert(w.art_tiles.size()==9)
 for node in w.scenery_nodes:
  assert(node.get_parent()==w.decorations and not node.collision_rects.is_empty())
  assert(not w.can_stand(node.collision_rects[0].get_center()))
 assert(w.can_stand(Vector2(385,95))) # passage behind the roofline
 assert(not w.can_stand(Vector2(850,550))) # river is impassable
 assert(w.can_stand(Vector2(810,365))) # boarding pier
 for entry in w.npcs:assert(not w.path_to(entry.position,true).is_empty())
 assert(game.save_system.write_slot(8))
 assert(game.save_system.load_slot(8))
 assert(w.area_name=="dock" and w.scenery_nodes.size()==9)
 w.load_area("deck");assert(w.scenery_nodes.is_empty())
 w.load_area("dock");assert(w.scenery_nodes.size()==9)
 game.reset();game.queue_free();await process_frame
 print("DOCK_LAYERED: PASS — separate art, depth sorting, collision, water, pier, saves and revisits");quit()
