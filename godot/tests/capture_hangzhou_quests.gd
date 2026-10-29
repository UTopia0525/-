extends "res://tests/hangzhou_quests.gd"
func frames() -> void:
 await create_timer(.25).timeout
 for i in range(4):await process_frame;await RenderingServer.frame_post_draw
func shot(file: String) -> void:
 await frames();assert(root.get_texture().get_image().save_png("res://screenshots/"+file+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("cuiyue_hall")
 var w=game.exploration;w.player.position=w.safe_player_position(w.decorations.get_node("cy_waiter").position+Vector2(100,100));w.player.stop();w.camera.snap_to_player()
 game.hangzhou_quests.refresh_world();await shot("hangzhou-quest-markers")
 game.adventure_ui.open_journal();game.adventure_ui.set_filter("available");game.adventure_ui.select_quest("hangzhou_after_song");await frames();game.adventure_ui.rows.get_parent().scroll_vertical=int(game.adventure_ui.rows.get_parent().get_v_scroll_bar().max_value);await shot("hangzhou-quest-journal");game.adventure_ui.close_menu()
 await talk("cy_waiter","after_song");game.advance_dialogue();game.advance_dialogue();await shot("hangzhou-love-request");await settle();await choose(true)
 await step("after_song");await step("after_song");await step("after_song");await shot("hangzhou-love-choice");await choose(true)
 await talk("cy_pipa","after_song");game.advance_dialogue();await shot("hangzhou-love-response");await settle();await step("after_song")
 game.queue_free();await process_frame;print("HANGZHOU_QUEST_CAPTURE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
