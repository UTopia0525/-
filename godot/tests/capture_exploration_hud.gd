extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide();game.adventure_ui.notification_waiting=false
 await create_timer(.4).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_city();game.chapter_number=1
 game.quest_navigation.clear();await shot("hud-main-objective")
 game.quest_navigation.track("changsha_cloth","deliver")
 var w=game.exploration
 for actor in w.ambient_nodes:
  if actor.get_meta("service_id","")=="city_merchant":w.player.position=w.safe_player_position(actor.position+Vector2(0,55));break
 w.camera.snap_to_player();await shot("hud-nearby-npc")
 game.exploration.load_area("wuchang");game.herbalist_quest.phase="search";game.herbalist_quest.refresh_world();game.quest_navigation.track(game.herbalist_quest.ID,"search")
 game.exploration.camera.snap_to_player();await shot("hud-cross-region")
 game.exploration.load_area("nanjing");game.quest_navigation.clear();game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([770,510]));game.exploration.camera.snap_to_player();await shot("hud-nanjing")
 game.queue_free();await process_frame;quit()
