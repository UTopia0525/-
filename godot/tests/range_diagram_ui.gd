extends SceneTree
var game
var failed=false
func check(value: bool,message: String) -> void:
 if not value:failed=true;push_error("RANGE_DIAGRAM: "+message)
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 await create_timer(.15).timeout;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK,"capture "+name)
func run() -> void:
 root.size=Vector2i(1280,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
 var arts=game.progress.arts
 check(not arts.get_skill("basic_attack").damage_coefficients.has("agility"),"displayed basic formula matches common combat rule")
 var preview=preload("res://scripts/martial_range_preview.gd").new();preview.size=Vector2(250,164);root.add_child(preview)
 var tactics=preload("res://scripts/martial_tactics.gd").new()
 for id in ["basic_attack","basic_defense"]+arts.definitions.keys():
  var model=tactics.preview(id);preview.configure(model);await process_frame
  check(preview.art_id==id and model.known,"every current art has automatic range artwork: "+id)
  check(preview.skill==arts.get_skill(id),"effect metadata follows the current catalogue")
 preview.queue_free()
 for id in arts.definitions:
  if id not in game.progress.learned:game.progress.learned.append(id)
 game.player_menu.open_menu("martial");game.player_menu.select_item("banseok")
 check(game.player_menu.range_preview.art_id=="banseok","K selection updates the common artwork")
 await shot("k-range-preview")
 game.player_menu.select_item("josik_suwon");await shot("k-range-support")
 game.player_menu.hide();game.start_battle();await create_timer(.15).timeout
 var b=game.battle;b.select_skill("samjae")
 check(b.range_diagram.visible and b.range_diagram.art_id=="samjae","battle selection updates range artwork")
 var before=b.grid.units.duplicate(true);b.refresh_grid();b.refresh_grid()
 check(before==b.grid.units,"drawing never changes combat resources, guards or positions")
 await shot("battle-range-preview")
 b.utility(0);check(not b.range_diagram.visible,"movement restores walking controls")
 b.cancel()
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 await create_timer(.2).timeout;game.queue_free();await process_frame
 print("RANGE_DIAGRAM: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
