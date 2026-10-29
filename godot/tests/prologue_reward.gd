extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("PROLOGUE_REWARD: "+message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"])
 var p=game.prologue;var saves=game.save_system
 check(p.TREASURE_REWARD==500,"current delivery reward")
 for file in ["namgung_campaign","murong_quest","cuiyue_incident"]:
  var e=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+file+".json")).encounter
  var total=0
  for value in e.stats.values():total+=int(value)
  check(total=={"namgung_campaign":310,"murong_quest":250,"cuiyue_incident":300}[file],"latest enemy total retained: "+file)
  check(e.max_hp==preload("res://scripts/rules.gd").max_health(e.stats),"shared health retained: "+file)
 game.start_story()
 game.say([["hero","삼천 문입니다. 인도가 끝난 뒤 지급합니다."]])
 check(preload("res://tests/legacy_save_fixture.gd").write(game,1),"historical unpaid dialogue fixture")
 check(saves.load_slot(1) and game.dialogue_text.text.contains("오백 문") and not game.dialogue_text.text.contains("삼천 문"),"unpaid legacy dialogue adopts current reward")
 check(game.money==0 and not p.payment_received,"loading unpaid dialogue does not pay")
 game.reset();game.start_city();p.branch="treasure";p.payment_received=true;p.completed=true;game.money=3000
 check(saves.write_slot(2) and saves.load_slot(2) and game.money==3000,"already-paid manual save retains balance")
 p._after_delivery();check(game.money==3000,"loading paid save cannot pay again")
 game.reset()
 for amount in [500,3000]:
  var f=FileAccess.open(p.SAVE_PATH,FileAccess.WRITE);f.store_string(JSON.stringify({"version":1,"chapter_00_complete":true,"branch":"treasure","payment_received":true,"money":amount}));f.close()
  check(not p.read_checkpoint().is_empty(),"new/legacy checkpoint accepted: "+str(amount))
  p.resume();check(game.money==amount and p.payment_received,"checkpoint preserves paid balance: "+str(amount));game.reset()
 var f=FileAccess.open(p.SAVE_PATH,FileAccess.WRITE);f.store_string(JSON.stringify({"version":1,"chapter_00_complete":true,"branch":"treasure","payment_received":true,"money":999}));f.close()
 check(p.read_checkpoint().is_empty(),"unrecognized checkpoint amount rejected")
 game.queue_free();await process_frame
 print("PROLOGUE_REWARD: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
