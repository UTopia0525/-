extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
var before=false
var metadata: Dictionary={}
func _initialize() -> void:run.call_deferred()
func frames(count: int) -> void:
	for i in range(count):await process_frame
func camera_at(point: Vector2,zoom: float) -> void:
	scene.follow=false;scene.camera.position=point;scene.camera.zoom=Vector2.ONE*zoom;scene.camera.force_update_scroll()
func shot(name: String) -> void:
	scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh()
	await RenderingServer.frame_post_draw
	var prefix="harmony-before-" if before else "harmony-after-"
	assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/"+prefix+name+".png")==OK)
	metadata[name]={"camera":[scene.camera.position.x,scene.camera.position.y],"zoom":scene.camera.zoom.x,"viewport":[root.size.x,root.size.y],"actors":[],"speeds":[]}
	for p in scene.moving_actors:
		metadata[name].actors.append([p.logical.x,p.logical.y]);metadata[name].speeds.append(p.speed)
func input_direction(direction: Vector2) -> void:
	var projected=Space.project(direction).normalized()
	for key in ["iso_left","iso_right","iso_up","iso_down"]:Input.action_release(key)
	if projected.x>0:Input.action_press("iso_right",projected.x)
	elif projected.x<0:Input.action_press("iso_left",-projected.x)
	if projected.y>0:Input.action_press("iso_down",projected.y)
	elif projected.y<0:Input.action_press("iso_up",-projected.y)
func travel(target: Vector2,count: int) -> void:
	for i in range(count):
		var offset=target-scene.actor.logical;input_direction(offset if offset.length()>.08 else Vector2.ZERO);await process_frame
	input_direction(Vector2.ZERO)
func comparison() -> void:
	scene.patrols_enabled=false
	for i in range(scene.moving_actors.size()):scene.moving_actors[i].set_physics_process(false)
	scene.actor.set_logical(Vector2(4.72,8.4));scene.actor.set_pose("front",false)
	for i in range(scene.npcs.size()):scene.npcs[i].set_logical(Vector2(7+i,9));scene.npcs[i].set_pose("front",false)
	scene.selection_message="미술 비교 · 같은 인물 위치 / 같은 카메라 / 같은 배율"
	camera_at(Vector2(0,290),.75);await frames(3);await shot("overview")
	camera_at(Vector2(-190,320),1.25);await frames(3);await shot("close")
	scene.actor.set_logical(Vector2(4.72,6.5));camera_at(Vector2(-85,290),1.05);await frames(3);await shot("gate")
	var prefix="harmony-before" if before else "harmony-after"
	var file=FileAccess.open("res://prototypes/isometric/screenshots/"+prefix+"-camera.json",FileAccess.WRITE);file.store_string(JSON.stringify(metadata,"  "));file.close()
func run() -> void:
	before=OS.get_cmdline_user_args().has("--before")
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(2)
	if before and scene.actor.display_name=="도원":
		push_error("Before captures require baseline 58b86bc plus this capture script; refusing to overwrite historical images with current art.")
		scene.queue_free();await process_frame;quit(1);return
	await comparison()
	if not before:
		scene.reset_trial()
		for p in scene.moving_actors:p.set_physics_process(true)
		scene.patrols_enabled=true;camera_at(Vector2(-55,325),.85)
		scene.selection_message="실제 입력 재생 · 도원과 왕복 짐꾼 둘 · 기존 속도 유지"
		await frames(60);await travel(Vector2(4.72,5.5),30);await shot("walk-gate")
		await travel(Vector2(4.72,1.45),45);await travel(Vector2(2.8,1.5),30);await shot("behind");await frames(50)
		await travel(Vector2(4.72,1.45),30);await travel(Vector2(4.72,8.4),65);await shot("return");await frames(40)
		scene.patrols_enabled=false;scene.actor.set_physics_process(false);scene.actor.set_logical(Vector2(4.72,8.4));camera_at(Vector2(-190,320),1.25)
		scene.selection_message="보행 비교 · 상체/허리띠 고정 · 양 다리는 반대 위상"
		for i in range(4):
			scene.actor.moving=true;scene.actor.phase=i*PI/2;scene.actor.set_pose("front",false);await frames(10);await shot("step-"+str(i))
		scene.actor.set_logical(Vector2(4.72,6.5));scene.debug_footprints=true;scene.queue_redraw()
		for prop in scene.props:prop.debug_footprint=true;prop.queue_redraw()
		camera_at(Vector2(-85,290),1.05);await frames(4);await shot("collision")
		for prop in scene.props:prop.debug_footprint=false;prop.queue_redraw()
		scene.debug_footprints=false;scene.queue_redraw()
		root.size=Vector2i(2560,1440);await frames(2);await shot("1440p")
	scene.queue_free();await process_frame;print("ISOMETRIC_HARMONY_CAPTURE: PASS before="+str(before));quit()
