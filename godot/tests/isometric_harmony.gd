extends SceneTree
const Space=preload("res://prototypes/isometric/iso_space.gd")
var scene
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("ISO_HARMONY: "+message)
func run() -> void:
	scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await process_frame;await physics_frame
	scene.patrols_enabled=false
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/assets/manifest.json"))
	check(scene.actor.display_name=="도원","player and locator identity")
	check(scene.visibility_hint.captions[scene.actor].text=="도원 · 가림","locator uses protagonist name")
	check(scene.actor.images.front.atlas.resource_path==manifest.hero.front.texture,"hero uses independent atlas")
	check(is_equal_approx(scene.actor.base_scale.y*manifest.hero.canvas_height,96),"unchanged protagonist target height")
	for npc in scene.npcs:
		check(is_equal_approx(npc.speed,4.8),"autonomous speed unchanged")
		check(npc.images.front.atlas.resource_path==manifest.npc.front.texture,"commoners retain original art")
		check(npc.rig.hip_start==.66 and npc.rig.stride==.090,"commoner gait unchanged")
	check(scene.grounding.get_index()<scene.actors.get_index(),"all ground shadows render before characters")
	check(scene.grounding.get_child_count()==0,"ground decoration adds no physics bodies")
	check(scene.grounding.CAST_DIRECTION==Vector2(1,.65),"one consistent shadow direction")
	for prop in scene.props:
		if prop.spec.kind not in ["tree","urn"]:continue
		check(prop.sprite!=null,"placeholder replaced with authored art "+str(prop.name))
		check(prop.physical_footprints==[prop.footprint],"original ground occupancy retained")
		var info=manifest.buildings[prop.spec.kind];var pivot=Vector2(info.pivot[0],info.pivot[1])
		check(prop.sprite.to_global(pivot).distance_to(Space.project(prop.footprint.end))<.001,"registered ground corner matches collider")
		check(not prop.hit(prop.sprite.to_global(Vector2(0,0))),"transparent decor corners cannot be picked")
	for key in ["front","back"]:
		scene.actor.moving=true;scene.actor.phase=PI/2;scene.actor.set_pose(key,false)
		var first: PackedVector2Array=scene.actor.rig.polygon.duplicate()
		scene.actor.phase=PI*1.5;scene.actor.set_pose(key,false)
		var protected=0
		for i in range(first.size()):
			if scene.actor.rig.original[i].y/scene.actor.rig.tex_size.y<.80:
				check(first[i]==scene.actor.rig.polygon[i],"head, upper robe and sash stay rigid")
				protected+=1
		check(protected>200,"substantial garment area protected from foot skinning")
	check(scene.data.props.size()==5 and scene.data.walls.size()==4,"same authored buildings and wall lines")
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/main.tscn","main game entry unchanged")
	scene.queue_free();await process_frame;print("ISOMETRIC_HARMONY: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
