extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("DEDICATED_NPC: "+msg)
func verify() -> void:
 var w=game.exploration
 var actors=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")=="namgung_seojin")
 check(actors.size()==1,"one Seojin per map")
 if actors.is_empty():return
 var actor=actors[0];var sprite=actor.get_child(1)
 check(sprite.texture.atlas.resource_path=="res://assets/characters/namgung/seojin.png","unique sprite on "+w.area_name)
 check(game.PORTRAITS.ACTORS.namgung_seojin.portrait=="res://assets/portraits/namgung/seojin.png","approved portrait unchanged")
 check(sprite.offset.y+sprite.texture.get_height()==0,"feet anchored to world position")
 for n in w.ambient_nodes:
  var id=str(n.get_meta("npc_id"))
  if id=="ng_gatekeeper" or id.begins_with("ng_guard_"):
   check(n.get_child(1).texture.atlas.resource_path==game.namgung_campaign.warrior_visual.sprite,"ordinary warrior remains distinct")
func shot(name: String) -> void:
 if not "--capture" in OS.get_cmdline_user_args():return
 var w=game.exploration
 var npc=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")=="namgung_seojin")[0]
 w.player.position=w.safe_player_position(npc.position+Vector2(130,130));w.camera.snap_to_player()
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK,"capture "+name)
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"]);game.start_wuchang()
 var q=game.qingya_quest;q.phase="completed";q.branch="assault";q.reward_stat="strength";q.departed=true;q.ruined=true;q.ruin_intro=true;q.ruin_checks=["store","home","place"];q.regret_seen=true;q.heard=q.INVESTIGATORS.keys();q.admitted=true;q.captive_heard=true
 game.waterfront_quest.phase="completed";game.progress.add_favor("namgung",10)
 var n=game.namgung_campaign;n.phase="preparing";n._travel("namgung_estate",[1050,1055]);n.refresh_world();verify()
 await shot("namgung-seojin-overworld")
 check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"estate save restores")
 verify();n=game.namgung_campaign;n.phase="camp";n._travel("qingya_camp",[970,790]);n.refresh_world();verify()
 await shot("namgung-seojin-camp")
 check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"camp save restores");verify()
 game.reset();await create_timer(.8).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame
 print("DEDICATED_NPC: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
