extends RefCounted
static func make(data: Dictionary) -> ShaderMaterial:
	var image=Image.create(1536,1024,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(260,80,890,875),Color(0,0,0,.94))
	for road in data.road_centers:
		image.fill_rect(Rect2i(road[0],road[1],road[2],road[3]),Color(.75,0,0,.94))
	image.fill_rect(Rect2i(235,150,40,100),Color(.75,0,0,.94))
	# Retain existing rural thresholds; urban yards are paved below.
	for spec in data.objects:
		if not spec.prefab in ["home","warehouse","inn","government","workshop","martial_hall","farmhouse","shrine"]:continue
		var r: Array=spec.rect
		image.fill_rect(Rect2i(int(r[0]+8),int(r[1]+r[3]-8),int(r[2]-16),14),Color(.55,0,0,.94))
	# City-only paving. Do not extend this mask into the eastern fields or outside gates.
	var inside=Rect2i(275,78,860,877)
	image.fill_rect(inside,Color(0,1,0,1))
	for road in data.road_centers:
		image.fill_rect(Rect2i(road[0],road[1],road[2],road[3]).intersection(inside),Color(1,0,0,1))
	var ink=ShaderMaterial.new();ink.shader=load("res://shaders/changsha_painted.gdshader")
	ink.set_shader_parameter("mask_map",ImageTexture.create_from_image(image))
	ink.set_shader_parameter("materials",load("res://assets/maps/nanjing/market-slice/materials.png"))
	return ink
