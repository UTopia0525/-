extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
 for area in ["nanjing_suzhou_road","suzhou"]:
  game.exploration.load_area(area)
  game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([850,355] if area=="nanjing_suzhou_road" else [768,512]));game.exploration.player.stop();game.exploration.camera.snap_to_player()
  game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
  await create_timer(.4).timeout
  for i in range(3):await process_frame;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://screenshots/"+area+"-play.png")==OK)
  var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
  var map=preload("res://scripts/suzhou_map.gd").new(area);view.add_child(map);map.scale=Vector2(1536.0/map.map_bounds.size.x,1024.0/map.map_bounds.size.y)
  if area=="suzhou":
   for npc in game.exploration.ambient_nodes:
    var marker=Node2D.new();marker.position=npc.position;map.actors.add_child(marker)
    marker.add_child(npc.get_child(1).duplicate())
    var label=preload("res://scripts/ui.gd").label(marker,str(npc.get_meta("display_name")),Rect2(-115,-190,230,45),36,Color("ffe4ad"))
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_color_override("font_outline_color",Color("152a26"));label.add_theme_constant_override("outline_size",6)
  await create_timer(.4).timeout
  for i in range(3):await process_frame;await RenderingServer.frame_post_draw
  assert(view.get_texture().get_image().save_png("res://screenshots/"+area+"-full.png")==OK);view.queue_free();await process_frame
 var w=game.exploration;var merchant=w.decorations.get_node("sz_herbalist");var route=w.path_to(merchant.position,true)
 assert(not route.is_empty());w.player.position=route[-1];w.player.stop();w.camera.snap_to_player();game.interact()
 await create_timer(.4).timeout
 for i in range(3):await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/suzhou-herbalist-dialogue.png")==OK)
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
 await create_timer(.4).timeout
 for i in range(3):await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/suzhou-herbalist-trade.png")==OK)
 game.city_service.close_counter()
 game.reset();await create_timer(.8).timeout
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("SUZHOU_CAPTURE: PASS");quit()
