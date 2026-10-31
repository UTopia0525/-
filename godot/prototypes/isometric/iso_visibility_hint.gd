extends Node2D
## HUD-only locator. It never changes depth, physics, or hit testing.
var world
var captions: Dictionary={}
var label_rects: Array[Rect2]=[]
var markers: Array=[]
func setup(value) -> void:
	world=value
	for person in world.moving_actors:
		var caption=Label.new();caption.text=person.display_name+" · 가림"
		caption.add_theme_font_override("font",load("res://assets/fonts/NanumMyeongjo-Regular.ttf"));caption.add_theme_font_size_override("font_size",14)
		caption.add_theme_color_override("font_color",Color("ffdc88") if person.interactive else Color("a9dde5"));caption.add_theme_color_override("font_shadow_color",Color("12231d"));caption.add_theme_constant_override("shadow_offset_x",1);caption.add_theme_constant_override("shadow_offset_y",1)
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(caption);captions[person]=caption
func _process(_delta: float) -> void:
	refresh()
func refresh() -> void:
	label_rects.clear();markers.clear()
	visible=is_instance_valid(world) and world.show_occlusion_hint
	for person in captions:
		var caption: Label=captions[person];caption.visible=visible and person.occluded
		if not caption.visible:continue
		var foot=world.get_canvas_transform()*person.position
		var extent=caption.get_combined_minimum_size()+Vector2(8,4)
		var desired=foot-Vector2(extent.x/2,108*world.camera.zoom.y)
		var rect=_place_label(desired,extent)
		caption.position=rect.position+Vector2(4,2);label_rects.append(rect)
		markers.append({"foot":foot,"rect":rect,"player":person.interactive})
	visible=visible and not markers.is_empty()
	queue_redraw()
func _place_label(desired: Vector2,extent: Vector2) -> Rect2:
	var viewport_size=get_viewport_rect().size
	var offsets=[Vector2.ZERO]
	for row in range(1,10):
		offsets.append(Vector2(0,-row*(extent.y+4)))
		offsets.append(Vector2((extent.x+8)*((row+1)/2),0))
		offsets.append(Vector2(-(extent.x+8)*((row+1)/2),0))
	for offset in offsets:
		var p=(desired+offset).clamp(Vector2(8,8),viewport_size-extent-Vector2(8,66))
		var candidate=Rect2(p,extent);var clear=true
		# Keep the existing instruction panel and bottom status unobstructed as well.
		if candidate.intersects(Rect2(16,12,456,110)):continue
		for used in label_rects:
			if candidate.grow(3).intersects(used):clear=false;break
		if clear:return candidate
	return Rect2(desired.clamp(Vector2(8,126),viewport_size-extent-Vector2(8,66)),extent)
func _draw() -> void:
	if not is_instance_valid(world):return
	var z=world.camera.zoom.x
	for marker in markers:
		var foot: Vector2=marker.foot;var rect: Rect2=marker.rect
		var color=Color("ffe1a1") if marker.player else Color("a9dde5")
		var points=PackedVector2Array()
		for i in range(33):points.append(foot+Vector2(cos(i*TAU/32)*22,sin(i*TAU/32)*10)*z)
		draw_polyline(points,color,2);draw_circle(foot,3.0,color)
		var end=Vector2(rect.get_center().x,rect.end.y)
		draw_dashed_line(foot-Vector2(0,14*z),end,color*.85,1,5)
		draw_style_box(_backdrop(),rect)
func _backdrop() -> StyleBoxFlat:
	var box=StyleBoxFlat.new();box.bg_color=Color(.055,.09,.08,.85);box.set_corner_radius_all(3);return box
