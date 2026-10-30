extends Node2D
var data: Dictionary
var terrain: Texture2D
func _ready() -> void:
	terrain=load(data.ground_texture)
	var mask=Image.create(1536,1024,false,Image.FORMAT_RGBA8);mask.fill(Color.TRANSPARENT)
	mask.fill_rect(Rect2i(24,24,660,976),Color(0,0,0,.94))
	mask.fill_rect(Rect2i(870,24,642,976),Color(0,0,0,.94))
	for road in data.roads:
		for i in range(road.points.size()-1):
			var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var steps=maxi(1,ceili(a.distance_to(b)))
			for j in range(steps+1):
				var p=a.lerp(b,j/float(steps));var width=int(road.width)
				mask.fill_rect(Rect2i(int(p.x)-width/2,int(p.y)-width/2,width,width),Color(.9,0,0,.94))
	mask.fill_rect(Rect2i(175,805,510,195),Color(0,0,1,.96))
	for courtyard in [Rect2i(330,805,80,195),Rect2i(175,895,170,95),Rect2i(420,895,195,95)]:mask.fill_rect(courtyard,Color(0,0,0,.94))
	mask.fill_rect(Rect2i(930,825,160,75),Color(0,1,0,.94))
	# Preserve the authored canal edges and the exact three navigable crossings.
	mask.fill_rect(Rect2i(685,0,185,1024),Color.TRANSPARENT)
	var ink=ShaderMaterial.new();ink.shader=load("res://shaders/suzhou_painted.gdshader")
	ink.set_shader_parameter("mask_map",ImageTexture.create_from_image(mask));ink.set_shader_parameter("materials",load("res://assets/maps/nanjing/market-slice/materials.png"));ink.set_shader_parameter("rice_field",load("res://assets/maps/suzhou/painted/rice-field.png"));material=ink;texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if terrain:draw_texture_rect(terrain,Rect2(0,0,1536,1024),false)
