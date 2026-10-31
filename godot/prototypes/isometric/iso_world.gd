extends Node2D
const Space=preload("res://prototypes/isometric/iso_space.gd")
const Prop=preload("res://prototypes/isometric/iso_prop.gd")
const Wall=preload("res://prototypes/isometric/iso_wall.gd")
const Actor=preload("res://prototypes/isometric/iso_actor.gd")
const ACCESS=preload("res://prototypes/isometric/iso_access_rules.gd")
@export_file("*.json") var layout_path="res://prototypes/isometric/layout.json"
var data: Dictionary
var map_size=Vector2.ZERO
var art: Dictionary
var actors: Node2D
var actor
var moving_actors: Array=[]
var npcs: Array=[]
var patrols_enabled=true
var props: Array=[]
var camera: Camera2D
var selected
var title: Label
var details: Label
var status: Label
var debug_footprints=false
var follow=true
var texture_stone: AtlasTexture
var texture_soil: AtlasTexture
var registered_actions: Array[String]=[]
var depth_cycles=0
var selection_message="대문을 지나 좁은 골목으로 들어가 보세요. · 이동 속도 2배"
var drag=false
var actor_occluded=false
var occluded_samples=0
var show_occlusion_hint=true
var visibility_hint
var grounding
var interaction
var dialogue
var last_sorted_positions: Array=[]
var access_errors: Array[String]=[]
func _ready() -> void:
	process_physics_priority=10
	data=JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	map_size=Vector2(data.size[0],data.size[1])
	art=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/assets/manifest.json"))
	_register_inputs()
	var material_texture=load("res://assets/maps/nanjing/market-slice/materials.png")
	texture_stone=AtlasTexture.new();texture_stone.atlas=material_texture;texture_stone.region=Rect2(Vector2.ZERO,material_texture.get_size()/2)
	texture_soil=AtlasTexture.new();texture_soil.atlas=material_texture;texture_soil.region=Rect2(Vector2(material_texture.get_width()/2.0,0),material_texture.get_size()/2)
	actors=Node2D.new();actors.name="DepthSortedActors";add_child(actors)
	for entry in data.props:
		var prop=Prop.new();prop.setup(entry,art.buildings);actors.add_child(prop);props.append(prop)
	for section in data.walls:
		var r=section.rect;var along_u=float(r[2])>float(r[3]);var length=float(r[2] if along_u else r[3]);var count=ceili(length/.75)
		for i in range(count):
			var start=length*i/count;var end=length*(i+1)/count
			var rect=[r[0]+start,r[1],end-start,r[3]] if along_u else [r[0],r[1]+start,r[2],end-start]
			var wall=Wall.new();wall.setup({"id":section.id+"_"+str(i),"name":"마당 경계 담장","kind":"wall","rect":rect,"plot":section.get("plot",""),"end_cap":i==count-1},art.wall_materials)
			actors.add_child(wall);props.append(wall)
	actor=Actor.new();actor.setup(art.hero,self);actor.display_name="도원";actors.add_child(actor);moving_actors.append(actor);reset_actor()
	for entry in data.get("patrols",[]):
		var npc=Actor.new();npc.setup(art.npc,self);npc.name=entry.id;npc.display_name=entry.name
		npc.interactive=false;npc.traffic_rank=npcs.size()+1;actors.add_child(npc);moving_actors.append(npc);npcs.append(npc)
		npc.patrol=preload("res://prototypes/isometric/iso_patrol.gd").new();npc.patrol.setup(npc,entry.route)
	for r in [Rect2(-1,-1,map_size.x+2,1),Rect2(-1,map_size.y,map_size.x+2,1),Rect2(-1,0,1,map_size.y),Rect2(map_size.x,0,1,map_size.y)]:
		var wall=StaticBody2D.new();wall.collision_layer=1
		var shape=CollisionPolygon2D.new();shape.polygon=Space.diamond(r);wall.add_child(shape);add_child(wall)
	grounding=preload("res://prototypes/isometric/iso_grounding.gd").new();grounding.setup(self);add_child(grounding);move_child(grounding,0)
	camera=Camera2D.new();camera.zoom=Vector2.ONE*.85;camera.position_smoothing_enabled=false;add_child(camera);camera.make_current();snap_camera()
	_build_hud()
	var dialogue_layer=CanvasLayer.new();dialogue_layer.layer=20;add_child(dialogue_layer)
	dialogue=preload("res://prototypes/isometric/iso_dialogue.gd").new();dialogue.setup(self);dialogue_layer.add_child(dialogue)
	update_depth();queue_redraw()
	_validate_entrances.call_deferred()
func _validate_entrances() -> void:
	await get_tree().physics_frame
	access_errors=ACCESS.validate(self)
	if not access_errors.is_empty():push_warning("Prototype entrance validation: "+str(access_errors))
