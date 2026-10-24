extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	for spec in [["mountain_road_map.gd","overland-full-map",Vector2i(1024,1280)],["wuchang_map.gd","wuchang-full-map",Vector2i(2048,1920)],["alliance_office_map.gd","alliance-office-full-map",Vector2i(1536,1080)]]:
		var view=SubViewport.new();view.world_2d=World2D.new();view.size=spec[2];view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
		var map=load("res://scripts/"+spec[0]).new();view.add_child(map)
		map.scale=Vector2(view.size)/map.map_bounds.size
		await create_timer(.4).timeout;await RenderingServer.frame_post_draw
		var rendered=view.get_texture().get_image()
		assert(rendered.get_pixel(8,8)!=Color.WHITE,"Ground texture must remain alive after _draw")
		assert(rendered.save_png("res://screenshots/"+spec[1]+".png")==OK)
		view.free();await process_frame
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.options.seen.append("city");game.start_wuchang()
	for spec in [["wuchang",[780,1215],"wuchang-art-market"],["mountain_road",[630,700],"overland-art-pass"],["alliance_office",[256,222],"alliance-office-interior"]]:
		preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":spec[0],"arrival":spec[1]}})
		await create_timer(3.7).timeout;await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://screenshots/"+spec[2]+".png")==OK)
		if spec[0]=="alliance_office":
			game.toggle_city_map();await create_timer(.3).timeout;await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("res://screenshots/alliance-office-map.png")==OK);game.toggle_city_map()
	game.reset()
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame;quit()
