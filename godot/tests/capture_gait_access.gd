extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
func _initialize() -> void:run.call_deferred()
func frames(count: int) -> void:
 for i in range(count):await process_frame
func shot(name: String) -> void:
 scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh();await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/gait-access-"+name+".png")==OK)
func input_direction(direction: Vector2) -> void:
 var p=Space.project(direction).normalized()
 for action in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(action)
 if p.x>0:Input.action_press("iso_right",p.x)
 elif p.x<0:Input.action_press("iso_left",-p.x)
 if p.y>0:Input.action_press("iso_down",p.y)
 elif p.y<0:Input.action_press("iso_up",-p.y)
func travel(target: Vector2,count: int) -> void:
 for i in range(count):
  var delta=target-scene.actor.logical;input_direction(delta if delta.length()>.05 else Vector2.ZERO);await process_frame
 input_direction(Vector2.ZERO)
func run() -> void:
 root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(2)
 scene.patrols_enabled=false;scene.follow=false;scene.actor.set_logical(Vector2(4.72,8.4))
 for i in range(scene.npcs.size()):scene.npcs[i].set_logical(Vector2(7+i,9))
 scene.camera.position=Vector2(0,290);scene.camera.zoom=Vector2.ONE*.75;scene.camera.force_update_scroll()
 scene.selection_message="배치 비교 · 같은 카메라 / 같은 인물 위치 / 같은 배율"
 await frames(2);await shot("after-overview")
 scene.debug_footprints=true;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=true;p.queue_redraw()
 await frames(2);await shot("routes")
 scene.debug_footprints=false;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=false;p.queue_redraw()
 scene.reset_trial();scene.patrols_enabled=true;scene.camera.zoom=Vector2.ONE*.85;scene.camera.position=Vector2(-10,325);scene.camera.force_update_scroll()
 scene.selection_message="실제 입력 재생 · 주도로 → 하역 출입구 → 창고 문 앞"
 for p in [[7.7,8.0],[7.7,6.4],[7.95,5.1],[7.95,3.52]]:await travel(Vector2(p[0],p[1]),35)
 await frames(8);await shot("warehouse-door")
 # Compare all characters at equal ground depth. This is a pose review setup.
 scene.patrols_enabled=false
 var places=[Vector2(6.2,10.6),Vector2(7.6,9.2),Vector2(9,7.8)]
 for i in range(3):scene.moving_actors[i].set_physics_process(false);scene.moving_actors[i].set_logical(places[i])
 scene.camera.position=Vector2(-100,470);scene.camera.zoom=Vector2.ONE*1.25;scene.camera.force_update_scroll()
 scene.selection_message="관절 보행 8단계 · 무릎 / 반대 팔 / 골반 상하 · 배율과 바닥 기준 유지"
 for i in range(8):
  for p in scene.moving_actors:p.moving=true;p.phase=i*TAU/8;p.set_pose("front",false)
  await frames(2);await shot("step-"+str(i))
 # A slowed-in-place preview exposes knee/arm phases, followed by the rear view.
 for key in ["front","back"]:
  scene.selection_message="보행 자세 검토 · "+("앞쪽" if key=="front" else "뒤쪽")+" · 관절 주기를 느리게 재생"
  for i in range(90):
   for p in scene.moving_actors:p.moving=true;p.phase=i*TAU/30;p.set_pose(key,false)
   await process_frame
  await shot(key)
 for p in scene.moving_actors:p.stop_motion()
 await frames(3);await shot("idle")
 scene.queue_free();await process_frame;print("GAIT_ACCESS_CAPTURE: PASS");quit()