func _register_inputs() -> void:
	var actions={"iso_left":[KEY_A,KEY_LEFT],"iso_right":[KEY_D,KEY_RIGHT],"iso_up":[KEY_W,KEY_UP],"iso_down":[KEY_S,KEY_DOWN],"iso_interact":[KEY_F],"iso_debug":[KEY_G],"iso_reset":[KEY_R],"iso_camera":[KEY_C],"iso_hint":[KEY_H],"iso_patrol":[KEY_P]}
	for action in actions:
		if InputMap.has_action(action):continue
		registered_actions.append(action);InputMap.add_action(action)
		for code in actions[action]:
			var event=InputEventKey.new();event.physical_keycode=code;InputMap.action_add_event(action,event)
func _exit_tree() -> void:
	for action in registered_actions:InputMap.erase_action(action)
func reset_actor() -> void:
	actor.set_logical(Vector2(data.spawn[0],data.spawn[1]))
func reset_trial() -> void:
	reset_actor()
	for npc in npcs:npc.patrol.reset()
func _draw() -> void:
	var boundary=Space.diamond(Rect2(Vector2.ZERO,map_size));var low=boundary.duplicate()
	for i in range(low.size()):low[i]+=Vector2(0,14)
	draw_colored_polygon(low,Color("263b35"))
	for u in range(int(map_size.x)):
		for v in range(int(map_size.y)):
			var points=Space.diamond(Rect2(u,v,1,1));var road=false
			for a in data.paving:
				if Rect2(a[0],a[1],a[2],a[3]).has_point(Vector2(u+.5,v+.5)):road=true;break
			var tint=1.0+float((u*17+v*31)%7-3)*.003
			var uv=Vector2(u%3,v%3)/3.0;var step=1.0/3.0
			var colors=PackedColorArray([Color(tint,tint,tint),Color(tint,tint,tint),Color(tint,tint,tint),Color(tint,tint,tint)])
			draw_polygon(points,colors,PackedVector2Array([uv,uv+Vector2(step,0),uv+Vector2(step,step),uv+Vector2(0,step)]),texture_stone if road else texture_soil)
			draw_polyline(points+PackedVector2Array([points[0]]),Color(.18,.24,.21,.12 if debug_footprints else .055),1)
	draw_polyline(boundary+PackedVector2Array([boundary[0]]),Color("7c8870"),2)
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(actor):return
	update_depth()
	update_occlusion()
	if follow:snap_camera()
	if is_instance_valid(details):
		details.text=selection_message
		status.text="논리 좌표 (%.2f, %.2f)   ·   %s   ·   %.0f%%" % [actor.logical.x,actor.logical.y,"카메라 추적" if follow else "카메라 고정",camera.zoom.x*100]
func snap_camera() -> void:
	var target=actor.position+Vector2(0,-96)
	place_camera(target)
func camera_bounds() -> Rect2:
	# Ground diamond bounds plus the original artwork/roof margins.
	# These margins preserve the 12x12 framing and are not map dimensions.
	return Rect2(Vector2(-map_size.y*Space.TILE.x/2-82,-330),Vector2((map_size.x+map_size.y)*Space.TILE.x/2+164,(map_size.x+map_size.y)*Space.TILE.y/2+462))
func constrained_camera(target: Vector2) -> Vector2:
	var extent=get_viewport_rect().size/(camera.zoom*2)
	var bounds=camera_bounds();var low=bounds.position+extent;var high=bounds.end-extent;var center=bounds.get_center()
	return Vector2(center.x if low.x>high.x else clampf(target.x,low.x,high.x),center.y if low.y>high.y else clampf(target.y,low.y,high.y))
func place_camera(target: Vector2) -> void:
	camera.position=constrained_camera(target)
	camera.force_update_scroll()
func comes_before(a,b) -> bool:
	var a_actor=a in moving_actors;var b_actor=b in moving_actors
	if a_actor and b_actor:
		var gap=a.position.y-b.position.y
		return gap<0 if absf(gap)>.01 else a.traffic_rank<b.traffic_rank
	var gate=b if a_actor else a if b_actor else null
	var person=a if a_actor else b if b_actor else null
	if gate!=null and gate.spec.kind=="gate" and gate.footprint.has_point(person.logical):return a==person
	return Space.before(a.footprint,b.footprint)
func update_depth() -> void:
	var positions=moving_actors.map(func(n):return n.logical)
	if positions==last_sorted_positions:return
	last_sorted_positions=positions
	var nodes=props.duplicate();nodes.append_array(moving_actors)
	var edges={};var indegree={}
	for node in nodes:edges[node]=[];indegree[node]=0
	for i in range(nodes.size()):
		for j in range(i+1,nodes.size()):
			var a=nodes[i];var b=nodes[j]
			if comes_before(a,b):edges[a].append(b);indegree[b]+=1
			elif comes_before(b,a):edges[b].append(a);indegree[a]+=1
	var remaining=nodes.duplicate();var ordered=[]
	while not remaining.is_empty():
		var ready=remaining.filter(func(n):return indegree[n]==0)
		if ready.is_empty():depth_cycles+=1;ready=remaining.duplicate()
		ready.sort_custom(func(a,b):
			var ay=Space.project(a.footprint.get_center()).y;var by=Space.project(b.footprint.get_center()).y
			return ay<by if not is_equal_approx(ay,by) else str(a.name)<str(b.name))
		var next=ready[0];ordered.append(next);remaining.erase(next)
		for other in edges[next]:indegree[other]-=1
	for i in range(ordered.size()):actors.move_child(ordered[i],i)
