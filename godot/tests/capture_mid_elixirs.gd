extends "res://tests/mid_elixirs.gd"
func shot(file: String) -> void:
 await create_timer(.2).timeout
 for i in range(5):await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://screenshots/"+file+".png")==OK,"screenshot "+file)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
 prepare_prereqs();game.progress.learned.append("hoeryu");game.progress.add_favor("haomun",20);game.cuiyue_incident.phase="completed"
 game.progress.stats={"strength":78,"agility":73,"constitution":73,"inner":73,"insight":32};game.money=3500
 for id in ["bear_strength_pill","light_step_pill","bone_fortifying_pill","qi_nourishing_pill"]:game.progress.consumed[id]=10
 var w=game.exploration;w.load_area("cuiyue_hall");await frames();w.player.position=w.travel_exits[0].position;w.player.stop();await frames();await press_f()
 game.cuiyue_incident.track();await shot("mid-elixirs-referral");await settle()
 game.hangzhou_quests.trade("hz_herbalist");await settle()
 var shop=game.city_service;shop.select_item(MID_IDS[0]);await frames();shop.rows.get_parent().scroll_vertical=300
 await shot("mid-elixirs-shop")
 shop.transact();shop.close_counter();game.player_menu.open_menu("inventory");game.player_menu.category="elixir";game.player_menu.select_item(MID_IDS[0])
 await shot("mid-elixirs-inventory")
 game.queue_free();await process_frame;print("MID_ELIXIRS_CAPTURE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
