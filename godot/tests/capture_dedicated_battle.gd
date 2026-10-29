extends "res://tests/dedicated_battle_visuals.gd"
func shot(path: String) -> void:
 await create_timer(.12).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/"+path+".png")==OK)
func run() -> void:
 root.size=Vector2i(1280,720)
 b=load("res://scenes/battle.tscn").instantiate();root.add_child(b);await process_frame
 b.player_stats={"strength":60,"agility":60,"constitution":60,"inner":60,"insight":61};b.set_loadout(["basic_attack","basic_defense","samjae",""])
 for e in fixtures():
  b.set_encounter(e);b.begin();b.generation+=1;b.awaiting_player=true;b.busy=false;b.refresh_grid()
  await shot("dedicated-battle-"+e.id)
  b.enemy_actor.set_pose("strike");b.player_actor.set_pose("hit")
  b._basic_fx("attack",b.enemy_actor.home+Vector2(-25,-30),Vector2.LEFT,b.enemy_actor.visual_effect)
  b._basic_fx("hit",b.player_actor.home+Vector2(0,-30),Vector2.LEFT,b.enemy_actor.visual_effect)
  if e.id=="qingya_maunpyo":b.support_actor.set_pose("strike");b._basic_fx("attack",b.support_actor.home+Vector2(35,-25),Vector2.RIGHT,b.support_actor.visual_effect)
  await shot("dedicated-battle-"+e.id+"-strike");b.cancel()
 b.hide()
 root.size=Vector2i(1600,1030)
 var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1600,1030);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var ui=preload("res://scripts/ui.gd")
 var background=ColorRect.new();background.color=Color("182a2a");background.size=Vector2(1600,1030);view.add_child(background)
 ui.label(view,"전투 도트 · 기존 도원과 고유 인물 비교",Rect2(25,12,1540,38),28)
 var ids=["","mr_heir","cy_tak","qy_ma_yunpiao","namgung_seojin"]
 var names=["도원 · 기존 기준","모용유안","탁문호","마운표","남궁서진 · 지원"]
 for col in range(5):
  ui.label(view,names[col],Rect2(35+col*315,60,275,34),23)
  for row in range(4):
   var pose=["ready","windup","strike","hit"][row]
   var foot=Vector2(155+col*315,275+row*235)
   var line=ColorRect.new();line.color=Color("d7c69d55");line.position=foot+Vector2(-118,1);line.size=Vector2(236,1);view.add_child(line)
   var actor=preload("res://scripts/battle_actor.gd").new();view.add_child(actor)
   actor.configure(col in [1,2,3],"none" if col==3 else "saber" if col==2 else "sword",foot,ids[col]);actor.stop()
   actor.scale=Vector2.ONE*(.5 if col==0 else .48 if col==4 else .62);actor.set_pose(pose)
   ui.label(view,["대기","공격 준비","공격","피격"][row],Rect2(40+col*315,foot.y+8,250,27),16)
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(view.get_texture().get_image().save_png("res://screenshots/dedicated-battle-comparison.png")==OK)
 view.queue_free();b.queue_free();await process_frame;print("DEDICATED_BATTLE_CAPTURE: PASS");quit()
