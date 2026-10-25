extends StaticBody2D
## A physical investigation prop, not a collectible item.
const FOOT=Rect2(-38,-14,76,14)
const VISUAL=Rect2(-40,-124,80,124)
func _ready() -> void:
	collision_layer=2;collision_mask=1
	var collider=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=FOOT.size;collider.shape=shape;collider.position=FOOT.get_center();add_child(collider)
func _draw() -> void:
	for x in [-34,28]:draw_rect(Rect2(x,-124,6,124),Color("59402c"))
	draw_rect(Rect2(-40,-118,80,91),Color("725437"))
	draw_rect(Rect2(-36,-114,72,83),Color("b59b6b"))
	for i in range(3):
		var y=-104+i*23
		draw_rect(Rect2(-30,y,60,18),Color("e3d5ad"))
		for j in range(3):draw_line(Vector2(-23+j*17,y+5),Vector2(-14+j*17,y+5),Color("554d3b"),2)
		draw_line(Vector2(-23,y+11),Vector2(23,y+11),Color("81745a"),1)
