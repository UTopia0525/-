extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1440,1400);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 var layer=ColorRect.new();layer.color=Color("24302f");layer.size=Vector2(root.size);root.add_child(layer)
 var dir=DirAccess.open("res://assets/portraits")
 var paths: Array[String]=[]
 for folder in dir.get_directories():
  if folder=="expressions":continue
  var sub=DirAccess.open("res://assets/portraits/"+folder)
  for file in sub.get_files():
   if file.ends_with(".png"):paths.append("res://assets/portraits/"+folder+"/"+file)
 paths.sort()
 for i in range(paths.size()):
  var rect=TextureRect.new();rect.texture=load(paths[i]);rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  rect.position=Vector2((i%9)*160,(i/9)*280);rect.size=Vector2(160,245);root.add_child(rect)
  var label=Label.new();label.text=paths[i].trim_prefix("res://assets/portraits/");label.add_theme_font_size_override("font_size",10);label.position=rect.position+Vector2(2,246);label.size=Vector2(158,32);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(label)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://screenshots/portrait-sources-all.png");quit()
