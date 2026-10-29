extends SceneTree
var b
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,text: String) -> void:
 if not ok:failed=true;push_error("BATTLE_VISUALS: "+text)
func fixtures() -> Array:
 return [JSON.parse_string(FileAccess.get_file_as_string("res://data/murong_quest.json")).encounter,JSON.parse_string(FileAccess.get_file_as_string("res://data/cuiyue_incident.json")).encounter,JSON.parse_string(FileAccess.get_file_as_string("res://data/namgung_campaign.json")).encounter]
func run() -> void:
 b=load("res://scenes/battle.tscn").instantiate();root.add_child(b);await process_frame
 var catalog=preload("res://scripts/battle_visuals.gd").DATA.characters
 check(catalog.size()==4,"three opponents and Seojin support registered")
 for encounter in fixtures():
  b.set_encounter(encounter);b.begin();b.generation+=1
  var a=b.enemy_actor;var id=str(encounter.portrait_actor);var spec=catalog[id]
  check(a.visual_id==id and a.sprite.texture.atlas.resource_path==spec.texture,"encounter selects actual dedicated sheet "+id)
  check(encounter.stats.keys().all(func(key):return float(b.enemy_stats[key])==float(encounter.stats[key])) and b.enemy_skills==encounter.skills,"art does not alter combat rules "+id)
  check(a.sprite.material==null,"enemy keeps original clothing palette")
  var scale=a.sprite.scale;var texture_paths={}
  for pose in ["ready","windup","strike","hit"]:
   a.set_pose(pose)
   check(a.sprite.scale==scale,"fixed body scale across poses "+id+pose)
   var frame=spec.frames[str(a.ROWS[pose])];var r=Rect2(frame.region[0],frame.region[1],frame.region[2],frame.region[3])
   check(a.sprite.texture.region==r and r.has_area(),"distinct uncut pose "+id+pose)
   check(a.sprite.flip_h==bool(frame.facing_right),"pose faces opponent after source normalization")
   check(absf(a.sprite.position.y+r.size.y*scale.y)<.001,"feet stay on common baseline")
   texture_paths[frame.region]=true
  check(texture_paths.size()==4,"all four poses unique")
  a.hurt();await create_timer(.07).timeout
  check(a.pose=="hit" and a.sprite.modulate.g<1,"actual hit pose and damage flash")
  a.stop();a.set_pose("strike")
  b._basic_fx("attack",a.home+Vector2(0,-35),Vector2.LEFT,a.visual_effect)
  var fx=b.get_children().filter(func(n):return n.get_script()==preload("res://scripts/battle_basic_fx.gd"))
  check(not fx.is_empty() and fx[-1].profile.style==spec.effect.style,"character-specific attack effect")
  b.grid.units[0].position=Vector2i(5,2);b.grid.units[1].position=Vector2i(1,2);b._place_actors();b.refresh_grid()
  check(b.player_actor.scale.x<0 and b.enemy_actor.scale.x<0,"dedicated opponent mirrors after crossing")
  a.set_pose("ready")
  a.walker=preload("res://scripts/battle_step.gd").new();a.add_child(a.walker);a.walker.configure(a,.2)
  check(not a.sprite.visible and a.walker.pieces.size()==3,"dedicated sprite participates in stepping")
  check(signf(a.walker.scale.x)==(-1.0 if a.sprite.flip_h else 1.0),"walking preserves normalized source orientation")
  a.reset_motion();await process_frame;check(a.sprite.visible,"walking restores dedicated body")
  # Play the real grid presentation rather than checking only manually chosen frames.
  b.grid.units[0].position=Vector2i(2,2);b.grid.units[1].position=Vector2i(3,2);b._place_actors();b.refresh_grid()
  b.grid.units[1].gauge=200;b.grid.units[1].qi=500
  var event=b.grid.perform(1,"basic_attack",Vector2i.LEFT)
  check(event.ok and event.damage>0,"real attack is valid")
  b.animation_time=.3;b._present.call_deferred(event,b.generation)
  await create_timer(.04).timeout
  check(a.pose=="windup" and b.player_actor.pose=="hit","real presentation enters named windup and victim hit")
  await create_timer(.13).timeout;check(a.pose=="strike","real presentation enters named strike")
  await create_timer(.5).timeout
  check(a.pose=="ready","presentation returns to dedicated ready pose")
  if encounter.id=="qingya_maunpyo":
   check(b.support_actor.visual_id=="namgung_seojin" and b.support_actor.visible,"support uses Seojin, not recolored protagonist")
   check(b.support_actor.sprite.material==null and b.support_actor.sprite.flip_h,"support keeps blue-white clothing and faces right")
  b.cancel()
 b.set_encounter(JSON.parse_string(FileAccess.get_file_as_string("res://data/blackguild_story.json")).encounter);b.begin();b.generation+=1
 check(b.enemy_actor.visual_id=="" and b.enemy_actor.textures.size()==16,"ordinary enemy returns to common weapon poses")
 check(b.player_actor.visual_id=="" and b.player_actor.sprite.material!=null,"protagonist art remains unchanged")
 b.cancel();b.queue_free();await process_frame
 print("BATTLE_VISUALS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
