extends SceneTree
var game
var failed=false
const Rules=preload("res://scripts/rules.gd")
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("HEALTH_GROWTH: "+message)
func run() -> void:
 check(Rules.max_health()==300,"starting health remains300")
 check(Rules.max_health({"strength":0,"constitution":0})==220,"minimum stat boundary")
 check(Rules.max_health({"strength":200,"constitution":200})==1820,"maximum stat boundary")
 check(Rules.max_health({"strength":11,"constitution":10})==303,"strength increment3")
 check(Rules.max_health({"strength":10,"constitution":11})==305,"constitution increment5")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 for e in game.encounters():check(e.max_hp==Rules.max_health(e.stats),"encounter cache matches shared formula: "+e.id)
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
 game.progress.stats={"strength":50,"agility":20,"constitution":50,"inner":20,"insight":30}
 var saves=game.save_system
 check(saves.write_slot(1) and saves.load_slot(1),"growth exploration save restores")
 check(game.battle.player_max_hp==620,"loaded growth health")
 var e=game.herbalist_quest.data.encounter;game.herbalist_quest.phase="rescue";game.herbalist_quest.battle_active=true
 game.start_battle(e);var b=game.battle
 check(b.player_hp==620 and b.grid.units[0].max_hp==620,"real battle starts full at derived cap")
 check(b.enemy_max_hp==328 and b.grid.units[1].max_hp==328,"real enemy uses same formula")
 check(not saves.write_slot(2),"battle saves still blocked")
 var data=saves.capture();data.battle.player_hp=450;data.battle.enemy_hp=160
 check(saves.validate(data),"new health above300 is valid")
 var invalid=data.duplicate(true);invalid.battle.player_hp=621;check(not saves.validate(invalid),"reject health above derived cap")
 invalid=data.duplicate(true);invalid.battle.enemy_hp=329;check(not saves.validate(invalid),"reject enemy above derived cap")
 var f=FileAccess.open(saves.path(3),FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 check(saves.load_slot(3) and b.player_hp==450 and b.player_max_hp==620 and b.enemy_hp==160,"historical combat read path restores growth HP")
 var old=data.duplicate(true);old.erase("health_revision");old.battle.player_hp=150;old.battle.enemy_hp=95
 f=FileAccess.open(saves.path(4),FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
 check(saves.load_slot(4) and b.player_hp==310 and b.enemy_hp==164,"old combat HP percentages migrate once")
 var stable=saves.capture();check(stable.health_revision==1 and stable.battle.player_hp==310,"new revision prevents repeated scaling")
 game.reset();game.start_wuchang();game.progress.stats.strength=11
 game.start_battle();check(b.player_hp==303 and b.enemy_max_hp==242,"next fight reflects stat increase and tutorial HP")
 game.reset();check(b.player_hp==300 and b.player_max_hp==300,"new game resets health")
 game.queue_free();await process_frame
 print("HEALTH_GROWTH: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
