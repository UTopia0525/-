extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 await create_timer(.2).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"]);game.options.seen.erase("prologue_grid_lesson_v1")
 game.prologue.active=true;game.start_battle();await shot("battle-lesson-intro")
 game.battle.lesson.step=3;game.battle.lesson.refresh();game.battle.select_skill("samjae");await shot("battle-lesson-attack")
 game.reset();await create_timer(.7).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame;print("LESSON_CAPTURE: PASS");quit()
