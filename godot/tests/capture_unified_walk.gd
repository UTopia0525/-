extends SceneTree
const UI=preload("res://scripts/ui.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1080,880)
 var background=ColorRect.new();background.size=root.size;background.color=Color("142422");root.add_child(background)
 UI.label(root,"사방 보행 · 같은 이동 거리, 같은 보폭 주기",Rect2(24,15,1000,40),26,UI.GOLD)
 for column in range(4):UI.label(root,"주기 %d / 4" % [column+1],Rect2(150+column*220,65,150,25),17,UI.TEXT)
 for row in range(4):
  var direction=["down","up","left","right"][row]
  UI.label(root,["아래","위","왼쪽","오른쪽"][row],Rect2(24,153+row*190,110,30),21,UI.TEXT)
  for column in range(4):
   var player=load("res://scenes/player.tscn").instantiate();root.add_child(player);player.set_physics_process(false);player.set_display_height(140);player.position=Vector2(210+220*column,240+row*190);player.facing=direction;player.gait_phase=column*TAU/4;player._play("walk_"+direction)
   var baseline=ColorRect.new();baseline.position=player.position+Vector2(-65,3);baseline.size=Vector2(130,1);baseline.color=Color("ad9a6b");root.add_child(baseline)
 await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/walk-unified-directions.png")==OK)
 quit()
