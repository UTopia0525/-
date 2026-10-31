extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
func _initialize() -> void:run.call_deferred()
func frames(n: int) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh();await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/orientation-"+name+".png")==OK)
func travel(target: Vector2) -> void:
 for i in range(200):
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
 create_timer(90).timeout.connect(func():push_error("Orientation capture watchdog");quit(2))
 root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(3)
 scene.patrols_enabled=false;scene.follow=false;scene.actor.set_logical(Vector2(4.72,8.4))
 for i in range(2):scene.npcs[i].set_logical(Vector2(7+i,9))
 scene.camera.position=Vector2(0,290);scene.camera.zoom=Vector2.ONE*.75;scene.camera.force_update_scroll()
 scene.selection_message="입구는 중앙 골목을 향함 · 민가와 창고의 독립 마당 · 창고 뒷면 전용 그림"
 await frames(2);await shot("after")
 scene.debug_footprints=true;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=true;p.queue_redraw()
 await frames(2);await shot("boundaries")
 scene.debug_footprints=false;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=false;p.queue_redraw()
 for i in range(2):scene.npcs[i].set_logical(Vector2(10,10+i))
 scene.selection_message="실제 입력 · 중앙 골목 → 창고 마당 출입구 → 길을 향한 숨은 정면 문"
 for p in [[4.72,8],[4.72,5.2],[4.72,3.45],[6.12,3.45],[6.62,3.45]]:await travel(Vector2(p[0],p[1]))
 await shot("warehouse-entry")
 scene.actor.set_logical(Vector2(3.12,8));scene.selection_message="실제 입력 · 민가 대문 → 분리된 앞마당 → 민가 입구"
 for p in [[3.12,7.3],[3.12,6.5],[3.12,5.3],[3.605814,3.162791],[3.055814,3.162791]]:await travel(Vector2(p[0],p[1]))
 await shot("house-entry")
 scene.actor.set_logical(Vector2(4.72,8.4));scene.reset_trial();scene.patrols_enabled=true
 scene.selection_message="자동 짐꾼 · 민가 마당 왕복 / 외부 뒷길 왕복 · 이동 속도 유지"
 await frames(120);await shot("patrol")
 scene.queue_free();await process_frame;print("ISOMETRIC_ORIENTATION_CAPTURE: PASS");quit()
