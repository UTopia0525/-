extends StaticBody2D
const Space=preload("res://prototypes/isometric/iso_space.gd")
var footprint: Rect2
var spec: Dictionary
var sprite: Sprite2D
var source_image: Image
var picked=false
var debug_footprint=false
func setup(value: Dictionary,art: Dictionary) -> void:
	spec=value;name=value.id
	var r=value.rect;footprint=Rect2(r[0],r[1],r[2],r[3]);position=Space.project(footprint.get_center())
	collision_layer=1;collision_mask=2
	var shape=CollisionPolygon2D.new();var points=Space.diamond(footprint)
	for i in range(points.size()):points[i]-=position
	shape.polygon=points;add_child(shape)
	if art.has(value.get("art","")):
		var info=art[value.art];var atlas=AtlasTexture.new();atlas.atlas=load(info.texture);atlas.region=Rect2(info.region[0],info.region[1],info.region[2],info.region[3])
		sprite=Sprite2D.new();sprite.centered=false;sprite.texture=atlas;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		var fit=128.0 if spec.kind!="building" else 64.0*(footprint.size.x+footprint.size.y)
		sprite.scale=Vector2.ONE*fit/float(info.get("ground_width",atlas.region.size.x))
		var pivot=Vector2(info.pivot[0],info.pivot[1])
		sprite.position=Space.project(footprint.end)-position-pivot*sprite.scale
		add_child(sprite);source_image=atlas.get_image()
		if source_image.is_compressed():source_image.decompress()
func hit(point: Vector2) -> bool:
	if is_instance_valid(sprite):
		var p=sprite.to_local(point)
		return Rect2(Vector2.ZERO,source_image.get_size()).has_point(p) and source_image.get_pixelv(Vector2i(p)).a>.2
	var local=point-position
	if spec.kind=="tree":
		return Rect2(-7,-70,14,70).has_point(local) or local.distance_to(Vector2(-22,-86))<=34 or local.distance_to(Vector2(18,-92))<=34 or local.distance_to(Vector2(0,-115))<=34
	return local.distance_to(Vector2(0,-24))<=22
func _draw() -> void:
	var foot=Space.diamond(footprint)
	for i in range(foot.size()):foot[i]-=position
	if picked or debug_footprint:
		draw_colored_polygon(foot,Color(.84,.69,.32,.16))
		draw_polyline(foot+PackedVector2Array([foot[0]]),Color("e0be73") if picked else Color("6daeba"),2)
	if not is_instance_valid(sprite):
		if spec.kind=="tree":
			draw_rect(Rect2(-7,-70,14,70),Color("735039"))
			for p in [Vector2(-22,-86),Vector2(18,-92),Vector2(0,-115)]:
				draw_circle(p,34,Color("304a40"));draw_circle(p+Vector2(-6,-7),25,Color("607a50"))
		else:
			paint_ellipse(Vector2.ZERO,Vector2(27,12),Color("23352b"))
			draw_circle(Vector2(0,-24),22,Color("80634a"));paint_ellipse(Vector2(0,-45),Vector2(18,8),Color("393b32"))
func paint_ellipse(center: Vector2,extent: Vector2,color: Color) -> void:
	var points=PackedVector2Array()
	for i in range(24):points.append(center+Vector2(cos(i*TAU/24),sin(i*TAU/24))*extent)
	draw_colored_polygon(points,color)
