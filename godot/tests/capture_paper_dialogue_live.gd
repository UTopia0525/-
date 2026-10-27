extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.toast.hide();game.adventure_ui.pending_toasts.clear()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang();game.exploration.load_area("nanjing")
 game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([845,300]));game.exploration.camera.snap_to_player()
 game.say(game.book_quest.data.scenes.post_giver,Callable(),["hero","nj_crowd_book_buyer"]);await shot("paper-dialogue-live-group")
 game.say(game.levy_quest.data.scenes.post_guard,Callable(),["hero","nj_vendor","nj_crowd_clerk_runner"]);await shot("paper-dialogue-live-crowd")
 game.say(game.book_quest.data.scenes.report)
 for i in range(4):game.advance_dialogue()
 await shot("paper-dialogue-live-hero")
 game.dialogue_history.open_history();await shot("paper-dialogue-live-history");game.dialogue_history.close_history()
 game.options.update("size",2);game.say([["hero","장사에서 무창으로, 다시 남경까지 길을 걸어왔소. 번화한 나루에서는 많은 사람이 짐을 나르고 있었지만, 그 모두가 넉넉한 것은 아니었소. 한 사람을 돕는 일이 다른 사람의 어려움까지 모두 해결하는 것은 아니라는 것을 이제 조금은 알 것 같소."]],Callable(),["hero","nj_vendor","nj_crowd_clerk_runner","nj_constable"])
 await shot("paper-dialogue-live-large")
 game.options.update("size",1);game.reset();game.queue_free();await process_frame;quit()
