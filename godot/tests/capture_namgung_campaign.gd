extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
 await create_timer(.25).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"]);game.start_wuchang()
 var q=game.qingya_quest;q.phase="completed";q.ruined=true;q.regret_seen=true;q.ruin_intro=true
 game.waterfront_quest.phase="completed";game.progress.add_favor("namgung",10)
 var n=game.namgung_campaign;n._travel("namgung_estate",[1460,1490]);n.phase="preparing";n.refresh_world();await shot("namgung-estate-play")
 game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([920,1470]));game.exploration.camera.snap_to_player();await shot("namgung-warrior-map")
 game.interact();await shot("namgung-gatekeeper")
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
 var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(2304,1536);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var map=preload("res://scripts/namgung_map.gd").new();map.scale=Vector2.ONE/3;view.add_child(map);await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(view.get_texture().get_image().save_png("res://screenshots/namgung-estate-full.png")==OK);view.queue_free();await process_frame
 game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point([1460,1490]));game.exploration.camera.snap_to_player()
 game.say(n.data.scenes.intro);await shot("namgung-seojin-dialogue")
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
 n.phase="battle";game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20};game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""]
 game.start_battle(n.data.encounter)
 await create_timer(1.0).timeout;await shot("namgung-maunpyo-battle")
 game.battle.cancel();game.battle.hide();game.state="explore";game.exploration.show();game.top_hud.show();game.bottom_hint.show();game.exploration.camera.enabled=true;n.phase="return";n._travel("qingya_hamlet",[900,650]);await shot("namgung-village-return")
 game.progress.inventory["namgung_cheongcheon_pill"]=1;game.player_menu.open_menu("inventory");game.player_menu.select_item("namgung_cheongcheon_pill");await shot("namgung-secret-elixir")
 game.reset();await create_timer(.8).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame;print("NAMGUNG_CAPTURE: PASS");quit()
