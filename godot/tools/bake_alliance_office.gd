extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	for atlas in [false,true]:
		var view=SubViewport.new();view.world_2d=World2D.new();view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;view.transparent_bg=atlas;view.size=Vector2i(384,200) if atlas else Vector2i(512,360);root.add_child(view)
		var floor=load("res://scripts/alliance_office_ground.gd").new();floor.atlas_mode=atlas;view.add_child(floor)
		await create_timer(.2).timeout;await RenderingServer.frame_post_draw
		assert(view.get_texture().get_image().save_png("res://assets/maps/alliance-office/"+("furniture.png" if atlas else "ground.png"))==OK)
		view.free()
	quit()
