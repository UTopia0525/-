extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func frames() -> void:
 await create_timer(.3).timeout
 for i in range(3):await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("murong_estate")
 var w=game.exploration;game.suzhou_quests.get_quest("suzhou_balance").phase="completed"
 w.player.position=w.safe_player_position(w.city_point([768,690]));w.player.stop();w.camera.snap_to_player();await frames()
 assert(root.get_texture().get_image().save_png("res://screenshots/murong-estate-play.png")==OK)
 var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var map=preload("res://scripts/murong_map.gd").new();view.add_child(map);map.scale=Vector2.ONE/3
 for npc in w.ambient_nodes:
  var marker=Node2D.new();marker.position=npc.position;map.actors.add_child(marker);marker.add_child(npc.get_child(1).duplicate())
  var label=preload("res://scripts/ui.gd").label(marker,str(npc.get_meta("display_name")),Rect2(-130,-190,260,45),32,Color("ffe4ad"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_color_override("font_outline_color",Color("152a26"));label.add_theme_constant_override("outline_size",5)
 await frames();assert(view.get_texture().get_image().save_png("res://screenshots/murong-estate-full.png")==OK);view.queue_free()
 var q=game.suzhou_quests.get_quest("suzhou_murong");q.phase="hear";q.present();game.advance_dialogue();game.advance_dialogue();await frames()
 assert(root.get_texture().get_image().save_png("res://screenshots/murong-livelihood-dialogue.png")==OK)
 game.queue_free();await process_frame;print("MURONG_CAPTURE: PASS");quit()
