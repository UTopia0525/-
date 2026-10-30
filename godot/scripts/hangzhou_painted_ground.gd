extends Node2D
## Ground-only material treatment; buildings retain their own alpha/physics/Y sorting.
var data: Dictionary
var terrain: Texture2D
func _ready() -> void:
	terrain=load(data.ground_texture)
	var mask=Image.create(1760,1280,false,Image.FORMAT_RGBA8);mask.fill(Color.TRANSPARENT)
	# Keep the authored lake, quay edge and northern water visible.
	mask.fill_rect(Rect2i(433,0,1327,1280),Color(0,0,0,1))
	mask.fill_rect(Rect2i(495,0,540,430),Color(.2,.8,0,1))
	mask.fill_rect(Rect2i(495,485,540,345),Color(.35,.3,0,1))
	mask.fill_rect(Rect2i(1120,265,520,565),Color(.4,0,0,1))
	mask.fill_rect(Rect2i(1120,895,595,360),Color(0,0,1,1))
	mask.fill_rect(Rect2i(1490,60,230,145),Color(0,0,.5,1))
	for road in data.roads:
		for i in range(road.points.size()-1):
			var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var steps=maxi(1,ceili(a.distance_to(b)))
			for j in range(steps+1):
				var p=a.lerp(b,j/float(steps));var width=int(road.width)
				mask.fill_rect(Rect2i(int(p.x)-width/2,int(p.y)-width/2,width,width),Color(.9,0,0,1))
	mask.fill_rect(Rect2i(1490,0,270,60),Color.TRANSPARENT)
	var ink=ShaderMaterial.new();ink.shader=load("res://shaders/hangzhou_painted.gdshader")
	ink.set_shader_parameter("mask_map",ImageTexture.create_from_image(mask));ink.set_shader_parameter("materials",load("res://assets/maps/nanjing/market-slice/materials.png"))
	material=ink;texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if terrain:draw_texture_rect(terrain,Rect2(0,0,1760,1280),false)
