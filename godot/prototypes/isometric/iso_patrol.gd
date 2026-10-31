extends RefCounted
const Space=preload("res://prototypes/isometric/iso_space.gd")
## Only an authored polyline, local yielding and retreat. No navigation/path search.
var actor
var route: Array[Vector2]=[]
var index=1
var step=1
var pause=0.0
var blocked=0.0
var detour=Vector2(INF,INF)
var state="왕복"
var arrivals=0
var yields=0
var retreats=0
var last_request=Vector2.ZERO
func setup(value,points: Array) -> void:
	actor=value
	for p in points:route.append(Vector2(p[0],p[1]))
	reset()
func reset() -> void:
	index=1;step=1;pause=.35;blocked=0;detour=Vector2(INF,INF);state="대기";arrivals=0;yields=0;retreats=0
	actor.set_logical(route[0])
func direction(delta: float) -> Vector2:
	last_request=Vector2.ZERO
	if pause>0:
		pause-=delta;state="양보 대기" if blocked>0 else "대기";return last_request
	var target=detour if detour.is_finite() else route[index]
	var offset=target-actor.logical
	if offset.length()<.075:
		if detour.is_finite():
			detour=Vector2(INF,INF);pause=.25;state="양보 대기";return last_request
		arrivals+=1;blocked=0
		if index==route.size()-1 or index==0:step=-step;pause=.55
		index+=step
		offset=route[index]-actor.logical
		if pause>0:return last_request
	var forward=offset.normalized()
	if not detour.is_finite():
		for other in actor.owner_world.moving_actors:
			if other==actor:continue
			var gap=other.logical-actor.logical;var ahead=gap.dot(forward)
			if ahead<-.05 or ahead>.85 or absf(gap.cross(forward))>.38:continue
			# A keyboard-controlled actor has priority; NPC ties use a fixed rank.
			if other.traffic_rank>actor.traffic_rank and other.moving:continue
			_yield(forward);return Vector2.ZERO
	state="옆으로 양보" if detour.is_finite() else "왕복"
	last_request=forward*minf(1.0,offset.length()/(actor.speed*delta))
	return last_request
func _yield(forward: Vector2) -> void:
	yields+=1;blocked=maxf(blocked,.01)
	var side=Vector2(-forward.y,forward.x)
	# Both endpoint and swept path are checked by the same physical foot collider.
	for sign_value in [1,-1]:
		var offset=side*sign_value*.46
		if actor.test_move(actor.global_transform,Space.project(offset)):continue
		var candidate=actor.logical+offset
		if not Rect2(Vector2.ONE*.2,actor.owner_world.map_size-Vector2.ONE*.4).has_point(candidate):continue
		detour=candidate;state="옆으로 양보";return
	# No side room: wait briefly, then walk back to the preceding authored waypoint.
	_retreat();pause=.3
func _retreat() -> void:
	step=-step;index=clampi(index+step,0,route.size()-1)
	if actor.logical.distance_to(route[index])<.12:
		if index==0:step=1
		elif index==route.size()-1:step=-1
		index+=step
	detour=Vector2(INF,INF);blocked=0;retreats+=1;state="뒤로 양보"
func observe(delta: float,travel: float) -> void:
	if last_request==Vector2.ZERO:return
	if travel<actor.speed*delta*.15:blocked+=delta
	else:blocked=0
	if blocked>.55:
		# Back off physically, never teleport or disable a collision shape.
		_retreat();pause=.3
