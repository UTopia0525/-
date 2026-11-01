extends SceneTree
## Controlled 120-render/60-physics cadence probe, NOT a throughput/FPS test.
## Reads a temporary marker from rendered frames in memory; creates no video.
var host
var failed=false
var rows=[]
var output="/tmp/isometric-cadence.json"
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
 run.call_deferred()
func rendered() -> Image:
 await process_frame;await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func centroid(frame: Image,predicted: Vector2,color: String) -> Vector2:
 var total=Vector2.ZERO;var count=0
 var rect=Rect2i(Vector2i(predicted-Vector2(35,20)),Vector2i(70,40)).intersection(Rect2i(Vector2i.ZERO,frame.get_size()))
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x):
   var c=frame.get_pixel(x,y)
   if (c.r>.9 and c.g<.15 and c.b>.8) if color=="pink" else (c.r<.15 and c.g>.8 and c.b>.9):
    total+=Vector2(x,y);count+=1
 if count==0:failed=true;push_error("CADENCE marker missing");return Vector2.ZERO
 return total/count
func stats(points: Array) -> Dictionary:
 var steps=[];var zeros=0;var sum=0.0
 for i in range(1,points.size()):
  var step=points[i].distance_to(points[i-1]);steps.append(step);sum+=step;zeros+=int(step<.01)
 var mean=sum/steps.size();var variance=0.0
 for step in steps:variance+=pow(step-mean,2)
 return {"mean_px":mean,"sd_px":sqrt(variance/steps.size()),"stationary_frames":zeros,"steps":steps}
func run() -> void:
 root.size=Vector2i(1280,720)
 host=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(host)
 host.patrols_enabled=false
 for npc in host.npcs:npc.set_logical(Vector2(19,14));npc.set_physics_process(false)
 var marker=Polygon2D.new();marker.polygon=PackedVector2Array([Vector2(-3,-57),Vector2(3,-57),Vector2(3,-51),Vector2(-3,-51)]);marker.color=Color(1,0,1);marker.z_index=4096;host.actor.add_child(marker)
 var landmark=Polygon2D.new();landmark.polygon=PackedVector2Array([Vector2(-3,-3),Vector2(3,-3),Vector2(3,3),Vector2(-3,3)]);landmark.color=Color(0,1,1);landmark.z_index=4095;host.add_child(landmark)
 for interpolate in [false,true]:
  physics_interpolation=interpolate;host.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_ON
  for follow in [false,true]:
   host.follow=follow
   Input.action_release("iso_right");Input.action_release("iso_up")
   host.actor.set_logical(Vector2(9.7,11.1));host.snap_camera();host.reset_physics_interpolation()
   landmark.position=host.actor.position+Vector2(100,-54)
   await rendered();await rendered()
   Input.action_press("iso_right");Input.action_press("iso_up")
   var actors=[];var backgrounds=[];var ticks=[]
   for i in range(20):
    var frame=await rendered()
    actors.append(centroid(frame,host.get_canvas_transform()*(host.actor.position+Vector2(0,-54)),"pink"))
    backgrounds.append(centroid(frame,host.get_canvas_transform()*landmark.position,"blue"))
    ticks.append(Engine.get_physics_frames())
   var result={"interpolation":interpolate,"follow":follow,"actor":stats(actors),"background":stats(backgrounds),"physics_ticks":ticks}
   rows.append(result);print("CADENCE ",JSON.stringify(result))
 Input.action_release("iso_right");Input.action_release("iso_up")
 var old_fixed=rows[0].actor;var new_fixed=rows[2].actor
 var old_follow=rows[1].background;var new_follow=rows[3].background
 if old_fixed.stationary_frames<8 or new_fixed.stationary_frames!=0 or old_follow.stationary_frames<8 or new_follow.stationary_frames!=0 or new_fixed.sd_px>=old_fixed.sd_px or new_follow.sd_px>=old_follow.sd_px:
  failed=true;push_error("CADENCE interpolation did not eliminate repeated positions")
 var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify({"fixed_render_hz":120,"physics_hz":Engine.physics_ticks_per_second,"results":rows},"  "));file.close()
 host.queue_free();await process_frame
 print("ISOMETRIC_MOTION_CADENCE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
