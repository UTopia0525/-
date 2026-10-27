extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	await shot("title-no-save")
	game.options.seen.append_array(["city","dialogue","trade"])
	game.start_city();assert(game.save_system.write_slot(1))
	game.exploration.load_area("wuchang");assert(game.save_system.write_slot(2))
	game.exploration.load_area("nanjing");assert(game.save_system.write_slot(3))
	game.reset();await shot("title-river-sunset")
	game.title_screen.open_load();await shot("title-load-saves")
	game.queue_free();await process_frame;quit()
