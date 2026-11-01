extends SceneTree
## Single still at the widened entrance boundary. No movie writer.
var output="/tmp/isometric-entry.png"
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
 run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var host=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(host)
 host.patrols_enabled=false
 for i in range(host.npcs.size()):host.npcs[i].set_logical(Vector2(19,14+i*.6))
 var threshold=Vector2(host.passage.doorway.threshold[0],host.passage.doorway.threshold[1])
 host.actor.set_logical(threshold+Vector2(1.25,0));host.actor.set_pose("back",true);host.snap_camera();host.reset_physics_interpolation()
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image();var err=image.save_png(output)
 print("ENTRY_STILL ",output," | F_offer=",host.passage.offer()," | result=",err)
 host.queue_free();await process_frame;quit(0 if err==OK else 1)
