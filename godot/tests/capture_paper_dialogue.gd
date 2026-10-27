extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("nanjing");game.adventure_ui.hide();game.top_hud.hide();game.bottom_hint.hide();game.settings_menu.gear.hide()
 game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([845,300]));game.exploration.camera.snap_to_player();game.exploration.set_active(false)
 var preview=load("res://previews/paper_dialogue.gd").new();preview.game=game;game.ui_root.add_child(preview)
 for mode in ["pair","group","hero","crowd"]:
  preview.scene_for(mode);await create_timer(.3).timeout;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://screenshots/paper-dialogue-"+mode+".png")==OK)
 preview.queue_free();game.reset();game.queue_free();await process_frame;print("PAPER_DIALOGUE: four compositions rendered; unique portraits and shared eye-line framing");quit()
