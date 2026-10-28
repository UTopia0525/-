extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var layer=Control.new();root.add_child(layer)
 var background=ColorRect.new();background.size=Vector2(1280,720);background.color=Color("24372e");layer.add_child(background)
 var ui=preload("res://scripts/ui.gd")
 ui.label(layer,"도원 · 전투 자세",Rect2(30,12,900,40),25)
 var weapons=["sword","saber","spear","none"];var poses=["ready","windup","strike","hit"]
 for col in range(4):
  ui.label(layer,["검","도","창","맨손"][col],Rect2(150+col*280,55,200,30),20)
  for row in range(4):
   if col==0:ui.label(layer,["준비","출수 준비","타격","피격"][row],Rect2(10,112+row*145,110,30),16)
   var actor=preload("res://scripts/battle_actor.gd").new();layer.add_child(actor);actor.configure(false,weapons[col],Vector2(235+col*280,210+row*145));actor.scale=Vector2.ONE*.28;actor.stop();actor.set_pose(poses[row])
 await create_timer(.2).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/jade-hero-poses.png")==OK)
 layer.queue_free();await process_frame;print("JADE_HERO_CAPTURE: PASS");quit()
