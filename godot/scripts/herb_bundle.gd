extends Node2D
## World investigation prop, not a collectible inventory item.
func _draw() -> void:
	draw_rect(Rect2(-28,8,56,8),Color(0,0,0,0.2))
	for i in range(7):
		var p=Vector2(-18+i*5,2-(i%3)*3)
		draw_line(p+Vector2(3,12),p+Vector2(-4,-15),Color("a09159"),3)
		draw_rect(Rect2(p+Vector2(-9,-20),Vector2(8,13)),Color("4b7543"))
		draw_rect(Rect2(p+Vector2(0,-12),Vector2(9,7)),Color("6e9450"))
	draw_line(Vector2(-18,3),Vector2(16,-3),Color("bca97c"),4)
	draw_line(Vector2(16,-3),Vector2(27,6),Color("bca97c"),2)
