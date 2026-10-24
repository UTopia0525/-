extends Node2D
func _draw() -> void:
	var points:=PackedVector2Array()
	for i in range(41):
		var angle:=TAU*i/40.0;points.append(Vector2(cos(angle)*25,sin(angle)*8))
	draw_polyline(points,Color("ffdf86"),2.5,true)
	draw_colored_polygon(PackedVector2Array([Vector2(-5,-98),Vector2(5,-98),Vector2(0,-91)]),Color("ffdf86"))
