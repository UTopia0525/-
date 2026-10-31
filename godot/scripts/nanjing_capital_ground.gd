extends Node2D
## Expanded capital: north palace forecourt, a straight avenue, preserved river banks.
var data: Dictionary
var terrain: Texture2D
func _ready() -> void:
	terrain=load(data.ground_texture)
	var mask=Image.create(1856,1408,false,Image.FORMAT_RGBA8);mask.fill(Color(0,0,0,1))
	for r in [Rect2i(20,375,321,305),Rect2i(20,864,215,150),Rect2i(20,1075,1816,125)]:mask.fill_rect(r,Color.TRANSPARENT)
	for district in data.districts:
		var a=district.rect
		if district.id in ["government","residential","imperial"]:mask.fill_rect(Rect2i(a[0],a[1],a[2],a[3]),Color(1,0,0,1))
		if district.id=="inn":mask.fill_rect(Rect2i(a[0],a[1],a[2],a[3]),Color(0,1,0,1))
	mask.fill_rect(Rect2i(850,300,100,110),Color(0,1,0,1))
	for road in data.roads:
		for i in range(road.points.size()-1):
			var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var steps=maxi(1,ceili(a.distance_to(b)))
			for j in range(steps+1):
				var p=a.lerp(b,j/float(steps));var width=int(road.width)
				if p.y>1075 and p.y<1200:continue
				mask.fill_rect(Rect2i(int(p.x)-width/2,int(p.y)-width/2,width,width),Color(1,0,0,1))
	var ink=ShaderMaterial.new();ink.shader=load("res://shaders/nanjing_terrain.gdshader")
	ink.set_shader_parameter("material_atlas",load(data.painted_materials));ink.set_shader_parameter("district_mask",ImageTexture.create_from_image(mask))
	ink.set_shader_parameter("expanded_layout",true);ink.set_shader_parameter("original_terrain",terrain);ink.set_shader_parameter("art_extent",Vector2(1856,1408));ink.set_shader_parameter("layout_origin",Vector2(160,300))
	ink.set_shader_parameter("world_extent",Vector2(7424,5632));ink.set_shader_parameter("capital_materials",true);ink.set_shader_parameter("market_materials",load(data.market_slice.materials));material=ink
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if terrain:draw_texture_rect(terrain,Rect2(0,0,1856,1408),false)
