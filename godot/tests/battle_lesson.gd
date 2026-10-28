extends SceneTree
var game
var failed=false
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("BATTLE_LESSON: "+message)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"])
 game.options.seen.erase("prologue_grid_lesson_v1")
 game.prologue.active=true;game.start_battle();var b=game.battle;var lesson=b.lesson;b.animation_time=.01
 await create_timer(.03).timeout
 check(lesson.active and lesson.step==0,"only active prologue starts lesson")
 var before=b.grid.units.duplicate(true);lesson.advance();check(before==b.grid.units,"reading tutorial never spends resources or grants actions")
 b.grid.units[0].gauge=100;b.awaiting_player=true;b.busy=false
 var p=b.grid.units[0].position;b.commit("move",p+Vector2i.RIGHT)
 check(lesson.step==2,"actual successful movement advances objective")
 var deadline=Time.get_ticks_msec()+3000
 while b.busy and Time.get_ticks_msec()<deadline:await create_timer(.02).timeout
 b.select_skill("samjae");check(lesson.step==3,"actual technique selection advances objective")
 var original=b.grid.units.duplicate(true)
 b.grid.units[1].position=Vector2i(6,0);b.grid.units[0].gauge=100;b.awaiting_player=true;b.busy=false;b.commit("samjae")
 check(lesson.step==3,"invalid out-of-range attack never completes exercise")
 b.grid.units[1].position=b.grid.units[0].position+Vector2i.RIGHT;b.facing=Vector2i.RIGHT;b.commit("samjae")
 check(lesson.step==4,"real technique execution advances lesson")
 for id in ["basic_defense","basic_attack"]:
  deadline=Time.get_ticks_msec()+3000
  while b.busy and Time.get_ticks_msec()<deadline:await create_timer(.02).timeout
  b.grid.units[0].gauge=100;b.awaiting_player=true;b.busy=false
  b.grid.units[1].position=b.grid.units[0].position+Vector2i.RIGHT;b.facing=Vector2i.RIGHT
  b.select_skill(id);b.commit(id)
  check(lesson.step==(5 if id=="basic_defense" else 6),"actual committed practice: "+id)
 lesson.finish();check(not lesson.active and lesson.KEY in game.options.seen,"completion remembers preference separately from story saves")
 b.cancel();game.start_battle();check(not lesson.active,"completed guide does not repeat")
 game.options.seen.erase(lesson.KEY);b.cancel();game.prologue.active=false;game.start_battle();check(not lesson.active,"standalone battle practice not forced into lesson")
 game.prologue.active=true;b.cancel();game.start_battle(game.herbalist_quest.data.encounter);check(not lesson.active,"other encounter never receives prologue guide")
 b.cancel();game.start_battle();check(lesson.active,"fresh prologue can teach")
 b.begin();check(not lesson.active,"legacy battle begin does not reopen tutorial")
 b.cancel();game.start_battle();game._on_victory(300);check(not lesson.active and lesson.KEY in game.options.seen,"early victory closes guide without blocking story")
 game.reset();await create_timer(.8).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame
 print("BATTLE_LESSON: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
