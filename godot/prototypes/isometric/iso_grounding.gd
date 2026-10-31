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
	# An open working frontage uses a warmer worn paving patch, not a fence.
	for space in world.data.get("outdoor_spaces",[]):
		var a=space.rect;slab(Rect2(a[0],a[1],a[2],a[3]),Color(1,.94,.81))
	# Flat thresholds: no new collisions, and the open gateway remains unobstructed.
	for plot in world.data.get("plots",[]):
		for a in plot.openings:
			var r=Rect2(a[0],a[1],a[2],a[3])
			slab(r,Color(.87,.85,.79));draw_polyline(Space.diamond(r)+PackedVector2Array([Space.project(r.position)]),Color(.28,.27,.24,.3),1)
	for prop in world.data.props:
		if not prop.has("entrance"):continue
		var e=prop.entrance;var a=e.apron;slab(Rect2(a[0],a[1],a[2],a[3]),Color(1,.99,.96))
		var t=Vector2(e.threshold[0],e.threshold[1]);var step=Rect2(t-Vector2(0,.38),Vector2(.32,.76))
		slab(step,Color(.86,.84,.78));draw_polyline(Space.diamond(step)+PackedVector2Array([Space.project(step.position)]),Color(.24,.25,.22,.45),1)
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
	if world.debug_footprints:
		for space in world.data.get("outdoor_spaces",[]):
			var a=space.rect;var border=Space.diamond(Rect2(a[0],a[1],a[2],a[3]))
			draw_polyline(border+PackedVector2Array([border[0]]),Color("9cd2d6"),2)
		for plot in world.data.get("plots",[]):
			var a=plot.rect;var border=Space.diamond(Rect2(a[0],a[1],a[2],a[3]))
			draw_polyline(border+PackedVector2Array([border[0]]),Color("d3bb7f"),2)
		for prop in world.data.props:
			if not prop.has("entrance"):continue
			var e=prop.entrance;var points=PackedVector2Array()
			for p in e.path:points.append(Space.project(Vector2(p[0],p[1])))
			points.append(Space.project(Vector2(e.threshold[0],e.threshold[1])))
			draw_polyline(points,Color("90ddbb"),3)
			for p in points:draw_circle(p,4,Color("d9edb5"))
			var a=e.apron;var apron=Space.diamond(Rect2(a[0],a[1],a[2],a[3]))
			draw_polyline(apron+PackedVector2Array([apron[0]]),Color("90ddbb"),2)
