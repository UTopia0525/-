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
	position = Vector2(visual_rect.get_center().x, visual_rect.end.y)
	var atlas := AtlasTexture.new()
	atlas.atlas = load(prefab.texture)
	var src: Array = prefab.source
	atlas.region = Rect2(src[0], src[1], src[2], src[3])
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = visual_rect.position - position
	sprite.scale = visual_rect.size / atlas.region.size
	# Optional transparent-cell padding preserves the original visible footprint
	# when a higher-resolution atlas uses tightly cropped source rectangles.
	if prefab.has("content_rect"):
		var c: Array=prefab.content_rect
		sprite.position+=Vector2(c[0],c[1])*visual_rect.size
		sprite.scale*=Vector2(c[2],c[3])
	add_child(sprite)
	for shape in prefab.footprints:
		var bounds := Rect2(visual_rect.position + Vector2(shape[0], shape[1]) * visual_rect.size, Vector2(shape[2], shape[3]) * visual_rect.size)
		collision_rects.append(bounds)
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = bounds.size
		collision.shape = rectangle
		collision.position = bounds.get_center() - position
		add_child(collision)
