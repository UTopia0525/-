extends SceneTree
var game
var failed=false
const PILL="namgung_cheongcheon_pill"
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("NAMGUNG: "+msg)
func _initialize() -> void:run.call_deferred()
func settle() -> void:
 for i in range(100):
  if game.dialogue_lines.is_empty():break
  game.dialogue_index=game.dialogue_lines.size()-1;game._show_line();game.advance_dialogue()
  await process_frame
func prerequisites() -> void:
 var q=game.qingya_quest;q.phase="completed";q.branch="assault";q.reward_stat="strength";q.departed=true;q.ruined=true;q.ruin_intro=true;q.ruin_checks=["store","home","place"];q.regret_seen=true;q.heard=q.INVESTIGATORS.keys();q.admitted=true;q.captive_heard=true
 game.waterfront_quest.phase="completed";game.progress.add_favor("namgung",10)
func sim(skill: String,help: bool) -> Dictionary:
 var e=game.namgung_campaign.data.encounter
 var g=preload("res://scripts/grid_combat.gd").new();var stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
 var config={"support":e.support} if help else {}
 var weapon=game.progress.weapons.DEFAULT_BY_TYPE[game.progress.arts.get_skill(skill).required_weapon_type]
 g.setup(config,{"stats":stats.duplicate(),"weapon":weapon,"hp":300,"max_hp":300,"skills":[skill]}, {"stats":e.stats.duplicate(),"weapon":e.weapon,"hp":e.max_hp,"max_hp":e.max_hp,"skills":e.skills.duplicate(),"ai":e.ai})
 var assisted=0
 for i in range(500):
  var actor=g.next_actor()
  if actor<0:break
  var plan=preload("res://scripts/grid_tactical_ai.gd").choose(g,actor)
  var event=g.perform(actor,plan.id,plan.facing,plan.get("destination",Vector2i(-1,-1)))
  check(event.ok,"simulation action legal")
  assisted+=int(event.get("support_damage",0))
  if g.winner>=0:break
 return {"skill":skill,"support":help,"win":g.winner==0,"hp":g.units[0].hp,"support_damage":assisted}
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","battle","dialogue","trade"]);game.start_wuchang()
 var q=game.namgung_campaign
 check(not q.eligible(),"initially locked")
 prerequisites();check(q.eligible(),"three prerequisites unlock")
 game.progress.faction_favor.namgung=9;check(not q.eligible(),"favor gate");game.progress.faction_favor.namgung=10
 game.waterfront_quest.phase="available";check(not q.eligible(),"waterfront gate");game.waterfront_quest.phase="completed"
 game.qingya_quest.regret_seen=false;check(not q.eligible(),"empty village gate");game.qingya_quest.regret_seen=true
 var old=game.progress.snapshot();old.inventory.erase(PILL);old.consumed.erase(PILL);check(game.progress.valid(old),"old four-elixir progress still valid")
 game.progress.restore(old);check(game.progress.inventory[PILL]==0,"old save gains empty new item slot")
 var icons=preload("res://scripts/catalog_icons.gd")
 for id in game.progress.arts.definitions:check(icons.texture(id)!=null,"art icon "+id)
 for id in game.progress.elixirs:check(icons.texture(id)!=null,"elixir icon "+id)
 var results=[]
 for id in ["hoeryu","paak","gwanak","banseok","jungun"]:
  var solo=sim(id,false);var aided=sim(id,true);results.append(solo);results.append(aided)
  check(aided.win and aided.support_damage>0,"middle art clears with visible support: "+id)
 print("NAMGUNG_BALANCE "+JSON.stringify(results))
 q._travel("namgung_estate",[768,1050]);check(game.exploration.area_name=="namgung_estate","estate reachable")
 check(game.exploration.regional_map.can_stand(game.exploration.player.position),"estate spawn clear")
 check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"estate save/load")
 q=game.namgung_campaign
 for npc in game.exploration.ambient_nodes:
  if npc.get_meta("npc_id")==q.GIVER:game.exploration.player.position=game.exploration.safe_player_position(npc.position+Vector2(0,64));break
 game.interact();await settle();check(game.adventure_ui.window.visible and game.adventure_ui.mode=="choice","F interaction offers quest through dialogue")
 game.adventure_ui.primary_action();await settle();check(q.phase=="preparing","accepted after dialogue")
 check(game.save_system.write_slot(2) and game.save_system.load_slot(2),"preparation save/load")
 q=game.namgung_campaign;q._march();await settle();check(q.phase=="camp" and game.exploration.area_name=="qingya_camp","party marches into camp")
 check(game.exploration.ambient_nodes.filter(func(n):return str(n.get_meta("npc_id")).begins_with("ng_guard_")).size()==4,"four allied warriors deployed")
 check(game.exploration.regional_map.path_to(game.exploration.player.position,game.exploration.city_point([780,500])).size()>0,"path to boss open")
 check(game.save_system.write_slot(3) and game.save_system.load_slot(3),"camp stage save/load")
 q=game.namgung_campaign;game.progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20};game.progress.learned.append("hoeryu");game.progress.loadout=["basic_attack","basic_defense","hoeryu",""];q._confront();await settle();check(game.state=="battle" and q.in_battle(),"boss dialogue enters actual battle")
 check(not game.save_system.write_slot(4),"battle saving stays blocked")
 game.battle.animation_time=.01
 var limit=Time.get_ticks_msec()+15000
 while game.state=="battle" and Time.get_ticks_msec()<limit:
  if game.battle.awaiting_player and not game.battle.busy:
   var b=game.battle;var plan=preload("res://scripts/grid_tactical_ai.gd").choose(b.grid,0);b.facing=plan.facing
   b.commit(plan.id,plan.get("destination",Vector2i(-1,-1)))
  await create_timer(.02).timeout
 await settle();check(q.phase=="report" and game.state=="explore","actual supported battle victory clears camp")
 check(game.top_hud.visible and game.exploration.camera.enabled,"exploration HUD and camera restored after battle")
 q._travel("namgung_estate",[768,1050]);var money=game.money
 q.handle_interaction(q.GIVER);await settle();check(q.phase=="return" and game.money==money+1000 and game.progress.inventory[PILL]==1 and game.progress.faction_favor.namgung==40,"reward exactly once with30favor at dialogue end")
 check(game.exploration.regional_map.data.admission_open,"paying immediately opens existing estate without village revisit")
 q._paid();check(game.money==money+1000 and game.progress.inventory[PILL]==1 and game.progress.faction_favor.namgung==40,"duplicate money, pill and favor blocked")
 check(game.save_system.write_slot(5) and game.save_system.load_slot(5),"paid stage save/load")
 var legacy=game.save_system.read_slot(5);legacy.namgung_campaign.erase("favor_reward_granted");legacy.progress.faction_favor.namgung=10;legacy.world.position=[3000,2580];legacy.world.layout_version=1
 var old_file=FileAccess.open(game.save_system.path(8),FileAccess.WRITE);old_file.store_string(JSON.stringify(legacy));old_file.close()
 check(game.save_system.load_slot(8) and game.progress.faction_favor.namgung==40 and game.namgung_campaign.estate_open(),"old paid save gains missing favor and entry")
 check(game.save_system.load_slot(8) and game.progress.faction_favor.namgung==40,"reloading old file does not stack favor")
 q=game.namgung_campaign;q._travel("qingya_hamlet",[900,650])
 check(q.restored() and game.exploration.ambient_nodes.any(func(n):return n.get_meta("npc_id")=="qy_ren_shoutian"),"residents return")
 check(game.exploration.objectives.all(func(o):return not str(o.id).begins_with("qingya_ruin:")),"old ruin investigations removed")
 q.handle_interaction("qy_ren_shoutian");await settle();check(q.phase=="completed","reunion completes story")
 var stats=game.progress.stats.duplicate();check(game.progress.consume(PILL),"secret elixir consumed")
 for key in ["strength","agility","constitution","inner"]:check(game.progress.stats[key]==mini(100,stats[key]+3),"elixir grows "+key)
 check(game.progress.stats.insight==stats.insight and not game.progress.consume(PILL),"no insight or duplicate consumption")
 check(game.save_system.write_slot(6) and game.save_system.load_slot(6),"returned village and consumed elixir persist")
 var preserved=FileAccess.get_file_as_string(game.save_system.path(6));var balance=game.money
 q=game.namgung_campaign;q.phase="battle";game.start_battle(q.data.encounter);game.battle.animation_time=.01
 game.battle.grid.units[0].hp=1;game.battle.player_hp=1;game.battle.grid.units[0].position=Vector2i(2,2);game.battle.grid.units[1].position=Vector2i(3,2)
 limit=Time.get_ticks_msec()+5000
 while game.state=="battle" and Time.get_ticks_msec()<limit:await create_timer(.02).timeout
 check(game.state=="game_over" and game.money==balance,"actual chief defeat is lethal with no reward")
 check(FileAccess.get_file_as_string(game.save_system.path(6))==preserved and not game.save_system.write_slot(7),"death preserves save and blocks new saving")
 game.reset();await create_timer(.8).timeout
 for voice in game.music.players:voice.stop();voice.stream=null
 for voice in game.options.voices:voice.stop();voice.stream=null
 game.queue_free();await process_frame
 print("NAMGUNG: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
