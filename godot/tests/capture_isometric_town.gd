extends "res://tests/isometric_town.gd"
var output="res://prototypes/isometric/screenshots/"
func take(name: String) -> void:
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"town-"+name+".png")
 print("TOWN_STILL ",name)
func run() -> void:
 root.size=Vector2i(1280,720);await start()
 world.follow=false;world.camera.zoom=Vector2.ONE*.35;world.place_camera(world.camera_bounds().get_center());world.camera.reset_physics_interpolation()
 await take("overview")
 world.camera.zoom=Vector2.ONE*.85;world.follow=true;world.snap_camera();await take("entry")
 world.actor.set_logical(Vector2(4.72,7.7));world.snap_camera();await take("courtyard")
 world.actor.set_logical(Vector2(21.2,8.3));world.snap_camera();await take("market")
 await accept("iso_errand");await accept("iso_cargo");await tap(KEY_Q);await take("journal");await tap(KEY_Q)
 await enter();world.passage.room.actor.set_logical(Vector2(2.7,2.8));world.passage.room.snap_camera();await take("room");await inspect("iso_errand");await leave()
 await approach("TownMerchant");world.snap_camera();await tap(KEY_F);await finish_dialogue();await take("shop")
 await click(q.shop.action);await take("purchase");await tap(KEY_ESCAPE)
 world.queue_free();await process_frame;quit(1 if failed else 0)
