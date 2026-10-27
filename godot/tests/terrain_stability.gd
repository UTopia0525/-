extends SceneTree
var game
var failed=false
var results=[]
func _initialize() -> void:run.call_deferred()
func snapshot(point: Vector2) -> Image:
 await process_frame;await RenderingServer.frame_post_draw
 var transform=root.get_stretch_transform()*game.exploration.get_canvas_transform()
 var center: Vector2=transform*point
 return root.get_texture().get_image().get_region(Rect2i(Vector2i(center.round())-Vector2i(32,32),Vector2i(64,64)))
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang()
 for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
  root.size=size;await process_frame;await process_frame
  var w=game.exploration;w.player.position=w.city_point([1100,1790]);w.player.stop();w.camera.snap_to_player()
  var point: Vector2=w.player.position+Vector2(-250,-150);var before: Image=await snapshot(point)
  w.player.position.x+=5;w.camera.snap_to_player();var after: Image=await snapshot(point)
  var changed=0;var maximum=0
  for y in range(64):
   for x in range(64):
    var a=before.get_pixel(x,y);var b=after.get_pixel(x,y)
    var error=roundi(maxf(maxf(absf(a.r-b.r),absf(a.g-b.g)),absf(a.b-b.b))*255)
    maximum=maxi(maximum,error)
    if error>2:changed+=1
  results.append({"height":size.y,"patch_pixels":4096,"changed_over_2_levels":changed,"maximum_channel_error":maximum})
  if changed>20:failed=true;push_error("TERRAIN_STABILITY: fixed world detail shifted: "+str(size))
 print("TERRAIN_STABILITY_DATA "+JSON.stringify(results))
 game.queue_free();await process_frame;print("TERRAIN_STABILITY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
