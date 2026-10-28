extends SceneTree
var failed=false
var game
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("STAT_CAP: "+message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.start_city()
 var p=game.progress
 for key in p.stats:p.stats[key]=150
 check(p.valid(p.snapshot()),"all five stats above100 accepted")
 check(p.arts.can_learn("hoeryu",p.stats),"high stats do not prevent learning")
 check(game.save_system.write_slot(8),"save high stats during exploration")
 p.reset()
 check(game.save_system.load_slot(8) and int(p.stats.insight)==150 and int(p.stats.inner)==150,"high stats roundtrip")
 for value in [-1,201]:
  var invalid=p.snapshot();invalid.stats.strength=value
  check(not p.valid(invalid),"out of range rejected: %d" % value)
 var old=p.snapshot()
 for key in old.stats:old.stats[key]=10
 check(p.valid(old),"old stat range remains compatible")
 for key in p.stats:p.stats[key]=199
 p.inventory.bear_strength_pill=2
 check(p.consume("bear_strength_pill"),"elixir crosses old cap")
 for key in p.stats:
  check(int(p.stats[key])==(199 if key=="insight" else 200),"elixir clamps each stat and excludes insight")
 check(not p.consume("bear_strength_pill") and int(p.inventory.bear_strength_pill)==1,"no item consumed at physical cap")
 p.stats.insight=199;game.bandit_story._settle()
 check(int(p.stats.insight)==200,"quest insight capped at200")
 var qi=preload("res://scripts/inner_qi.gd").new();qi.start(200)
 check(qi.amount==200 and qi.inner_power==200,"battle uses full inner200")
 qi.recover_turn();qi.recover_turn();check(qi.amount==500,"qi pool remains500")
 qi.restore(200,150);check(qi.inner_power==200 and qi.amount==150,"legacy resource restore accepts inner200")
 check(p.RULES.realm(500)=="자연경" and p.RULES.realm(501)=="자연경" and p.RULES.realm(1000)=="자연경","realm does not regress above old maximum")
 p.reset();game.chapter_one.intro_complete=true;game.chapter_number=1
 p.learned.append("hoeryu")
 for key in p.stats:p.stats[key]=20
 check(game.bandit_story.eligible(),"campaign unlocks at total100")
 p.stats.strength=19;check(not game.bandit_story.eligible(),"campaign blocked at total99")
 p.stats.strength=20;p.learned.erase("hoeryu");check(not game.bandit_story.eligible(),"new art still required")
 game.queue_free();await process_frame
 if not failed:print("STAT_CAP: PASS")
 quit(1 if failed else 0)
