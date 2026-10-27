extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide();game.adventure_ui.notification_waiting=false
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["battle","city","dialogue","trade"])
 game.start_battle();var b=game.battle;b.select_samjae();await shot("battle-hud-refined-720")
 root.size=Vector2i(2560,1440);await shot("battle-hud-refined-1440")
 root.size=Vector2i(1280,720);b.qi.restore(10,2);b.select_samjae();await shot("battle-hud-refined-unavailable")
 b.select_skill("basic_defense");await shot("battle-hud-refined-defense")
 b.qi.restore(20,80);b.player_stats.inner=20;b.set_loadout(["basic_attack","basic_defense","samjae","josik_suwon"]);b.select_skill("josik_suwon");await shot("battle-hud-refined-support")
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("BATTLE_HUD_CAPTURE: PASS");quit()
