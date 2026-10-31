extends RefCounted
const Space=preload("res://prototypes/isometric/iso_space.gd")
const RADIUS=.16
## Applies to every building, including those without an interior or interaction.
static func validate(world) -> Array[String]:
	var errors: Array[String]=[]
	for prop in world.props:
		if prop.spec.kind!="building":continue
		var id: String=prop.spec.id
		if not prop.spec.has("entrance"):
			errors.append(id+": missing entrance even though interior may be absent");continue
		var entry: Dictionary=prop.spec.entrance
		for key in ["threshold","facing","approach","apron","path","kind"]:
			if not entry.has(key):errors.append(id+": missing "+key)
		if not errors.is_empty() and not entry.has_all(["threshold","facing","approach","apron","path","kind"]):continue
		var threshold=vec(entry.threshold);var approach=vec(entry.approach);var facing=vec(entry.facing)
		if not prop.door_pixel.is_finite():errors.append(id+": missing image-space doorway anchor")
		elif world.to_local(prop.sprite.to_global(prop.door_pixel)).distance_to(Space.project(threshold))>5:
			errors.append(id+": visual door and ground threshold disagree")
		if facing.length()<.9 or (approach-threshold).dot(facing.normalized())<.25 or absf((approach-threshold).cross(facing.normalized()))>.10:
			errors.append(id+": approach is not in front of the doorway")
		var a=entry.apron;var apron=Rect2(a[0],a[1],a[2],a[3])
		if minf(apron.size.x,apron.size.y)<.65 or not apron.has_point(approach) or not apron.has_point(threshold):errors.append(id+": apron is too small or detached")
		var inset=apron.grow(-RADIUS)
		for x in range(5):
			for y in range(5):
				var p=inset.position+inset.size*Vector2(x/4.0,y/4.0)
				if not clear(world,p):errors.append(id+": occupied apron");break
		var path: Array=entry.path
		if path.is_empty():errors.append(id+": missing public approach path");continue
		var public=false
		for index in world.data.public_paving:
			if rect(world.data.paving[index]).has_point(vec(path[0])):public=true
		if not public:errors.append(id+": path does not start on a public road")
		if vec(path[-1]).distance_to(approach)>.02:errors.append(id+": path does not end at approach")
		var points=path.duplicate(true);points.append(entry.threshold)
		for i in range(points.size()-1):
			var start=vec(points[i]);var end=vec(points[i+1]);var count=maxi(1,ceili(start.distance_to(end)/.10))
			for step in range(count+1):
				var p=start.lerp(end,step/float(count))
				if not clear(world,p):errors.append(id+": blocked route from road to door");break
				var paved=apron.has_point(p)
				for paving in world.data.paving:
					if rect(paving).has_point(p):paved=true;break
				if not paved:errors.append(id+": visible route paving is disconnected");break
	return errors
static func vec(value: Array) -> Vector2:return Vector2(value[0],value[1])
static func rect(a: Array) -> Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func clear(world,p: Vector2) -> bool:
	var size=vec(world.data.size)
	if not Rect2(Vector2.ONE*RADIUS,size-Vector2.ONE*2*RADIUS).has_point(p):return false
	var shape=ConvexPolygonShape2D.new();var vertices=PackedVector2Array()
	for i in range(20):vertices.append(Space.project(Vector2(cos(i*TAU/20),sin(i*TAU/20))*RADIUS))
	shape.points=vertices
	var query=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.transform=Transform2D(0,world.to_global(Space.project(p)));query.collision_mask=1;query.collide_with_areas=false
	return world.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
