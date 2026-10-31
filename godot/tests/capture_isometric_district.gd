extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
func _initialize() -> void:run.call_deferred()
func frames(n: int) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh();await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/district-"+name+".png")==OK)
func travel(target: Vector2) -> void:
 for i in range(400):
  var delta=target-scene.actor.logical
  if delta.length()<.10:break
  var v=Space.project(delta).normalized()
  for pair in [["iso_left",maxf(0,-v.x)],["iso_right",maxf(0,v.x)],["iso_up",maxf(0,-v.y)],["iso_down",maxf(0,v.y)]]:
   Input.action_release(pair[0])
   if pair[1]>0:Input.action_press(pair[0],pair[1])
  await process_frame
 for action in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(action)
 await frames(2)
 assert(scene.actor.logical.distance_to(target)<.12,"Actual path cannot reach "+str(target))
func run() -> void:
 create_timer(180).timeout.connect(func():push_error("District capture watchdog");quit(2))
 root.size=Vector2i(1600,1000);scene=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(scene);await frames(3)
 scene.patrols_enabled=false;scene.follow=false
 scene.camera.position=scene.camera_bounds().get_center();scene.camera.zoom=Vector2.ONE*.55;scene.camera.force_update_scroll()
 scene.selection_message="전체 배치 · 20×16논리 타일 / 건물4동 / 자동 짐꾼2명 / 순환 동선"
 await frames(2);await shot("overview")
 scene.debug_footprints=true;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=true;p.queue_redraw()
 await frames(2);await shot("footprints")
 scene.debug_footprints=false;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=false;p.queue_redraw()
 root.size=Vector2i(1280,720);await frames(2);scene.camera.zoom=Vector2.ONE*.85;scene.follow=true
 scene.reset_trial();scene.selection_message="생활 구역 출발 · 기존96높이 / 속도4.8 / 기본85% 카메라"
 await frames(2);await shot("spawn")
 for spot in scene.data.review_spots:
  scene.actor.set_logical(Vector2(spot.point[0],spot.point[1]));scene.snap_camera();scene.selection_message="실제 플레이 카메라 · "+spot.name
  await frames(2);await shot(spot.id)
 # No teleports or camera cuts during this entire loop.
 scene.reset_trial();scene.actor.input_neutral_required=false;scene.follow=true;scene.patrols_enabled=true;scene.snap_camera()
 scene.selection_message="실제 키보드 입력 · 큰길 → 동쪽 길 → 남쪽 골목 → 출발점 · 카메라 추적"
 await shot("loop-start")
 for i in range(scene.data.review_loop.size()):
  var p=scene.data.review_loop[i];await travel(Vector2(p[0],p[1]))
  if i>0:await shot("loop-"+str(i))
 check_finish()
 await frames(20);await shot("loop-finish")
 scene.actor.set_logical(Vector2(16.5,10.25));scene.patrols_enabled=false;scene.npcs[0].set_logical(Vector2(16.5,9.5));scene.npcs[1].set_logical(Vector2(19,15));scene.snap_camera();await frames(2)
 var e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events();await frames(3)
 e=InputEventKey.new();e.keycode=KEY_F;e.physical_keycode=KEY_F;e.pressed=false;Input.parse_input_event(e);await frames(2);await shot("dialogue")
 scene.queue_free();await process_frame;print("ISOMETRIC_DISTRICT_CAPTURE: PASS");quit()
func check_finish() -> void:
 assert(scene.actor.logical.distance_to(Vector2(scene.data.spawn[0],scene.data.spawn[1]))<.15,"Recorded loop failed to return")
