extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var preview=load("res://previews/paper_menu.tscn").instantiate();root.add_child(preview)
 for mode in ["inventory","martial"]:
  preview.show_mode(mode);await create_timer(.4).timeout;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://screenshots/paper-preview-"+mode+".png")==OK)
 preview.queue_free();await process_frame;print("PAPER_PREVIEW: rendered with existing assets");quit()
