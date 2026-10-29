extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func frames() -> void:
 await create_timer(.3).timeout
 for i in range(3):await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
 game.cuiyue_incident.phase="completed";game.cuiyue_incident.referral_seen=true
 var q=game.blackguild_story;var w=game.exploration
 for area in ["blackguild_warehouse","blackguild_hall"]:
  q.phase="warehouse" if area=="blackguild_warehouse" else "audience";q.branch="" if q.phase=="warehouse" else "agreement"
  w.load_area(area);await frames()
  var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
  var map=preload("res://scripts/blackguild_map.gd").new(area);view.add_child(map);map.scale=Vector2(.5,.5)
  for npc in w.ambient_nodes:
   var sp=npc.get_child(1).duplicate();sp.position=npc.position*.5;sp.scale*=.5;view.add_child(sp)
  await frames();assert(view.get_texture().get_image().save_png("res://screenshots/"+area.replace("_","-")+"-full.png")==OK);view.queue_free()
 w.player.position=w.city_point([768,565]);w.player.facing="up";w.player.stop();w.camera.snap_to_player();await frames()
 assert(root.get_texture().get_image().save_png("res://screenshots/blackguild-hall-play.png")==OK)
 q.present();await frames();assert(root.get_texture().get_image().save_png("res://screenshots/blackguild-wi-audience.png")==OK)
 game.queue_free();await process_frame;print("BLACKGUILD_CAPTURE: PASS");quit()
