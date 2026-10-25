extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ROAD_STRIDE: "+message)
func length_of(path: PackedVector2Array) -> float:
	var result:=0.0
	for i in range(1,path.size()):result+=path[i-1].distance_to(path[i])
	return result
func write_old(slot: int,revision: int,current: Vector2) -> void:
	var data=game.save_system.capture();data.world.layout_version=revision;data.world.position=[current.x*1.6,current.y*(3.2 if revision==1 else 1.6)]
	if revision==1:data.world.erase("layout_version")
	check(game.save_system.validate(data),"old road revision validates")
	var f=FileAccess.open(game.save_system.path(slot),FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
func run() -> void:
	# Render/navigation baseline uses the same authored route at its previous size.
	var old=load("res://scripts/mountain_road_map.gd").new();old.world_scale=Vector2(4,4);old.navigation_cell=32;old.data.world_size=[4096,5120]
	var line=PackedVector2Array()
	for p in old.data.route:line.append(old.point(p))
	old.walk_polygon=Geometry2D.offset_polyline(line,196,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)[0]
	root.add_child(old)
	var before=length_of(old.path_to(old.point([125,1175]),old.point([740,64])));old.free();await physics_frame
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"mountain_road","arrival":[125,1175]}})
	var w=game.exploration;var p=w.player
	var path=w.path_to(w.city_point([740,64]));var after=length_of(path)
	check(not path.is_empty() and after<before*.68 and after>before*.55,"road walk length drops about37.5 percent")
	check(p.display_height==140 and p.speed==360,"road shortening retains player size and speed")
	var report={"old_world_size":[4096,5120],"new_world_size":[2560,3200],"old_path":before,"new_path":after,"old_seconds":before/p.speed,"new_seconds":after/p.speed}
	print("ROAD_DISTANCE "+JSON.stringify(report))
	var file=FileAccess.open("user://road-distance.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	check(game.save_system.write_slot(1),"compact road save")
	var original=w.player.position
	write_old(2,1,original);check(game.save_system.load_slot(2) and w.player.position.distance_to(original)<.01,"revision1 XY migration")
	write_old(3,2,original);check(game.save_system.load_slot(3) and w.player.position.distance_to(original)<.01,"revision2 XY migration")
	check(game.save_system.write_slot(4) and game.save_system.load_slot(4) and w.player.position.distance_to(original)<.01,"revision3 never scales twice")
	# Empty horizontal stretch: exercise real movement and fixed-size body art.
	w.player.position=w.city_point([360,1175]);p.stop();await physics_frame
	for facing in ["left","right"]:
		p.facing=facing;p.stop();var scale_before: Vector2=p.sprite.scale
		var region_before=p.sprite.sprite_frames.get_frame_texture("idle_"+facing,0).region
		check(p.side_mesh.visible and not p.sprite.visible,"side mesh is active")
		var torso_before=p.side_mesh.scale
		var last_phase:=0.0;var advanced:=false
		Input.action_press("move_"+facing)
		for i in range(12):
			await physics_frame
			advanced=advanced or absf(p.gait_phase-last_phase)>.001;last_phase=p.gait_phase
			check(p.sprite.scale.is_equal_approx(scale_before) and p.side_mesh.scale==torso_before,"walk cannot resize torso")
		Input.action_release("move_"+facing);await physics_frame;await physics_frame
		check(advanced and p.side_material.get_shader_parameter("walking")==0.0,"real motion animates legs and release returns to neutral")
		check(p.sprite.scale==scale_before and p.sprite.sprite_frames.get_frame_texture("idle_"+facing,0).region==region_before,"idle retains identical source frame and scale")
		check(p.get_node("Feet").shape.radius==16,"visual gait preserves foot collision")
		p.stop();check(p.gait_phase==0.0,"dialogue/stop resets gait")
	game.reset();await create_timer(.3).timeout
	for v in game.music.players:v.stop();v.stream=null
	for v in game.options.voices:v.stop();v.stream=null
	game.queue_free();await process_frame
	print("GODOT_ROAD_STRIDE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
