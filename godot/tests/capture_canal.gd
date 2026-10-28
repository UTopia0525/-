extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func frames() -> void:
 await create_timer(.3).timeout
 for i in range(3):await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("suzhou_hangzhou_canal")
 var w=game.exploration;w.player.position=w.safe_player_position(w.city_point([1000,500]));w.player.stop();w.camera.snap_to_player();await frames()
 assert(root.get_texture().get_image().save_png("res://screenshots/canal-play.png")==OK)
 var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1536,1024);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var map=preload("res://scripts/canal_map.gd").new();view.add_child(map);map.scale=Vector2.ONE*.5
 await frames();assert(view.get_texture().get_image().save_png("res://screenshots/canal-full.png")==OK);view.queue_free()
 game.queue_free();await process_frame;print("CANAL_CAPTURE: PASS");quit()
