extends Node2D
var body_height:=132.0
func set_body_height(value: float) -> void:
	if value!=body_height:body_height=value;queue_redraw()
func _draw() -> void:
	var points:=PackedVector2Array()
	for i in range(41):
		var angle:=TAU*i/40.0;points.append(Vector2(cos(angle)*34,sin(angle)*11))
	draw_colored_polygon(points,Color("f1ce7025"))
	draw_polyline(points,Color("10221df2"),7.0,true)
	draw_polyline(points,Color("ffe5a3"),3.5,true)
	# Short brackets stay legible beside feet and against pale roads.
	for side in [-1.0,1.0]:
		var start=Vector2(side*37,0);var end=Vector2(side*47,0)
		draw_line(start,end,Color("10221df2"),6.0,true)
		draw_line(start,end,Color("ffe5a3"),2.5,true)
	if body_height>0:draw_colored_polygon(PackedVector2Array([Vector2(-5,-body_height-8),Vector2(5,-body_height-8),Vector2(0,-body_height-1)]),Color("ffdf86"))
