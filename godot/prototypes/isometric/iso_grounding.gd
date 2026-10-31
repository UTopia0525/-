extends Node2D
const Space=preload("res://prototypes/isometric/iso_space.gd")
## Ground-only decoration. Always before the complete depth-sorted actor layer.
const CAST_DIRECTION=Vector2(1,.65)
var world
var stone: Texture2D
func setup(value) -> void:
	world=value;name="GroundContact";texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	stone=ImageTexture.create_from_image(world.texture_stone.get_image())
func slab(rect: Rect2,tint: Color) -> void:
	var points=Space.diamond(rect)
	var uv=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	for i in range(uv.size()):uv[i]*=.42
	draw_polygon(points,PackedColorArray([tint,tint,tint,tint]),uv,stone)
func _draw() -> void:
	if not is_instance_valid(world):return
	# Continuous paving rectangles preserve the authored widths instead of tile-centre steps.
	for a in world.data.paving:
		var rect=Rect2(a[0],a[1],a[2],a[3])
		for width in [8,5,2]:draw_polyline(Space.diamond(rect)+PackedVector2Array([Space.project(rect.position)]),Color(.31,.26,.18,.035),width)
		slab(rect,Color(.98,.97,.94))
	# Flat thresholds: no new collisions, and the open gateway remains unobstructed.
	for r in [Rect2(4.15,6.25,1.15,.48),Rect2(4.22,3.8,.55,.65),Rect2(5.9,4.7,.65,.38)]:
		slab(r,Color(.87,.85,.79));draw_polyline(Space.diamond(r)+PackedVector2Array([Space.project(r.position)]),Color(.28,.27,.24,.3),1)
	for prop in world.props:
		var kind: String=prop.spec.kind
		var length=29.0 if kind=="building" else 18.0 if kind in ["gate","tree"] else 11.0 if kind=="wall" else 7.0
		var base=Space.diamond(prop.footprint)
		# Soft, consistent ground projections. No shadow enters the actor draw layer.
		for band in range(4,0,-1):
			var points=Space.diamond(prop.footprint.grow(.008*band))
			for p in base:points.append(p+CAST_DIRECTION*(length+band*1.5))
			draw_colored_polygon(Geometry2D.convex_hull(points),Color(.16,.17,.14,.028))
		for physical in prop.physical_footprints:
			var contact=Space.diamond(physical.grow(.02))
			draw_polyline(contact+PackedVector2Array([contact[0]]),Color(.18,.18,.14,.22),3)
