extends Node2D
var data: Dictionary
var terrain: Texture2D
func _ready() -> void:
	terrain=load("res://assets/maps/wuchang/ground.png")
	var mask=Image.create(2048,1920,false,Image.FORMAT_RGBA8);mask.fill(Color.TRANSPARENT)
	mask.fill_rect(Rect2i(210,80,1730,1360),Color(0,0,0,.95))
	mask.fill_rect(Rect2i(930,85,1000,820),Color(.3,0,0,.95))
	mask.fill_rect(Rect2i(1230,420,420,350),Color(.75,0,0,.95))
	for road in data.roads:
		for i in range(road.points.size()-1):
			var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1])
			var steps=maxi(1,ceili(a.distance_to(b)))
			for step in range(steps+1):
				var p=a.lerp(b,step/float(steps));var width=int(road.width)
				mask.fill_rect(Rect2i(int(p.x)-width/2,int(p.y)-width/2,width,width),Color(.85 if road.kind=="stone" else .4,0,0,.95))
	var inside=Rect2i(249,112,1691,1340)
	mask.fill_rect(inside,Color(0,1,0,1))
	mask.fill_rect(Rect2i(950,130,970,745),Color(1,0,0,1))
	for road in data.roads:
		for i in range(road.points.size()-1):
			var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var steps=maxi(1,ceili(a.distance_to(b)))
			for step in range(steps+1):
				var p=a.lerp(b,step/float(steps));var width=int(road.width)
				mask.fill_rect(Rect2i(int(p.x)-width/2,int(p.y)-width/2,width,width).intersection(inside),Color(1,0,0,1))
	var ink=ShaderMaterial.new();ink.shader=load("res://shaders/wuchang_painted.gdshader")
	ink.set_shader_parameter("mask_map",ImageTexture.create_from_image(mask));ink.set_shader_parameter("materials",load("res://assets/maps/nanjing/market-slice/materials.png"));material=ink
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if terrain:draw_texture_rect(terrain,Rect2(0,0,2048,1920),false)
