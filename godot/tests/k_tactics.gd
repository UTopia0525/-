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
  check(menu.martial_metrics.size()==3 and menu.martial_metrics[0].text==menu.tactics.action_cost_text(id),"configured action costs are displayed: "+id)
  var skill=p.arts.get_skill(id);var qi=p.weapons.qi_cost(int(skill.qi_cost),game.battle.equipped_weapon_id,skill)
  check(menu.martial_metrics[1].text==str(qi),"display actual equipment-adjusted qi: "+id)
  check(menu.martial_metrics[2].text=="도식 참고","range uses the diagram, not a fixed distance label: "+id)
  for row in menu.rows.get_children():
   if row is Button:check(not row.text.contains("인접1칸"),"list does not impose adjacent-one-cell labels")
  var model=menu.range_preview.model
  check(model.known,"all existing learned arts have range metadata: "+id)
  for point in model.attacks+model.moves:check(point.x>=0 and point.x<7 and point.y>=0 and point.y<5,"preview fits7x5: "+id)
 check(p.stats==stats and p.arts.definitions==definitions and game.battle.qi.amount==before_qi,"preview never modifies stats, legacy combat data or resource")
 menu.select_item("cheongpung");await process_frame;await process_frame
 var row=menu.rows.get_children().filter(func(n):return n.get_meta("item_id","")=="cheongpung")[0]
 check(menu.list_scroll.get_global_rect().encloses(row.get_global_rect()),"selected martial row is fully visible after layout")
 check(menu.range_preview.model.attacks.size()==3 and menu.range_preview.model.moves.size()==1,"charge distinguishes movement and attack")
 menu.select_item("hoepung");check(menu.range_preview.model.attacks.size()==8,"area attack shows surrounding eight cells")
 menu.select_item("josik_suwon");check(menu.range_preview.model.self_target and menu.range_preview.model.attacks.is_empty() and menu.detail.text.contains("200%"),"support targets self and preserves recovery explanation")
 menu.tactics.entries.samjae.action_cost=60;menu.select_item("samjae")
 check(menu.martial_metrics[0].text=="60" and game.battle.current_qi_cost("samjae")==10,"future action metadata displays separately from actual qi")
 menu.tactics.entries.samjae.action_cost=40
 menu.tactics.entries.samjae.attack_offsets=[[1,-1],[3,0],[-1,1]];menu.select_item("samjae")
 check(menu.range_preview.model.attacks.size()==3 and Vector2i(6,2) in menu.range_preview.model.attacks,"custom attack positions do not rely on one-cell labels")
 menu.tactics.entries.samjae.attack_offsets=[[1,0]]
 var desired=["basic_attack","samjae","cheongpung","josik_suwon"]
 for i in range(4):menu.select_slot(i);menu.select_item(desired[i]);menu.apply_selection()
 check(p.loadout==desired and game.battle.loadout==desired,"four chosen arts reach production loadout")
 menu.close_menu();check(game.save_system.write_slot(1) and game.save_system.load_slot(1),"save and restore edited loadout")
 check(p.loadout==desired,"slot identities persist without new schema")
 var legacy=game.save_system.capture()
 legacy.progress.learned.append_array(["swaeam","jingak"])
 legacy.progress.loadout=["swaeam","cheongpung","jingak","cheolsan"]
 legacy.battle.selected_action="jingak";legacy.battle.selected=true
 var file=FileAccess.open(game.save_system.path(2),FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
 check(game.save_system.load_slot(2),"real legacy save with removed martial IDs can be loaded")
 check(p.loadout==["cheongpung","","cheolsan",""] and "swaeam" not in p.learned and "jingak" not in p.learned,"save loader migrates removed arts and duplicate loadout positions")
 menu.open_menu("martial");menu.select_filter("unarmed")
 check(menu.visible_ids().all(func(id):return p.arts.get_skill(id).weapon_style in ["fist","palm"]),"one unarmed tab groups fist and palm")
 menu.select_slot(3);menu.select_item("clear");menu.apply_selection();check(p.loadout[3]=="" and menu.slots.size()==4,"clearing one slot preserves four-slot layout")
 menu.close_menu()
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("K_TACTICS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
