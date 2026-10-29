extends "res://tests/cuiyue_incident.gd"
func shot(file: String) -> void:
 await create_timer(.3).timeout
 for i in range(4):await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+file+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
 game.progress.stats={"strength":18,"agility":18,"constitution":18,"inner":18,"insight":29};game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""]
 prepare_prereqs();game.exploration.load_area("cuiyue_hall");await frames();await shot("cuiyue-incident-confront")
 await drain_to("battle");await frames();await shot("cuiyue-incident-battle");await auto_fight()
 while game.dialogue_lines.size()==2:game.advance_dialogue()
 await shot("cuiyue-incident-stage")
 await drain_to("private");game.advance_dialogue();game.advance_dialogue();await shot("cuiyue-incident-nanjing")
 await drain_to("completed");game.adventure_ui.open_favor();await shot("cuiyue-incident-favor");game.adventure_ui.close_menu()
 game.queue_free();await process_frame;print("CUIYUE_INCIDENT_CAPTURE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
