extends "res://prototypes/isometric/iso_prop.gd"
## Short independent wall sections share one height; no stretched facade sprites.
var faces: Array[PackedVector2Array]=[]
var masonry: AtlasTexture
var roof_ink: AtlasTexture
var wall_height=78.0
func setup(value: Dictionary,art: Dictionary) -> void:
	super.setup(value,art)
	var material_texture=load("res://assets/maps/nanjing/market-slice/materials.png")
	masonry=AtlasTexture.new();masonry.atlas=material_texture;masonry.region=Rect2(Vector2(0,material_texture.get_height()/2.0),material_texture.get_size()/2)
	roof_ink=AtlasTexture.new();roof_ink.atlas=material_texture;roof_ink.region=Rect2(Vector2.ZERO,material_texture.get_size()/2)
	var ground=Space.diamond(footprint)
	for i in range(ground.size()):ground[i]-=position
	var top=ground.duplicate()
	for i in range(top.size()):top[i]-=Vector2(0,wall_height)
	faces=[PackedVector2Array([top[1],top[2],ground[2],ground[1]]),PackedVector2Array([top[2],top[3],ground[3],ground[2]]),top]
func hit(point: Vector2) -> bool:
	for face in faces:
		if Geometry2D.is_point_in_polygon(point-position,face):return true
	return false
func _draw() -> void:
	if faces.is_empty():return
	var uv=PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
	for i in range(2):
		var tint=Color(.84,.86,.84) if i==0 else Color(.67,.71,.69)
		draw_polygon(faces[i],PackedColorArray([tint,tint,tint,tint]),uv,masonry)
		var base=faces[i];draw_line(base[2],base[3],Color("54605a"),6)
	var top=faces[2];var roof=top.duplicate()
	for i in range(roof.size()):roof[i]+=(roof[i]).normalized()*4
	draw_polygon(roof,PackedColorArray([Color("71817b"),Color("71817b"),Color("71817b"),Color("71817b")]),uv,roof_ink)
	draw_polyline(roof+PackedVector2Array([roof[0]]),Color("3a4f4a"),3)
	var along_u=footprint.size.x>footprint.size.y
	var a=roof[0];var b=roof[1] if along_u else roof[3]
	var side=roof[3]-roof[0] if along_u else roof[1]-roof[0]
	var tiles=maxi(2,ceili(a.distance_to(b)/9))
	for i in range(tiles+1):
		var p=a.lerp(b,i/float(tiles));draw_line(p,p+side,Color(.2,.28,.27,.65),2)
	if picked or debug_footprint:
		var ground=Space.diamond(footprint)
		for i in range(ground.size()):ground[i]-=position
		draw_polyline(ground+PackedVector2Array([ground[0]]),Color("6daeba"),2)
