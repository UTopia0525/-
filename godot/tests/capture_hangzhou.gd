extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func frames() -> void:
 await create_timer(.3).timeout
 for i in range(3):await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("hangzhou")
 var w=game.exploration;w.player.position=w.safe_player_position(w.city_point([785,430]));w.player.stop();w.camera.snap_to_player();await frames()
 assert(root.get_texture().get_image().save_png("res://screenshots/hangzhou-play.png")==OK)
 var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1760,1280);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var map=preload("res://scripts/hangzhou_map.gd").new();view.add_child(map);map.scale=Vector2.ONE/3.2
 await frames();assert(view.get_texture().get_image().save_png("res://screenshots/hangzhou-full.png")==OK)
 # Numbered district names are kept in a separate overview to preserve the clean art.
 for district in w.city_data.districts:
  var marker=preload("res://scripts/ui.gd").label(map,str(district.name),Rect2(Vector2(district.label[0],district.label[1])*3.2-Vector2(230,15),Vector2(460,55)),38,Color("ffe8ac"));marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.add_theme_color_override("font_outline_color",Color("203026"));marker.add_theme_constant_override("outline_size",6)
 await frames();assert(view.get_texture().get_image().save_png("res://screenshots/hangzhou-districts.png")==OK);view.queue_free()
 game.queue_free();await process_frame;print("HANGZHOU_CAPTURE: PASS");quit()
