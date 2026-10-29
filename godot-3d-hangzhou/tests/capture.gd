extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(path: String) -> void:
 for i in range(8):await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+path+".png")==OK)
func photo(pos: Vector3,target: Vector3) -> void:
 game.scenic.position=pos;game.scenic.look_at(target);game.scenic.current=true
func run() -> void:
 root.size=Vector2i(1440,900);game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 for i in range(30):await physics_frame
 game.player.control_enabled=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 await shot("01-night-market")
 photo(Vector3(49,40,62),Vector3(-3,3,-5));await shot("02-city-overview")
 photo(Vector3(-16,8,-19),Vector3(-31,10,-43));await shot("03-cuiyue-tower")
 photo(Vector3(14,7,25),Vector3(0,3,7));await shot("04-pleasure-barge")
 game.player.position=Vector3(18,.6,15);game.player.avatar.rotation.y=PI
 photo(game.player.position+Vector3(1.9,1.6,-3.6),game.player.position+Vector3(0,1.05,0));await shot("05-dowon-model")
 print("HANGZHOU_3D_CAPTURE: PASS");game.queue_free();await process_frame;quit()
