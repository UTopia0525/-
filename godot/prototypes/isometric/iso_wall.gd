extends "res://prototypes/isometric/iso_prop.gd"
## Exact isometric faces with authored plaster, stone and slate materials.
static var palette: Dictionary={}
var faces: Array[PackedVector2Array]=[]
var ground=PackedVector2Array()
var wall_height=78.0
var along_u=false
func setup(value: Dictionary,art: Dictionary) -> void:
	super.setup(value,{})
	if palette.is_empty():
		var source: Texture2D=load(art.texture)
		for entry in [["plaster",Vector2(0,0)],["tiles",Vector2(1,0)],["stone",Vector2(0,1)]]:
			var atlas=AtlasTexture.new();atlas.atlas=source;atlas.region=Rect2(entry[1]*source.get_size()/2,source.get_size()/2)
			palette[entry[0]]=ImageTexture.create_from_image(atlas.get_image())
	ground=Space.diamond(footprint)
	for i in range(ground.size()):ground[i]-=position
	var top=ground.duplicate()
	for i in range(top.size()):top[i]-=Vector2(0,wall_height)
	faces=[PackedVector2Array([top[1],top[2],ground[2],ground[1]]),PackedVector2Array([top[2],top[3],ground[3],ground[2]]),top]
	along_u=footprint.size.x>footprint.size.y
func hit(point: Vector2) -> bool:
	for face in faces:
		if Geometry2D.is_point_in_polygon(point-position,face):return true
	return false
func band(a: Vector2,b: Vector2,low: float,high: float,material_name: String,tint: Color) -> void:
	var points=PackedVector2Array([a-Vector2(0,high),b-Vector2(0,high),b-Vector2(0,low),a-Vector2(0,low)])
	var uv=PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
	draw_polygon(points,PackedColorArray([tint,tint,tint,tint]),uv,palette[material_name])
func _draw() -> void:
	if faces.is_empty():return
	for i in range(2):
		if ((along_u and i==0) or (not along_u and i==1)) and not spec.get("end_cap",true):continue
		var a=ground[i+1];var b=ground[i+2];var tint=Color(.93,.90,.84) if i==0 else Color(.83,.81,.77)
		band(a,b,0,16,"stone",tint)
		band(a,b,16,wall_height-4,"plaster",tint)
		draw_line(a-Vector2(0,16),b-Vector2(0,16),Color(.28,.27,.24,.4),1)
	var roof=Space.diamond(footprint.grow(.025))
	for i in range(roof.size()):roof[i]-=position+Vector2(0,wall_height)
	var uv=PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]) if along_u else PackedVector2Array([Vector2.ZERO,Vector2(0,1),Vector2.ONE,Vector2(1,0)])
	draw_polygon(roof,PackedColorArray([Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE]),uv,palette.tiles)
	if along_u:draw_line(roof[2],roof[3],Color("44484a"),2)
	else:draw_line(roof[1],roof[2],Color("44484a"),2)
	if picked or debug_footprint:draw_polyline(ground+PackedVector2Array([ground[0]]),Color("6daeba"),2)