func update_occlusion() -> void:
	var occluders=props.duplicate();occluders.append_array(moving_actors)
	for person in moving_actors:
		person.occluded_samples=0
		for y in [18,44,70,90]:
			for x in [-10,0,10]:
				var point=person.position+Vector2(x,-y)
				for prop in occluders:
					if prop.get_index()>person.get_index() and prop.hit(point):person.occluded_samples+=1;break
		person.occluded=person.occluded_samples>=3
	occluded_samples=actor.occluded_samples;actor_occluded=actor.occluded
func pick(world_point: Vector2):
	var nodes=actors.get_children();nodes.reverse()
	for node in nodes:
		if node.hit(world_point):return node
	return null
func select_target(target) -> void:
	selected=target
	for prop in props:prop.picked=(prop==selected);prop.queue_redraw()
	for person in moving_actors:person.picked=(person==selected);person.queue_redraw()
	selection_message="선택: "+(selected.display_name if selected in moving_actors else str(selected.spec.name)) if selected!=null else "선택한 대상이 없습니다."
func interact() -> void:
	if interaction.interact():return
	var nearest=null;var distance=INF
	for prop in props:
		var d=actor.logical.distance_to(prop.footprint.get_center())
		if d<distance:distance=d;nearest=prop
	if nearest!=null and distance<3.0:
		select_target(nearest);selection_message+="  ·  시험용 조사입니다. 본게임 대화와 연결되지 않습니다."
	else:selection_message="가까이 다가가 F를 눌러 보세요."
func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(dialogue) and dialogue.active:return
	if event.is_action_pressed("iso_debug") and not event.is_echo():
		debug_footprints=not debug_footprints
		for prop in props:prop.debug_footprint=debug_footprints;prop.queue_redraw()
		queue_redraw();get_viewport().set_input_as_handled()
		grounding.queue_redraw()
		if debug_footprints:
			access_errors=ACCESS.validate(self);selection_message="발밑/진입 동선 · "+("건물·대문·열린 공간 검사 통과" if access_errors.is_empty() else str(access_errors))
	elif event.is_action_pressed("iso_hint") and not event.is_echo():show_occlusion_hint=not show_occlusion_hint
	elif event.is_action_pressed("iso_reset") and not event.is_echo():reset_trial();snap_camera()
	elif event.is_action_pressed("iso_patrol") and not event.is_echo():
		patrols_enabled=not patrols_enabled;selection_message="자동 NPC "+("왕복 재개" if patrols_enabled else "정지 · 충돌은 유지")
	elif event.is_action_pressed("iso_camera") and not event.is_echo():follow=not follow
	elif event.is_action_pressed("iso_interact") and not event.is_echo():interact();get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE:drag=event.pressed;follow=false
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			camera.zoom=Vector2.ONE*clampf(camera.zoom.x+(.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -.1),.65,1.25)
			if follow:snap_camera()
			else:place_camera(camera.position)
		elif event.pressed and event.button_index==MOUSE_BUTTON_LEFT:select_target(pick(get_canvas_transform().affine_inverse()*event.position))
	elif event is InputEventMouseMotion and drag:place_camera(camera.position-event.relative/camera.zoom)
func _build_hud() -> void:
	var layer=CanvasLayer.new();add_child(layer)
	visibility_hint=preload("res://prototypes/isometric/iso_visibility_hint.gd").new();visibility_hint.setup(self);layer.add_child(visibility_hint)
	interaction=preload("res://prototypes/isometric/iso_interaction.gd").new();interaction.setup(self);layer.add_child(interaction)
	var font=load("res://assets/fonts/NanumMyeongjo-Regular.ttf")
	var panel=PanelContainer.new();panel.position=Vector2(22,18);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("142923eb");style.border_color=Color("98845b");style.set_border_width_all(1);style.set_content_margin_all(12);panel.add_theme_stylebox_override("panel",style)
	var list=VBoxContainer.new();list.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(list)
	for text in [data.get("title","골목 시험 · 도원과 왕복 짐꾼 둘"),"WASD / 방향키 이동 · F 대화/조사 · 클릭 선택","휠 확대 · 중간 버튼 드래그 · C 카메라 추적","G 충돌 · H 가림 표시(대화 중 기록) · P 왕복 · R 초기화"]:
		var label=Label.new();label.text=text;label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",15);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;list.add_child(label)
	details=Label.new();details.position=Vector2(24,650);details.add_theme_font_override("font",font);details.add_theme_font_size_override("font_size",17);details.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(details)
	status=Label.new();status.position=Vector2(24,682);status.add_theme_font_override("font",font);status.add_theme_font_size_override("font_size",14);status.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(status)
