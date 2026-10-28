extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func q(id: String):return game.suzhou_quests.get_quest("suzhou_"+id)
func settle() -> void:
 game.adventure_ui.dismiss()
 while not game.dialogue_lines.is_empty():game.advance_dialogue()
func shot(name: String) -> void:
 game.adventure_ui.toast.hide();game.adventure_ui.pending_toasts.clear()
 await create_timer(.4).timeout
 for i in range(3):await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("suzhou");game.suzhou_quests.refresh_world()
 game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20};game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""]
 for quest in game.suzhou_quests.quests:quest.accept();settle()
 await process_frame;await process_frame
 game.adventure_ui.open_journal();game.adventure_ui.select_quest("suzhou_quay");await shot("suzhou-quests-journal");game.adventure_ui.close_menu()
 game.suzhou_quests.handle_interaction("sz_smith");await shot("suzhou-quests-topics");game.adventure_ui.close_menu()
 var w=game.exploration;var npc=w.decorations.get_node("sz_apprentice");w.player.position=w.path_to(npc.position,true)[-1];w.camera.snap_to_player()
 q("silk").phase="apprentice";q("silk").track();game.exploration_hud.refresh();await process_frame;q("silk").present();game.dialogue_index=2;game._show_line();await shot("suzhou-apprentice-dialogue");settle()
 q("silk").present();await shot("suzhou-silk-choice");game.adventure_ui.secondary_action();settle()
 q("quay").phase="confront";game.suzhou_quests.refresh_world();q("quay").present();settle();await create_timer(.8).timeout;await shot("suzhou-quay-battle")
 game.battle.cancel();q("quay").after_victory();settle()
 q("balance")._fight_dialogue();settle();await create_timer(.8).timeout;await shot("suzhou-training-battle")
 game.battle.cancel();q("balance").after_defeat();settle()
 game.reset();await create_timer(.8).timeout
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("SUZHOU_QUEST_CAPTURE: PASS");quit()
