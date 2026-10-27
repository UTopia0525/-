extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("K_TACTICS: "+message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
 var p=game.progress;var menu=game.player_menu;var initial=p.learned.duplicate()
 menu.open_menu("martial");check(p.learned==initial and menu.slots.size()==4,"K metadata grants nothing and retains four slots")
 for id in p.arts.definitions:
  if id not in p.learned:p.learned.append(id)
 var stats=p.stats.duplicate(true);var definitions=p.arts.definitions.duplicate(true);var before_qi=game.battle.qi.amount
 for id in ["basic_attack","basic_defense"]+p.learned:
  menu.select_item(id)
  check(menu.martial_metrics.size()==3 and menu.martial_metrics[0].text=="미정","unapproved action costs remain pending: "+id)
  var skill=p.arts.get_skill(id);var qi=p.weapons.qi_cost(int(skill.qi_cost),game.battle.equipped_weapon_id,skill)
  check(menu.martial_metrics[1].text==str(qi),"display actual equipment-adjusted qi: "+id)
  var model=menu.range_preview.model
  check(model.known,"all existing learned arts have range metadata: "+id)
  for point in model.attacks+model.moves:check(point.x>=0 and point.x<7 and point.y>=0 and point.y<5,"preview fits7x5: "+id)
 check(p.stats==stats and p.arts.definitions==definitions and game.battle.qi.amount==before_qi,"preview never modifies stats, legacy combat data or resource")
 menu.select_item("cheongpung");await process_frame;await process_frame
 var row=menu.rows.get_children().filter(func(n):return n.get_meta("item_id","")=="cheongpung")[0]
 check(menu.list_scroll.get_global_rect().encloses(row.get_global_rect()),"selected martial row is fully visible after layout")
 check(menu.range_preview.model.attacks.size()==1 and menu.range_preview.model.moves.size()==1,"charge distinguishes movement and attack")
 menu.select_item("hoepung");check(menu.range_preview.model.attacks.size()==8,"area attack shows surrounding eight cells")
 menu.select_item("josik_suwon");check(menu.range_preview.model.self_target and menu.range_preview.model.attacks.is_empty() and menu.detail.text.contains("200%"),"support targets self and preserves recovery explanation")
 menu.tactics.entries.samjae.action_cost=60;menu.select_item("samjae")
 check(menu.martial_metrics[0].text=="60" and game.battle.current_qi_cost("samjae")==10,"future action metadata displays separately from actual qi")
 menu.tactics.entries.samjae.action_cost=null
 var desired=["basic_attack","samjae","cheongpung","josik_suwon"]
 for i in range(4):menu.select_slot(i);menu.select_item(desired[i]);menu.apply_selection()
 check(p.loadout==desired and game.battle.loadout==desired,"four chosen arts reach production loadout")
 menu.close_menu();check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"save and restore edited loadout")
 check(p.loadout==desired,"slot identities persist without new schema")
 menu.open_menu("martial");menu.select_slot(3);menu.select_item("clear");menu.apply_selection();check(p.loadout[3]=="" and menu.slots.size()==4,"clearing one slot preserves four-slot layout")
 menu.close_menu()
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("K_TACTICS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
