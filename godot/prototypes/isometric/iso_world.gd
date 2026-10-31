extends Node2D
const Space=preload("res://prototypes/isometric/iso_space.gd")
const Prop=preload("res://prototypes/isometric/iso_prop.gd")
const Wall=preload("res://prototypes/isometric/iso_wall.gd")
const Actor=preload("res://prototypes/isometric/iso_actor.gd")
var data: Dictionary
var actors: Node2D
var actor
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
var last_sorted_position=Vector2(INF,INF)
func _ready() -> void:
	process_physics_priority=10
	data=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/layout.json"))
	var art=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/assets/manifest.json"))
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
			var wall=Wall.new();wall.setup({"id":section.id+"_"+str(i),"name":"巷 · 골목 담장","kind":"wall","rect":rect},{})
			actors.add_child(wall);props.append(wall)
	actor=Actor.new();actor.setup(art.npc,self);actors.add_child(actor);reset_actor()
	for r in [Rect2(-1,-1,14,1),Rect2(-1,12,14,1),Rect2(-1,0,1,12),Rect2(12,0,1,12)]:
		var wall=StaticBody2D.new();wall.collision_layer=1
		var shape=CollisionPolygon2D.new();shape.polygon=Space.diamond(r);wall.add_child(shape);add_child(wall)
	camera=Camera2D.new();camera.zoom=Vector2.ONE*.85;camera.position_smoothing_enabled=false;add_child(camera);camera.make_current();snap_camera()
	_build_hud();update_depth();queue_redraw()
func _register_inputs() -> void:
	var actions={"iso_left":[KEY_A,KEY_LEFT],"iso_right":[KEY_D,KEY_RIGHT],"iso_up":[KEY_W,KEY_UP],"iso_down":[KEY_S,KEY_DOWN],"iso_interact":[KEY_F],"iso_debug":[KEY_G],"iso_reset":[KEY_R],"iso_camera":[KEY_C],"iso_hint":[KEY_H]}
	for action in actions:
		if InputMap.has_action(action):continue
		registered_actions.append(action);InputMap.add_action(action)
		for code in actions[action]:
			var event=InputEventKey.new();event.physical_keycode=code;InputMap.action_add_event(action,event)
func _exit_tree() -> void:
	for action in registered_actions:InputMap.erase_action(action)
func reset_actor() -> void:
	actor.set_logical(Vector2(data.spawn[0],data.spawn[1]))
func _draw() -> void:
	var boundary=Space.diamond(Rect2(0,0,12,12));var low=boundary.duplicate()
	for i in range(low.size()):low[i]+=Vector2(0,14)
	draw_colored_polygon(low,Color("263b35"))
	for u in range(12):
		for v in range(12):
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
	var extent=get_viewport_rect().size/(camera.zoom*2)
	var low=Vector2(-850,-330)+extent;var high=Vector2(850,900)-extent
	camera.position=Vector2(clampf(target.x,minf(low.x,high.x),maxf(low.x,high.x)),clampf(target.y,minf(low.y,high.y),maxf(low.y,high.y)))
	camera.force_update_scroll()
func comes_before(a,b) -> bool:
	var gate=b if a==actor else a if b==actor else null
	if gate!=null and gate.spec.kind=="gate" and gate.footprint.has_point(actor.logical):
		return a==actor
	return Space.before(a.footprint,b.footprint)
func update_depth() -> void:
	if actor.logical.is_equal_approx(last_sorted_position):return
	last_sorted_position=actor.logical
	var nodes=props.duplicate();nodes.append(actor)
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
	occluded_samples=0
	for y in [18,44,70,90]:
		for x in [-10,0,10]:
			var point=actor.position+Vector2(x,-y)
			for prop in props:
				if prop.get_index()>actor.get_index() and prop.hit(point):occluded_samples+=1;break
	actor_occluded=occluded_samples>=3
func pick(world_point: Vector2):
	var nodes=actors.get_children();nodes.reverse()
	for node in nodes:
		if node.hit(world_point):return node
	return null
func select_target(target) -> void:
	selected=target
	for prop in props:prop.picked=(prop==selected);prop.queue_redraw()
	actor.picked=(actor==selected);actor.queue_redraw()
	selection_message="선택: "+("마을 짐꾼" if selected==actor else str(selected.spec.name)) if selected!=null else "선택한 대상이 없습니다."
func interact() -> void:
	var nearest=null;var distance=INF
	for prop in props:
		var d=actor.logical.distance_to(prop.footprint.get_center())
		if d<distance:distance=d;nearest=prop
	if nearest!=null and distance<3.0:
		select_target(nearest);selection_message+="  ·  시험용 조사입니다. 본게임 대화와 연결되지 않습니다."
	else:selection_message="가까이 다가가 F를 눌러 보세요."
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("iso_debug") and not event.is_echo():
		debug_footprints=not debug_footprints
		for prop in props:prop.debug_footprint=debug_footprints;prop.queue_redraw()
		queue_redraw();get_viewport().set_input_as_handled()
	elif event.is_action_pressed("iso_hint") and not event.is_echo():show_occlusion_hint=not show_occlusion_hint
	elif event.is_action_pressed("iso_reset") and not event.is_echo():reset_actor();snap_camera()
	elif event.is_action_pressed("iso_camera") and not event.is_echo():follow=not follow
	elif event.is_action_pressed("iso_interact") and not event.is_echo():interact()
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE:drag=event.pressed;follow=false
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			camera.zoom=Vector2.ONE*clampf(camera.zoom.x+(.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -.1),.65,1.25)
			if follow:snap_camera()
		elif event.pressed and event.button_index==MOUSE_BUTTON_LEFT:select_target(pick(get_canvas_transform().affine_inverse()*event.position))
	elif event is InputEventMouseMotion and drag:camera.position-=event.relative/camera.zoom
func _build_hud() -> void:
	var layer=CanvasLayer.new();add_child(layer)
	visibility_hint=preload("res://prototypes/isometric/iso_visibility_hint.gd").new();visibility_hint.setup(self);layer.add_child(visibility_hint)
	var font=load("res://assets/fonts/NanumMyeongjo-Regular.ttf")
	var panel=PanelContainer.new();panel.position=Vector2(22,18);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("142923eb");style.border_color=Color("98845b");style.set_border_width_all(1);style.set_content_margin_all(12);panel.add_theme_stylebox_override("panel",style)
	var list=VBoxContainer.new();list.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(list)
	for text in ["공간 시험 · 마당에서 골목으로","WASD / 방향키 이동   ·   F 조사   ·   클릭 선택","휠 확대   ·   중간 버튼 드래그   ·   C 카메라 추적","G 충돌 범위   ·   H 가림 표시   ·   R 시작 위치"]:
		var label=Label.new();label.text=text;label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",15);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;list.add_child(label)
	details=Label.new();details.position=Vector2(24,650);details.add_theme_font_override("font",font);details.add_theme_font_size_override("font_size",17);details.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(details)
	status=Label.new();status.position=Vector2(24,682);status.add_theme_font_override("font",font);status.add_theme_font_size_override("font_size",14);status.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(status)
