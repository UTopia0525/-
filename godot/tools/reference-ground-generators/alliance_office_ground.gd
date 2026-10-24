extends Node2D
var data: Dictionary
var atlas_mode=false
func _draw() -> void:
	if atlas_mode:
		for i in range(6):
			draw_set_transform(Vector2((i%3)*128,(i/3)*100))
			furniture(i)
		return
	draw_rect(Rect2(0,0,512,360),Color("1c2426"))
	draw_rect(Rect2(20,50,472,300),Color("806344"))
	for y in range(70,342,16):
		for x in range(26,486,46):
			var offset=23 if (y/16)%2 else 0
			draw_rect(Rect2(x+offset,y,mini(45,486-x-offset),15),Color("927450") if (x+y)%3 else Color("886b49"))
			if x+offset+37<486:draw_line(Vector2(x+offset+3,y+10),Vector2(x+offset+37,y+10),Color("796042"),.6)
	# Rear wall and lattice windows: floor stays free of baked furniture.
	draw_rect(Rect2(20,16,472,54),Color("cfb78b"))
	draw_rect(Rect2(20,61,472,9),Color("593e30"))
	for x in [32,164,336,468]:draw_rect(Rect2(x,16,10,54),Color("703e30"))
	for x in [58,364]:
		draw_rect(Rect2(x,27,88,27),Color("414e49"))
		for k in range(0,89,11):draw_line(Vector2(x+k,27),Vector2(x+k,54),Color("9b7750"),2)
		for y in [33,42,51]:draw_line(Vector2(x,y),Vector2(x+88,y),Color("9b7750"),2)
	draw_rect(Rect2(208,24,96,27),Color("43352b"))
	draw_string(preload("res://scripts/ui.gd").BRUSH_FONT,Vector2(224,44),"總務堂",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e0c58d"))
	for x in [20,486]:draw_rect(Rect2(x,65,6,285),Color("513c31"))
	# Muted central runner leads from the door toward the steward's desk.
	draw_rect(Rect2(225,178,62,141),Color("695951"))
	for x in [227,283]:draw_line(Vector2(x,180),Vector2(x,317),Color("b49b68"),1)
	for r in [Rect2(20,342,201,8),Rect2(291,342,201,8)]:draw_rect(r,Color("513c31"))
	draw_rect(Rect2(221,341,70,4),Color("c1a675"))
func furniture(kind: int) -> void:
	var wood=Color("63422f");var edge=Color("bd8b50")
	match kind:
		0:
			for x in [16,105]:draw_rect(Rect2(x,59,7,35),wood)
			draw_rect(Rect2(8,43,112,35),wood);draw_rect(Rect2(6,39,116,25),edge);draw_rect(Rect2(10,42,108,18),Color("845936"))
			for x in [22,41,60]:draw_rect(Rect2(x,44,15,10),Color("ddd0aa"));draw_line(Vector2(x+2,47),Vector2(x+12,47),wood,1)
			draw_rect(Rect2(87,45,14,7),Color("252b2b"));draw_line(Vector2(96,41),Vector2(104,30),edge,2)
		1:
			draw_rect(Rect2(9,5,110,91),wood)
			for y in [12,39,66]:
				draw_rect(Rect2(16,y,96,23),Color("322e29"))
				for x in range(20,108,13):draw_rect(Rect2(x,y+3,9,19),Color("b7a17e") if x%3 else Color("627677"));draw_line(Vector2(x,y+8),Vector2(x+8,y+8),wood,1)
			for y in [10,37,64,91]:draw_rect(Rect2(8,y,112,4),edge)
		2:
			for x in [14,105]:draw_rect(Rect2(x,64,8,31),wood)
			draw_rect(Rect2(8,45,112,10),wood);draw_rect(Rect2(8,63,112,12),edge)
			for x in range(12,118,22):draw_rect(Rect2(x,49,4,17),wood)
		3:
			for x in [6,46,86]:
				draw_rect(Rect2(x,7,36,86),wood);draw_rect(Rect2(x+4,12,28,68),Color("bca77e"))
				for y in range(22,69,12):draw_line(Vector2(x+9,y),Vector2(x+25,y-5),Color("667463"),2)
		4:
			draw_rect(Rect2(29,79,70,17),Color("787975"));draw_rect(Rect2(42,5,44,80),Color("703f32"));draw_rect(Rect2(45,5,5,74),Color("9a5d3c"))
		5:
			draw_rect(Rect2(55,30,18,65),wood);draw_circle(Vector2(64,26),20,Color("b47b42"));draw_circle(Vector2(64,26),12,Color("edcc84"))
