extends Node2D
## Material detail and semantic masks use the same reserved plots/roads as gameplay.
var data: Dictionary
var terrain_texture: Texture2D
func _ready() -> void:
	terrain_texture=load(data.ground_texture)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var image=Image.create(1536,1024,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,.86))
	# River and harbour keep the painted shore and bridge art intact.
	for rect in [Rect2i(0,0,181,380),Rect2i(0,564,75,150),Rect2i(0,775,1536,125)]:image.fill_rect(rect,Color(0,0,0,0))
	for district in data.districts:
		var r: Array=district.rect
		var bounds=Rect2i(r[0],r[1],r[2],r[3])
		if district.id in ["government","residential"]:image.fill_rect(bounds,Color(1,0,0,.86))
		if district.id=="inn":image.fill_rect(bounds,Color(0,1,0,.86))
		if district.id=="qinhuai":
			image.fill_rect(Rect2i(75,900,1425,104),Color(0,0,1,.86))
	# Roads are continuous, modest stone lanes, not giant noisy cobblestones.
	for road in data.roads:
		for i in range(road.points.size()-1):
			var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var steps=maxi(1,ceili(a.distance_to(b)))
			for step in range(steps+1):
				var center=a.lerp(b,step/float(steps));var w=int(road.width)
				if center.y>775 and center.y<900:continue
				image.fill_rect(Rect2i(int(center.x)-w/2,int(center.y)-w/2,w,w),Color(1,0,0,.9))
	var ink=ShaderMaterial.new();ink.shader=preload("res://shaders/nanjing_terrain.gdshader")
	ink.set_shader_parameter("material_atlas",load(data.painted_materials));ink.set_shader_parameter("district_mask",ImageTexture.create_from_image(image));material=ink
	# A bounded production sample; all other districts retain their current art.
	if data.has("market_slice"):
		var slice: Dictionary=data.market_slice
		var b: Array=slice.bounds
		ink.set_shader_parameter("market_enabled",true)
		ink.set_shader_parameter("capital_materials",data.get("capital_materials",false))
		ink.set_shader_parameter("market_bounds",Vector4(b[0],b[1],b[2],b[3]))
		ink.set_shader_parameter("market_materials",load(slice.materials))
		var shadows=PackedVector4Array()
		for spec in data.objects:
			if str(spec.id).begins_with("market_shop_"):
				var r: Array=spec.rect
				shadows.append(Vector4(r[0]+12,r[1]+r[3]-13,r[2]-15,12))
		ink.set_shader_parameter("market_shadows",shadows)
func _draw() -> void:
	if terrain_texture:draw_texture_rect(terrain_texture,Rect2(Vector2.ZERO,Vector2(data.art_size[0],data.art_size[1])),false)
