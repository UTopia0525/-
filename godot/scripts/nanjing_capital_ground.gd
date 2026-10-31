extends Node2D
## Continuous northern city wall, rural parcels and a preserved straight avenue.
var data: Dictionary
var terrain: Texture2D
func _ready() -> void:
	terrain=load(data.ground_texture)
	var mask=Image.create(1856,1408,false,Image.FORMAT_RGBA8);mask.fill(Color(0,1,0,1))
	for r in [Rect2i(20,375,321,305),Rect2i(20,864,215,150),Rect2i(20,1075,1816,125)]:mask.fill_rect(r,Color.TRANSPARENT)
	for district in data.districts:
		var a=district.rect
		if district.id in ["government","residential"]:mask.fill_rect(Rect2i(a[0],a[1],a[2],a[3]),Color(1,0,0,1))
		if district.id=="inn":mask.fill_rect(Rect2i(a[0],a[1],a[2],a[3]),Color(0,1,0,1))
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
	var rural=Image.create(1856,1408,false,Image.FORMAT_RGBA8);rural.fill(Color.TRANSPARENT)
	for a in data.countryside.regions:rural.fill_rect(Rect2i(a[0],a[1],a[2],a[3]),Color(1,0,0,1))
	for parcel in data.countryside.fields:
		var polygon=PackedVector2Array();var center=Vector2.ZERO
		for point in parcel.points:polygon.append(Vector2(point[0],point[1]));center+=polygon[-1]
		center/=polygon.size();polygon=rounded_parcel(polygon,6);paint_polygon(rural,polygon,Color(0,0,0,1))
		var inner=PackedVector2Array()
		for point in polygon:inner.append(point.move_toward(center,4))
		paint_polygon(rural,inner,Color(1,0,0,1) if parcel.kind=="rice" else Color(0,1,0,1))
	for channel in data.countryside.irrigation:
		paint_path(rural,channel,Color(0,0,0,1),4)
		paint_path(rural,channel,Color(0,0,1,1))
	for o in data.objects:
		if not str(o.id).begins_with("countryside_"):continue
		var r=o.rect
		var plot=PackedVector2Array([Vector2(r[0]-5,r[1]),Vector2(r[0]+r[2]+18,r[1]),Vector2(r[0]+r[2]+18,r[1]+r[3]+25),Vector2(r[0]-6,r[1]+r[3]+25)])
		paint_polygon(rural,rounded_parcel(plot,9),Color(0,0,0,1))
	for road in data.countryside.paths:paint_path(rural,road,Color(0,0,0,1))
	ink.set_shader_parameter("countryside_enabled",true);ink.set_shader_parameter("countryside_mask",ImageTexture.create_from_image(rural));ink.set_shader_parameter("countryside_materials",load("res://assets/maps/nanjing/capital/paddy-materials.png"))
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if terrain:draw_texture_rect(terrain,Rect2(0,0,1856,1408),false)

func paint_polygon(canvas: Image,polygon: PackedVector2Array,color: Color) -> void:
	var lo=polygon[0].y;var hi=lo
	for point in polygon:lo=minf(lo,point.y);hi=maxf(hi,point.y)
	for y in range(maxi(0,floori(lo)),mini(canvas.get_height(),ceili(hi))):
		var crossings=[];var scan=y+.5
		for i in range(polygon.size()):
			var a=polygon[i];var b=polygon[(i+1)%polygon.size()]
			if (a.y>scan)!=(b.y>scan):crossings.append(a.x+(scan-a.y)*(b.x-a.x)/(b.y-a.y))
		crossings.sort()
		for i in range(0,crossings.size()-1,2):
			var x=maxi(0,ceili(crossings[i]));var end=mini(canvas.get_width(),ceili(crossings[i+1]))
			if end>x:canvas.fill_rect(Rect2i(x,y,end-x,1),color)

# Rounded bund corners, not rectangular grass patches pasted onto the field.
func rounded_parcel(points: PackedVector2Array,radius: float) -> PackedVector2Array:
	var result=PackedVector2Array()
	for i in range(points.size()):
		var corner=points[i];var previous=points[(i+points.size()-1)%points.size()];var next=points[(i+1)%points.size()]
		var a=corner.move_toward(previous,minf(radius,corner.distance_to(previous)*.2));var b=corner.move_toward(next,minf(radius,corner.distance_to(next)*.2))
		for step in range(7):
			var t=step/6.0;result.append(a.lerp(corner,t).lerp(corner.lerp(b,t),t))
	return result
func paint_path(canvas: Image,road: Dictionary,color: Color,extra_width: int=0) -> void:
	var width=int(road.width)+extra_width
	for i in range(road.points.size()-1):
		var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var steps=maxi(1,ceili(a.distance_to(b)))
		for j in range(steps+1):
			var p=a.lerp(b,j/float(steps));canvas.fill_rect(Rect2i(int(p.x)-width/2,int(p.y)-width/2,width,width),color)
