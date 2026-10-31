extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
func _initialize() -> void:run.call_deferred()
func frames(n: int) -> void:
 for i in range(n):await process_frame
func shot(name: String) -> void:
 scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh();await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/spaces-"+name+".png")==OK)
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
 create_timer(90).timeout.connect(func():push_error("Spaces capture watchdog");quit(2))
 root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(3)
 scene.patrols_enabled=false;scene.follow=false;scene.actor.set_logical(Vector2(4.72,8.4))
 for i in range(2):scene.npcs[i].set_logical(Vector2(7+i,9))
 scene.camera.position=Vector2(0,290);scene.camera.zoom=Vector2.ONE*.75;scene.camera.force_update_scroll()
 scene.selection_message="민가의 지붕 대문 / 창고의 목제 대문 / 담장 없는 목공 작업 공간"
 await frames(2);await shot("after")
 scene.debug_footprints=true;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=true;p.queue_redraw()
 await frames(2);await shot("boundaries")
 scene.debug_footprints=false;scene.queue_redraw();scene.grounding.queue_redraw()
 for p in scene.props:p.debug_footprint=false;p.queue_redraw()
 for i in range(2):scene.npcs[i].set_logical(Vector2(10,11+i*.3))
 scene.actor.set_logical(Vector2(4.72,3.5));scene.camera.position=Space.project(Vector2(5.75,3.5))-Vector2(0,65);scene.camera.zoom=Vector2.ONE*1.25;scene.camera.force_update_scroll()
 scene.selection_message="창고 목제 대문 · 실제 키보드 입력으로 양방향 통과"
 await frames(2);await shot("gate-outside")
 for i in range(5):
  await travel(Vector2([5.2,5.6,5.75,5.95,6.3][i],3.5));await shot("gate-step-"+str(i))
 await travel(Vector2(4.72,3.5));await shot("gate-return")
 for i in range(2):scene.npcs[i].set_logical(Vector2(1+i*.6,11))
 scene.actor.set_logical(Vector2(8,10.3));scene.camera.position=Space.project(Vector2(10.15,9.8))-Vector2(0,50);scene.camera.force_update_scroll()
 scene.selection_message="담장 없는 작업 공간 · 공용 마당에서 바로 접근"
 for p in [[9.1,10.15],[10.15,10.0]]:await travel(Vector2(p[0],p[1]))
 await frames(6);await shot("open-workshop")
 scene.reset_trial();scene.patrols_enabled=true;scene.camera.position=Vector2(0,290);scene.camera.zoom=Vector2.ONE*.75;scene.camera.force_update_scroll()
 scene.selection_message="기존 두 짐꾼의 왕복 · 보행/그림체/속도 유지"
 await frames(90);await shot("patrol")
 scene.queue_free();await process_frame;print("ISOMETRIC_SPACES_CAPTURE: PASS");quit()
