extends Node2D
## Only terrain and paving: every building, wall and tree is a separate prop.
var data: Dictionary
var terrain_texture: Texture2D
func _draw() -> void:
	if data.is_empty(): return
	var size=Vector2(data.art_size[0],data.art_size[1])
	draw_rect(Rect2(Vector2.ZERO,size),Color("b69b6c"))
	var rng=RandomNumberGenerator.new();rng.seed=314159
	# Two noise scales break up flat dirt without baking any structures into it.
	var noise=FastNoiseLite.new();noise.seed=513;noise.frequency=.018
	var dirt=Image.create(1024,768,false,Image.FORMAT_RGB8)
	for y in range(768):
		for x in range(1024):
			var grain=noise.get_noise_2d(x,y)*.13+rng.randf_range(-.022,.022)
			dirt.set_pixel(x,y,Color(.70+grain,.59+grain,.40+grain*.8))
	terrain_texture=ImageTexture.create_from_image(dirt)
	draw_texture_rect(terrain_texture,Rect2(Vector2.ZERO,size),false)
	for i in range(35000):
		var p=Vector2(rng.randf_range(0,size.x),rng.randf_range(0,size.y))
		draw_rect(Rect2(p,Vector2(rng.randf_range(.5,2.2),rng.randf_range(.3,1.1))),Color("82764e",rng.randf_range(.06,.22)))
	# A broad river edge, not the arrival route; shipping remains a city district.
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(203,0),Vector2(186,280),Vector2(207,600),Vector2(193,1100),Vector2(205,size.y),Vector2(0,size.y)]),Color("426c70"))
	for y in range(5,1536,12):
		for x in range(3,170,27):draw_line(Vector2(x,y),Vector2(x+10,y-1),Color("82a3a1",.25),.7)
	draw_line(Vector2(213,60),Vector2(213,1480),Color("8b8c70"),9)
	for y in [925,1075,1300]:
		draw_rect(Rect2(85,y,155,32),Color("70543c"))
		for x in range(85,240,9):draw_line(Vector2(x,y),Vector2(x,y+32),Color("a38c61"),1)
	# Courtyards get restrained stone paving; ordinary streets remain packed earth.
	for area in [Rect2(960,125,920,710),Rect2(980,870,250,150),Rect2(1630,1050,265,177)]:
		draw_rect(area,Color("b5ad8b"))
		for y in range(int(area.position.y),int(area.end.y),14):
			draw_line(Vector2(area.position.x,y),Vector2(area.end.x,y),Color("7b806d",.18),.5)
		for x in range(int(area.position.x),int(area.end.x),25):
			draw_line(Vector2(x,area.position.y),Vector2(x,area.end.y),Color("7b806d",.12),.5)
	for road in data.roads:
		var points=PackedVector2Array()
		for p in road.points:points.append(Vector2(p[0],p[1]))
		var stone: bool=road.kind=="stone"
		draw_polyline(points,Color("8f8467") if stone else Color("9d8156"),road.width+7,false)
		draw_polyline(points,Color("c3b991") if stone else Color("c6ad7d"),road.width,false)
	# Practice court markings are paint and worn paving, not blocking objects.
	for center in [Vector2(1270,520),Vector2(1635,520)]:
		draw_rect(Rect2(center-Vector2(62,64),Vector2(124,128)),Color("7c7c65"),false,1)
		draw_arc(center,44,0,TAU,40,Color("6c7662"),1)
		draw_line(center-Vector2(18,0),center+Vector2(18,0),Color("6c7662"),1)
