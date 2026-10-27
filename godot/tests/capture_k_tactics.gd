extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide();game.adventure_ui.notification_waiting=false
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
 var p=game.progress
 for id in ["cheongpung","yusu","danseok","hoepung","gwanpung","yeonhwan","josik_suwon"]:
  if id not in p.learned:p.learned.append(id)
 p.loadout=["basic_attack","samjae","cheongpung","josik_suwon"];game.battle.set_loadout(p.loadout)
 game.player_menu.open_menu("martial");game.player_menu.select_slot(2);game.player_menu.select_item("cheongpung");await shot("k-tactics-charge-720")
 root.size=Vector2i(2560,1440);await shot("k-tactics-charge-1440")
 root.size=Vector2i(1280,720);game.player_menu.select_item("hoepung");await shot("k-tactics-area")
 game.player_menu.select_item("yeonhwan");await shot("k-tactics-spear")
 game.player_menu.select_item("josik_suwon");await shot("k-tactics-support")
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("K_TACTICS_CAPTURE: PASS");quit()
