extends Node2D
var body_height:=132.0
func set_body_height(value: float) -> void:
	if value!=body_height:body_height=value;queue_redraw()
func _draw() -> void:
	var points:=PackedVector2Array()
	for i in range(41):
		var angle:=TAU*i/40.0;points.append(Vector2(cos(angle)*34,sin(angle)*11))
	draw_polyline(points,Color("ffdf86"),2.5,true)
	if body_height>0:draw_colored_polygon(PackedVector2Array([Vector2(-5,-body_height-8),Vector2(5,-body_height-8),Vector2(0,-body_height-1)]),Color("ffdf86"))
