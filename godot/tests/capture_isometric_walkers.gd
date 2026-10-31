extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
func _initialize() -> void:run.call_deferred()
func frames(count: int) -> void:
	for i in range(count):await process_frame
func shot(name: String) -> void:
	scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/walkers-"+name+".png")==OK)
func input_direction(direction: Vector2) -> void:
	var projected=Space.project(direction).normalized()
	for key in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(key)
	if projected.x>0:Input.action_press("iso_right",projected.x)
	elif projected.x<0:Input.action_press("iso_left",-projected.x)
	if projected.y>0:Input.action_press("iso_down",projected.y)
	elif projected.y<0:Input.action_press("iso_up",-projected.y)
func travel(target: Vector2,count: int) -> void:
	for i in range(count):
		var offset=target-scene.actor.logical
		input_direction(offset if offset.length()>.08 else Vector2.ZERO)
		await process_frame
	input_direction(Vector2.ZERO)
func run() -> void:
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(2)
	scene.follow=false;scene.camera.position=Vector2(-55,325);scene.camera.zoom=Vector2.ONE*.85;scene.camera.force_update_scroll()
	scene.selection_message="실제 입력 재생 · 두 짐꾼은 정해진 길을 왕복합니다."
	await frames(75);await shot("courtyard")
	await travel(Vector2(4.72,5.5),30);await shot("gate")
	await travel(Vector2(4.72,1.45),45)
	await travel(Vector2(2.8,1.5),30);await shot("behind")
	await frames(90)
	await travel(Vector2(4.72,1.45),30)
	await travel(Vector2(4.72,8.4),65);await shot("return")
	await frames(60)
	# Registered poses rendered by Godot for a leg-by-leg comparison, no pixel edits.
	scene.patrols_enabled=false;scene.actor.set_logical(Vector2(4.72,8.4));scene.actor.set_physics_process(false)
	for i in range(scene.npcs.size()):scene.npcs[i].set_logical(Vector2(7+i,9))
	scene.camera.position=Vector2(-190,320);scene.camera.zoom=Vector2.ONE*1.25;scene.camera.force_update_scroll()
	scene.selection_message="보행 단계 비교 · 같은 그림/크기/발밑 기준 · 두 발은 반대 위상"
	for i in range(4):
		scene.actor.moving=true;scene.actor.phase=i*PI/2;scene.actor.set_pose("front",false)
		await frames(8);await shot("step-"+str(i))
	# Deliberately clustered hidden actors exercise label placement (not a patrol route).
	for i in range(scene.moving_actors.size()):
		var person=scene.moving_actors[i];person.set_logical(Vector2(2.5+i*.35,1.5));person.set_physics_process(false)
	scene.camera.position=Vector2(-85,290);scene.camera.zoom=Vector2.ONE*1.05;scene.camera.force_update_scroll()
	scene.selection_message="가림 비교 배치 · 금색은 조작 인물 / 청색은 왕복 NPC · 이름표 겹침 방지"
	await frames(8);await shot("labels")
	await frames(30)
	root.size=Vector2i(2560,1440);await frames(2);await shot("1440p")
	scene.queue_free();await process_frame;print("ISOMETRIC_WALKERS_CAPTURE: PASS");quit()
