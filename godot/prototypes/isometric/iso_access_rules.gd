extends RefCounted
const Space=preload("res://prototypes/isometric/iso_space.gd")
const RADIUS=.16
## Applies to every building, including those without an interior or interaction.
static func validate(world) -> Array[String]:
	var errors: Array[String]=validate_plots(world)
	errors.append_array(validate_gates(world))
	errors.append_array(validate_open_spaces(world))
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
		if prop.art_front.distance_to(facing)>.01:errors.append(id+": artwork front and entrance orientation disagree")
		var road=vec(entry.get("road_anchor",[0,0]))
		var road_valid=false
		for index in world.data.public_paving:
			if rect(world.data.paving[index]).has_point(road):road_valid=true
		if not road_valid:errors.append(id+": road anchor is not on a public road")
		if (road-threshold).dot(facing)<.4:errors.append(id+": entrance must face its public road")
		if entry.get("visibility","visible")=="hidden_front":
			if prop.art_view!="rear" or prop.door_pixel.is_finite():errors.append(id+": hidden front requires a genuine rear-view asset")
			if (threshold-prop.footprint.get_center()).dot(facing)<prop.footprint.size.x/2+.15:errors.append(id+": hidden doorway must be on the road-facing side")
		elif not prop.door_pixel.is_finite():errors.append(id+": missing image-space doorway anchor")
		elif world.to_local(prop.sprite.to_global(prop.door_pixel)).distance_to(Space.project(threshold))>5:errors.append(id+": visual door and ground threshold disagree")
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
static func validate_plots(world) -> Array[String]:
	var errors: Array[String]=[];var plots={}
	for plot in world.data.get("plots",[]):plots[plot.id]=plot
	for wall in world.data.walls:
		if not plots.has(wall.get("plot","")):errors.append(wall.id+": orphan wall has no courtyard owner");continue
		var bounds=rect(plots[wall.plot].rect);var r=rect(wall.rect)
		if not bounds.grow(.001).encloses(r):errors.append(wall.id+": wall extends beyond its courtyard")
		if not (is_equal_approx(r.position.x,bounds.position.x) or is_equal_approx(r.end.x,bounds.end.x) or is_equal_approx(r.position.y,bounds.position.y) or is_equal_approx(r.end.y,bounds.end.y)):errors.append(wall.id+": wall does not define a courtyard boundary")
	for prop in world.data.props:
		if prop.kind!="building":continue
		if prop.get("plot","")=="":
			if prop.get("enclosure","open")=="walled":errors.append(prop.id+": walled building requires a courtyard owner")
			continue
		if not plots.has(prop.plot):errors.append(prop.id+": unknown courtyard owner");continue
		var plot=plots[prop.plot];var bounds=rect(plot.rect)
		if plot.building!=prop.id or not bounds.encloses(rect(prop.rect)):errors.append(prop.id+": building outside assigned courtyard")
		if prop.has("entrance") and prop.entrance.has("apron") and not bounds.encloses(rect(prop.entrance.apron)):errors.append(prop.id+": entrance apron outside assigned courtyard")
	for id in plots:
		var plot=plots[id];var bounds=rect(plot.rect);var solid: Array=[]
		for wall in world.data.walls:
			if wall.get("plot","")==id:solid.append(rect(wall.rect).grow(.002))
		for prop in world.data.props:
			if prop.kind=="gate" and prop.get("plot","")==id:
				for r in prop.colliders:solid.append(rect(r).grow(.002))
		for opening in plot.openings:
			var r=rect(opening);solid.append(r.grow(.002))
			if maxf(r.size.x,r.size.y)<RADIUS*2+.2:errors.append(id+": courtyard opening too narrow")
		var corners=[bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]
		for edge in range(4):
			var a=corners[edge];var b=corners[(edge+1)%4];var count=ceili(a.distance_to(b)/.1)
			for step in range(count+1):
				var p=a.lerp(b,step/float(count));var covered=false
				for r in solid:
					if r.has_point(p):covered=true;break
				if not covered:errors.append(id+": courtyard boundary has an undeclared gap");break
	return errors
static func validate_gates(world) -> Array[String]:
	var errors: Array[String]=[]
	for plot in world.data.get("plots",[]):
		for opening in plot.openings:
			var found=false
			for gate in world.props:
				if gate.spec.kind!="gate" or gate.spec.get("plot","")!=plot.id or not gate.spec.has("opening"):continue
				if rect(gate.spec.opening)!=rect(opening):continue
				found=true
				if gate.sprite==null or gate.source_image==null:errors.append(gate.spec.id+": opening requires authored gate artwork")
				if gate.physical_footprints.size()<2:errors.append(gate.spec.id+": gate requires solid posts")
				var r=rect(opening)
				for t in [.2,.5,.8]:
					var p=r.get_center()
					if r.size.x>r.size.y:p.x=lerpf(r.position.x,r.end.x,t)
					else:p.y=lerpf(r.position.y,r.end.y,t)
					if not clear(world,p):errors.append(gate.spec.id+": gate passage is physically blocked")
				var art=world.art.buildings[gate.spec.get("art","gate")]
				if art.has("post_pixels") and gate.physical_footprints.size()==2:
					for i in range(2):
						var pixel=vec(art.post_pixels[i]);var goal=Space.project(gate.physical_footprints[i].get_center())
						if world.to_local(gate.sprite.to_global(pixel)).distance_to(goal)>4:errors.append(gate.spec.id+": painted posts disagree with collision bases")
			if not found:errors.append(plot.id+": declared entrance has no gate artwork")
	return errors
static func validate_open_spaces(world) -> Array[String]:
	var errors: Array[String]=[]
	for space in world.data.get("outdoor_spaces",[]):
		if space.mode!="open":continue
		var bounds=rect(space.rect);var apron=rect(space.apron)
		if not bounds.encloses(apron):errors.append(space.id+": work frontage leaves its open space")
		for wall in world.data.walls:
			if bounds.intersects(rect(wall.rect)):errors.append(space.id+": open workspace must not be enclosed by walls")
		var owner=false
		for prop in world.data.props:
			if prop.id==space.owner:owner=true
		if not owner:errors.append(space.id+": open workspace requires its workstation")
		for x in range(3):
			for y in range(3):
				var inset=apron.grow(-RADIUS);var p=inset.position+inset.size*Vector2(x/2.0,y/2.0)
				if not clear(world,p):errors.append(space.id+": open work frontage is blocked")
		var points: Array=space.path
		for i in range(points.size()-1):
			var a=vec(points[i]);var b=vec(points[i+1]);var count=maxi(1,ceili(a.distance_to(b)/.1))
			for step in range(count+1):
				if not clear(world,a.lerp(b,step/float(count))):errors.append(space.id+": open work frontage route is blocked");break
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
