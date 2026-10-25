extends StaticBody2D
const FOOT=Rect2(-38,-14,76,14)
const VISUAL=Rect2(-40,-124,80,124)
var kind:="door"
func _ready() -> void:
	collision_layer=2;collision_mask=1
	var c=CollisionShape2D.new();var s=RectangleShape2D.new();s.size=FOOT.size;c.shape=s;c.position=FOOT.get_center();add_child(c)
func _draw() -> void:
	if kind=="door":
		draw_rect(Rect2(-32,-114,64,114),Color("715039"))
		for x in range(-28,32,12):draw_line(Vector2(x,-108),Vector2(x,-4),Color("4b382d"),2)
		for y in [-94,-28]:draw_rect(Rect2(-32,y,64,7),Color("a37b4e"))
		draw_line(Vector2(-30,-100),Vector2(30,-35),Color("c0ac79"),4)
		draw_rect(Rect2(-22,-85,44,22),Color("342b23"))
	else:
		for i in range(4):
			draw_rect(Rect2(-38+i%2*5,-16-i*13,70,11),Color("75583b") if kind=="beam" else Color("a38558"))
		for x in [-22,24]:draw_line(Vector2(x,-59),Vector2(x,-1),Color("c0ac79"),3)
