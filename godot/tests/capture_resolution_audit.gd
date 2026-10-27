extends SceneTree
var game
var report: Array=[]
var directory="res://screenshots/resolution-audit"
var baseline="--baseline" in OS.get_cmdline_user_args()
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
 if baseline:
  name=name.replace("final-","baseline-");game.exploration.background.material=null;game.exploration.background.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide();game.adventure_ui.notification_waiting=false
 await create_timer(.25).timeout;await RenderingServer.frame_post_draw
 var picture=root.get_texture().get_image()
 assert(picture.save_png(directory+"/"+name+".png")==OK)
 if name in ["final-wuchang-1440","baseline-wuchang-1440"]:
  assert(picture.get_region(Rect2i(640,440,1024,768)).save_png(directory+"/"+name+"-crop.png")==OK)
  var before=Image.load_from_file(directory+"/baseline-wuchang-1440.png")
  assert(before.get_region(Rect2i(640,440,1024,768)).save_png(directory+"/baseline-wuchang-1440-crop.png")==OK)
 report.append({"name":name,"mode":root.mode,"window":[root.size.x,root.size.y],"image":[picture.get_width(),picture.get_height()],"logical_view":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],"scale_mode":root.content_scale_mode,"scale_aspect":root.content_scale_aspect,"base":[root.content_scale_size.x,root.content_scale_size.y],"camera_zoom":game.exploration.camera.zoom.x,"camera_view":str(game.exploration.camera.get_screen_center_position())})
func run() -> void:
 DirAccess.make_dir_recursive_absolute(directory)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_city();game.chapter_number=1
 var w=game.exploration
 for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
  root.size=size;await process_frame;await process_frame
  w.load_area("changsha");w.player.position=w.safe_player_position(w.city_point([770,500]));w.player.stop();w.camera.snap_to_player()
  await shot("final-changsha-%d" % size.y)
  if size.y==1440:
   game.player_menu.open_menu("inventory");await shot("final-inventory-1440");game.player_menu.close_menu()
   game.player_menu.open_menu("martial");await shot("final-martial-1440");game.player_menu.close_menu()
   game.options.update("size",2);game.say([["hero","강호의 길은 멀고도 험하오. 장사에서 무창을 거쳐 남경에 이르기까지, 수많은 사람의 사정을 들었소. 누군가를 돕겠다는 마음만으로 모든 일이 풀리는 것은 아니었소. 그러니 이번에는 눈앞의 사정부터 찬찬히 살피고, 내가 책임질 수 있는 길을 찾으려 하오."]],Callable(),["hero","nj_vendor","nj_crowd_clerk_runner","nj_constable"])
   await shot("final-dialogue-large-1440");game.advance_dialogue();game.options.update("size",1)
   w.load_area("wuchang");w.camera.snap_to_player();await shot("final-wuchang-1440")
   w.load_area("nanjing");w.player.position=w.safe_player_position(w.city_point([770,510]));w.camera.snap_to_player();await shot("final-nanjing-1440")
 game.options.update("fullscreen",true);await create_timer(.2).timeout;await shot("final-fullscreen-1440");game.options.update("fullscreen",false)
 print("RESOLUTION_AUDIT "+JSON.stringify(report))
 var file=FileAccess.open("user://resolution-final.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 game.queue_free();await process_frame;quit()
