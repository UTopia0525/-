extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.toast.hide();game.adventure_ui.pending_toasts.clear()
 await create_timer(.5).timeout
 for i in range(3):
  await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
 var p=game.exploration.player;p.facing="left";p.stop();game.exploration.camera.snap_to_player()
 await shot("player-appearance-field")
 game.say([["hero","길이 멀어도 한 걸음씩 나아가면 되겠지."]],Callable(),["hero","city_merchant"])
 assert(game.dialogue_panel.visible and not game.dialogue_lines.is_empty())
 await shot("player-appearance-dialogue")
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
 game.start_battle();await create_timer(.6).timeout;await shot("player-appearance-battle")
 game.battle.cancel();game.reset();await create_timer(.8).timeout
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("PLAYER_APPEARANCE_CAPTURE: PASS");quit()
