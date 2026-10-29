extends StaticBody2D
## One transparent, foot-sorted prop with its own exact physical footprint.
var visual_rect := Rect2()
var collision_rects: Array[Rect2] = []
var definition: Dictionary
var sprite: Sprite2D

func configure(spec: Dictionary, prefab: Dictionary, world_scale: Vector2) -> void:
	definition = spec
	name = str(spec.id)
	set_meta("scenery_id", spec.id)
	set_meta("kind", prefab.kind)
	collision_layer = 2
	collision_mask = 3
	visual_rect = Rect2(Vector2(spec.rect[0], spec.rect[1]) * world_scale, Vector2(spec.rect[2], spec.rect[3]) * world_scale)
	if prefab.get("preserve_aspect",false):
		# Fit the authored art into its reserved plot, aligned at the feet.
		# Never stretch a roof/door or rotate a front sprite to fake a side view.
		var source_size=Vector2(prefab.source[2],prefab.source[3])
		var fit=minf(visual_rect.size.x/source_size.x,visual_rect.size.y/source_size.y)
		var fitted=source_size*fit
		visual_rect=Rect2(Vector2(visual_rect.get_center().x-fitted.x/2,visual_rect.end.y-fitted.y),fitted)
	position = Vector2(visual_rect.get_center().x, visual_rect.position.y if prefab.kind=="bridge" else visual_rect.end.y)
	var atlas := AtlasTexture.new()
	atlas.atlas = load(prefab.texture)
	var src: Array = prefab.source
	atlas.region = Rect2(src[0], src[1], src[2], src[3])
	if prefab.get("contact_shadow",false):
		for band in range(3):
			var shadow=Polygon2D.new();var points=PackedVector2Array()
			var extent=Vector2(visual_rect.size.x*.44,clampf(visual_rect.size.y*.045,9,24))*(1.0-band*.18)
			for step in range(32):points.append(Vector2(cos(step*TAU/32),sin(step*TAU/32))*extent)
			shadow.polygon=points;shadow.color=Color(.12,.09,.06,.055)
			shadow.position=Vector2(visual_rect.get_center().x+visual_rect.size.x*.025,visual_rect.end.y-visual_rect.size.y*.07)-position
			add_child(shadow)
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if prefab.get("smooth_filter",false) else CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = visual_rect.position - position
	sprite.scale = visual_rect.size / atlas.region.size
	# Optional transparent-cell padding preserves the original visible footprint
	# when a higher-resolution atlas uses tightly cropped source rectangles.
	if prefab.has("content_rect"):
		var c: Array=prefab.content_rect
		sprite.position+=Vector2(c[0],c[1])*visual_rect.size
		sprite.scale*=Vector2(c[2],c[3])
	add_child(sprite)
	# Modular long bridges keep stone/posts at one scale: select authored sections
	# instead of squashing the entire long bridge to a shorter crossing.
	if prefab.has("segments"):
		var offset_y=0.0
		for index in range(prefab.segments.size()):
			var part: Array=prefab.segments[index]
			var texture=AtlasTexture.new();texture.atlas=atlas.atlas;texture.region=Rect2(part[0],part[1],part[2],part[3])
			if index==0:sprite.texture=texture
			else:
				var section=Sprite2D.new();section.centered=false;section.texture=texture;section.position=Vector2(0,offset_y);sprite.add_child(section)
			offset_y+=float(part[3])
	for shape in prefab.footprints:
		var bounds := Rect2(visual_rect.position + Vector2(shape[0], shape[1]) * visual_rect.size, Vector2(shape[2], shape[3]) * visual_rect.size)
		collision_rects.append(bounds)
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = bounds.size
		collision.shape = rectangle
		collision.position = bounds.get_center() - position
		add_child(collision)
