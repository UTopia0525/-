extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(path: String) -> void:
	await create_timer(.15).timeout;await RenderingServer.frame_post_draw;assert(root.get_texture().get_image().save_png(path)==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"mountain_road","arrival":[630,700]}})
	game.exploration.player.facing="right";game.exploration.player.stop();game.adventure_ui.toast.hide();game.exploration.camera.snap_to_player()
	await shot("res://screenshots/short-road-play.png")
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(640,800);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load("res://scripts/mountain_road_map.gd").new();map.scale=Vector2(.25,.25);view.add_child(map)
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/short-road-map.png")==OK)
	view.queue_free();game.reset();await create_timer(.3).timeout
	for v in game.music.players:v.stop();v.stream=null
	for v in game.options.voices:v.stop();v.stream=null
	game.queue_free();await process_frame;quit()
