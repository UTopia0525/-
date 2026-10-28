extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error("EQUIPMENT_VISUALS: "+message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city();var p=game.exploration.player;var b=game.battle
 var slot=1
 for kind in ["sword","saber","spear","none"]:
  var id: String=b.weapons.DEFAULT_BY_TYPE[kind]
  if id!="none" and id not in game.progress.owned_weapons:game.progress.owned_weapons.append(id)
  game.player_menu.open_menu("inventory");game.player_menu.select_category("weapon");game.player_menu.select_item(id)
  if not game.player_menu.action.disabled:game.player_menu.apply_selection()
  game.player_menu.close_menu()
  check(b.equipped_weapon_id==id and p.equipped_weapon_id==id and p.equipped_weapon_type==kind,"I equip updates canonical and field: "+kind)
  check(p.body_key==("sword" if kind=="sword" else "clean"),"body never retains wrong scabbard: "+kind)
  check(p.carried_equipment.visible==(kind in ["sword","saber","spear"]),"correct rigid equipment layer: "+kind)
  for facing in ["down","up","left","right"]:
   p.facing=facing;p.stop();var scale=p.sprite.scale
   p.gait_phase=PI/2;p._play("walk_"+facing)
   check(p.sprite.scale==scale,"body scale remains fixed while walking: "+kind+"/"+facing)
   p.stop()
  check(p.get_node("Feet").shape.radius==16 and p.display_height==140 and p.speed==360,"visual equipment never changes feet or speed")
  check(game.save_system.write_slot(slot),"save equipment: "+kind)
  b.equip_weapon_item("plain_iron_sword")
  check(game.save_system.load_slot(slot),"reload equipment: "+kind)
  check(p.equipped_weapon_type==kind and b.player_actor.weapon_type==kind,"load synchronizes exploration and battle: "+kind)
  b.player_actor.set_weapon("sword");game.start_battle()
  check(b.player_actor.weapon_type==kind and b.player_actor.frame_index==b.player_actor.COLUMNS[kind],"battle entry repairs stale actor: "+kind)
  for pose in ["ready","windup","strike","hit"]:
   b.player_actor.set_pose(pose)
   check(b.player_actor.frame_index==b.player_actor.ROWS[pose]*4+b.player_actor.COLUMNS[kind],"matching combat weapon pose: "+kind+"/"+pose)
  game.enter_city();slot+=1
 game.reset();check(p.equipped_weapon_type=="sword" and p.body_key=="sword","new journey restores starter appearance")
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("EQUIPMENT_VISUALS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
