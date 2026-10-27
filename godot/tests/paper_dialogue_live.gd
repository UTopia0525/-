extends SceneTree
var game
var failed:=false
var count:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("PAPER_DIALOGUE_LIVE: "+msg)
func inspect(lines: Array) -> void:
 count+=1;game.say(lines)
 var cast=game.dialogue_cast
 if cast.portraits.has("hero"):
  var hero=cast.portraits.hero;check(hero.position.x<100,"hero stays left")
  for id in cast.portraits:
   if id!="hero":check(cast.portraits[id].position.x>=430,"opponents grouped right")
 var unique={};var positions={}
 for id in cast.portraits:
  unique[cast.portrait_choices[id]]=true;positions[id]=cast.portraits[id].position
  check(Rect2(Vector2.ZERO,cast.size).encloses(Rect2(cast.portraits[id].position,cast.portraits[id].size)),"inside cast bounds")
 check(unique.size()==cast.portraits.size(),"unique illustrations")
 for line in lines:
  cast.set_speaker(line[0])
  for id in positions:check(cast.portraits[id].position==positions[id],"no movement on speaker change")
func visit(value) -> void:
 if value is Dictionary:
  for child in value.values():visit(child)
 elif value is Array and not value.is_empty():
  if value[0] is Array and value[0].size()>=2 and value[0][0] is String and value[0][1] is String and game.PORTRAITS.ACTORS.has(value[0][0]):inspect(value)
  else:
   for child in value:visit(child)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang()
 for name in ["prologue_dialogues","chapter_one_intro","trade_intro","normal_quests","changsha_bandit_story","alliance_story","nanjing_book_quest","nanjing_levy_quest","nanjing_waterfront_quest","nanjing_relief_quest","qingya_quest","wuchang_duel_quest","wuchang_inn_quest","wuchang_impostor_quest","wuchang_herbalist_quest","wuchang_artisan_quest","wuchang_plaque_quest","wuchang_grain_quest","wuchang_wages_quest"]:
  visit(JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name+".json")))
 game.say([["hero","말을 듣겠소."],["nj_constable","긴 대화가 이어질 때에도 인물들은 처음에 정한 자리에 서 있습니다. 화자가 바뀌었다는 이유만으로 상대가 화면 가운데로 이동하거나 초상화의 크기가 달라져서는 안 됩니다. 같은 대화 안에서 짧은 대사와 긴 대사가 번갈아 나와도 화면은 안정적으로 유지되어야 합니다."]])
 var stable_rects={}
 for id in game.dialogue_cast.portraits:stable_rects[id]=game.dialogue_cast.portraits[id].get_global_rect()
 game.advance_dialogue()
 for id in stable_rects:check(game.dialogue_cast.portraits[id].get_global_rect()==stable_rects[id],"long and short lines preserve cast geometry")
 game.say([["hero","상대의 말을 듣는다."],["nj_constable","확인하겠소."],["nj_vendor","고맙습니다."]]);var original={}
 for id in game.dialogue_cast.portraits:original[id]=game.dialogue_cast.portraits[id].position
 game.advance_dialogue();check(game.dialogue_cast.portraits.nj_constable.self_modulate==Color.WHITE and game.dialogue_cast.portraits.hero.self_modulate==game.PORTRAITS.DIM,"speaker tint")
 check(not game.save_system.write_slot(9),"new manual save blocked in dialogue")
 check(preload("res://tests/legacy_save_fixture.gd").write(game,8) and game.save_system.load_slot(8),"legacy dialogue restored in new UI")
 check(game.dialogue_index==1 and game.dialogue_panel.get_script().resource_path.ends_with("paper_dialogue_panel.gd"),"new paper surface after restore")
 game.dialogue_history.open_history();check(game.dialogue_history.visible and paused and game.dialogue_history.shown_lines==2,"history pause and read boundary");game.dialogue_history.close_history()
 game.options.update("size",2)
 game.say([["hero","한 사람의 말을 듣는 동안 다른 이들도 그 자리에 함께 서 있었다. 장사에서 무창으로, 다시 남경까지 걸어오는 동안 만난 사람들은 서로 다른 사정을 지니고 있었다. 대화가 길어져도 그들의 말과 이름을 놓치지 않고 읽을 수 있어야 한다."]],Callable(),["hero","nj_vendor","nj_crowd_clerk_runner","nj_constable"])
 await process_frame;await process_frame
 check(game.dialogue_text.get_line_count()*game.dialogue_text.get_line_height()<=game.dialogue_text.size.y,"large text fits")
 check(game.dialogue_panel.position.y+game.dialogue_panel.size.y<=700,"panel inside viewport")
 game.options.update("size",1);game.reset();check(not game.dialogue_panel.visible and not game.dialogue_backdrop.visible and not paused,"reset cleanup")
 game.queue_free();await process_frame;print("PAPER_DIALOGUE_LIVE: "+("FAIL" if failed else "PASS")+" / "+str(count)+" existing scenes");quit(1 if failed else 0)
