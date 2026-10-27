extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.toast.hide();game.adventure_ui.pending_toasts.clear()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.start_story()
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
 await shot("prologue-dock-art-play")
 game.top_hud.hide();game.bottom_hint.hide();game.adventure_ui.hide();game.settings_menu.gear.hide();game.exploration.camera.zoom=Vector2.ONE;game.exploration.player.position=Vector2(400,560);game.exploration.camera.snap_to_player()
 await shot("prologue-dock-art-full")
 game.reset();game.queue_free();await process_frame;quit()
