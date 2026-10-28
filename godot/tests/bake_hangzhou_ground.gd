extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1760,1280);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var floor=preload("res://scripts/hangzhou_ground.gd").new();floor.data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/hangzhou/layout.json"));view.add_child(floor)
 for i in range(4):await process_frame;await RenderingServer.frame_post_draw
 assert(view.get_texture().get_image().save_png("res://assets/maps/hangzhou/layout-ground.png")==OK)
 view.queue_free();await process_frame;print("HANGZHOU_GROUND: PASS");quit()
