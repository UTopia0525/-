extends SceneTree
func _initialize() -> void:run.call_deferred()
func label_at(text: String,at: Vector2) -> void:
 var label=Label.new();label.text=text;label.position=at;label.add_theme_font_size_override("font_size",20);root.add_child(label)
func run() -> void:
 root.size=Vector2i(1360,1240);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 var background=ColorRect.new();background.color=Color("202c32");background.size=Vector2(1360,1240);root.add_child(background)
 var kinds=["sword","saber","spear","none"];var directions=["down","left","right","up"]
 for column in range(4):
  var kind: String=kinds[column];var x=170+column*340
  label_at(kind.to_upper(),Vector2(x-50,20))
  for row in range(4):
   var p=load("res://scenes/player.tscn").instantiate();root.add_child(p);p.set_physics_process(false)
   p.set_display_height(140);p.set_equipped_weapon("review_"+kind,kind);p.facing=directions[row];p.stop();p.position=Vector2(x,250+row*200)
  var actor=load("res://scripts/battle_actor.gd").new();root.add_child(actor);actor.configure(false,kind,Vector2(x,1195));actor.stop();actor.scale=Vector2.ONE*.72
 for row in range(4):label_at(directions[row],Vector2(10,80+row*200))
 label_at("BATTLE / READY",Vector2(10,925))
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/equipment-visual-overview.png")==OK)
 quit()
