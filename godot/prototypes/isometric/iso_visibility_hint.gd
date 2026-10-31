extends Node2D
## HUD-only locator. It never changes depth, physics, or hit testing.
var world
var caption: Label
func setup(value) -> void:
	world=value;caption=Label.new();caption.text="짐꾼 · 가림";caption.add_theme_font_override("font",load("res://assets/fonts/NanumMyeongjo-Regular.ttf"));caption.add_theme_font_size_override("font_size",14)
	caption.add_theme_color_override("font_color",Color("ffdc88"));caption.add_theme_color_override("font_shadow_color",Color("12231d"));caption.add_theme_constant_override("shadow_offset_x",1);caption.add_theme_constant_override("shadow_offset_y",1)
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(caption)
func _process(_delta: float) -> void:
	visible=is_instance_valid(world) and world.show_occlusion_hint and world.actor_occluded
	if not visible:return
	position=world.get_canvas_transform()*world.actor.position
	caption.position=Vector2(-48,-108*world.camera.zoom.y)
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(world):return
	var z=world.camera.zoom.x;var points=PackedVector2Array()
	for i in range(33):points.append(Vector2(cos(i*TAU/32)*22,sin(i*TAU/32)*10)*z)
	draw_polyline(points,Color("ffe1a1"),2)
	draw_circle(Vector2.ZERO,3.5,Color("dcb66c"))
	for y in range(17,75,12):draw_line(Vector2(0,-y*z),Vector2(0,-(y+5)*z),Color(.98,.81,.46,.7),1)
