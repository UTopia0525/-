extends Node2D
const Space=preload("res://prototypes/isometric/iso_space.gd")
const RANGE=1.25
var world
var target
var caption: Label
var require_release=false
func setup(value) -> void:
	world=value;process_physics_priority=20
	caption=Label.new();caption.add_theme_font_override("font",load("res://assets/fonts/NanumMyeongjo-Regular.ttf"));caption.add_theme_font_size_override("font_size",16)
	caption.add_theme_color_override("font_color",Color("ffe0a0"));caption.add_theme_color_override("font_outline_color",Color("10221b"));caption.add_theme_constant_override("outline_size",5)
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(caption)
func _physics_process(_delta: float) -> void:refresh()
func reachable(npc) -> bool:
	if npc.logical.distance_to(world.actor.logical)>RANGE:return false
	var side=(npc.logical-world.actor.logical).orthogonal().normalized()*.10
	for offset in [Vector2.ZERO,side,-side]:
		var query=PhysicsRayQueryParameters2D.create(Space.project(world.actor.logical+offset),Space.project(npc.logical+offset),3,[world.actor.get_rid(),npc.get_rid()])
		query.hit_from_inside=true
		if not world.get_world_2d().direct_space_state.intersect_ray(query).is_empty():return false
	# A clear foot path alone is insufficient if a roof completely hides the person.
	for y in [18,44,70,90]:
		for x in [-10,0,10]:
			var point=npc.position+Vector2(x,-y)
			if npc.hit(point) and world.pick(point)==npc:return true
	return false
func choose_target():
	var best=null;var nearest=INF
	for npc in world.npcs:
		if not reachable(npc):continue
		var distance=npc.logical.distance_squared_to(world.actor.logical)
		if distance<nearest-.00001 or (is_equal_approx(distance,nearest) and (best==null or npc.traffic_rank<best.traffic_rank)):
			best=npc;nearest=distance
	return best
func refresh() -> void:
	if require_release and not Input.is_action_pressed("iso_interact"):require_release=false
	var busy=is_instance_valid(world.dialogue) and world.dialogue.active
	target=null if busy or require_release else choose_target()
	for npc in world.npcs:
		var focused=npc==target
		if npc.interaction_target!=focused:npc.interaction_target=focused;npc.queue_redraw()
	visible=target!=null
	if not visible:return
	caption.text=target.display_name+" · F 대화"
	var foot=world.get_canvas_transform()*target.position;var extent=caption.get_combined_minimum_size()
	caption.position=foot-Vector2(extent.x/2,112*world.camera.zoom.y)
func interact() -> bool:
	if require_release:return true
	refresh()
	if target==null:return false
	var npc=target
	if world.dialogue.begin(npc):refresh();return true
	return false
