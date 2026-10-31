extends Polygon2D
## Original artwork skinned to hips/knees/feet and shoulders/elbows/hands.
## Eight gait landmarks, continuously interpolated; root/physics/scale stay fixed.
var source: Image
var original=PackedVector2Array()
var triangles: Array[PackedInt32Array]=[]
var bindings: Array=[]
var hit_rows: Array=[]
var facing="front"
var gait=0.0
var tex_size=Vector2.ZERO
var atlas_reference: Texture2D
var render_textures: Dictionary={}
var profile: Dictionary
var rest: Dictionary
var joints: Dictionary={}
var transforms: Dictionary={}
var body_offset=Vector2.ZERO
func configure(value: Dictionary) -> void:profile=value
func point(value: Array) -> Vector2:return Vector2(value[0]*tex_size.x-tex_size.x/2,value[1]*tex_size.y)
func pose(atlas: Texture2D,pixels: Image,key: String,phase: float) -> void:
	facing=key;gait=phase
	if atlas_reference!=atlas:
		atlas_reference=atlas
		if not render_textures.has(atlas):render_textures[atlas]=ImageTexture.create_from_image(pixels)
		texture=render_textures[atlas];source=pixels;tex_size=texture.get_size();rest=profile.skeleton[key];_build_grid()
	_solve_joints()
	var vertices=original.duplicate()
	for i in range(vertices.size()):
		var p=original[i];var bind=bindings[i];var result=p+body_offset
		if bind.kind!="body":
			var bones=transforms[bind.kind+str(bind.side)]
			var moved=(bones[0]*p).lerp(bones[1]*p,bind.lower)
			result=result.lerp(moved,bind.weight)
		vertices[i]=result
	polygon=vertices;_index_hits()
func _build_grid() -> void:
	original.clear();triangles.clear();bindings.clear();var coords=PackedVector2Array()
	var cols=24;var rows=32
	for y in range(rows+1):
		for x in range(cols+1):
			var normalized=Vector2(x/float(cols),y/float(rows));var uv_point=normalized*tex_size
			coords.append(uv_point);original.append(uv_point-Vector2(tex_size.x/2,0));bindings.append(_binding(normalized))
	for y in range(rows):
		for x in range(cols):
			var a=y*(cols+1)+x;var b=a+1;var c=a+cols+1;var d=c+1
			triangles.append(PackedInt32Array([a,b,d]));triangles.append(PackedInt32Array([a,d,c]))
	uv=coords;polygons=triangles
func _binding(p: Vector2) -> Dictionary:
	var result={"kind":"body","side":0,"lower":0.0,"weight":0.0}
	for side in range(2):
		var shoulder=rest.shoulders[side];var edge=float(rest.arm_inner[side])
		var lateral=clampf((edge-p.x)/.075 if side==0 else (p.x-edge)/.075,0,1)
		if p.y>=shoulder[1] and p.y<rest.arm_bottom and lateral>0:
			result.kind="arm";result.side=side;result.weight=lateral*smoothstep(shoulder[1],shoulder[1]+.08,p.y)
			result.lower=smoothstep(rest.elbows[side][1]-.025,rest.elbows[side][1]+.025,p.y);return result
	var side=0 if p.x<.5 else 1
	var hip_y=float(rest.hips[side][1]);var knee_y=float(rest.knees[side][1])
	if p.y>hip_y-.015:
		result.kind="leg";result.side=side;result.weight=smoothstep(hip_y-.015,hip_y+.07,p.y)
		result.lower=smoothstep(knee_y-.018,knee_y+.018,p.y)
	return result
func bone_map(a: Vector2,b: Vector2,da: Vector2,db: Vector2) -> Transform2D:
	var result=Transform2D((db-da).angle()-(b-a).angle(),Vector2.ZERO)
	result.origin=da-result.basis_xform(a);return result
func _solve_joints() -> void:
	var h=tex_size.y;var forward=Vector2(1,.466667) if facing=="front" else Vector2(-1,-.466667)
	var stride=float(profile.stride)*h;var lift=float(profile.lift)*h
	body_offset=Vector2(0,-float(profile.bob)*h*(1-cos(gait*2))*.5)
	joints={"legs":[],"arms":[]};transforms.clear()
	var feet: Array=[]
	for side in range(2):
		var t=fposmod(gait+side*PI,TAU);var hip=point(rest.hips[side]);var knee=point(rest.knees[side]);var foot=point(rest.feet[side])
		var goal=foot+forward*(stride*cos(t))+Vector2(0,-maxf(0,-sin(t))*lift)
		feet.append(goal)
		if t<=PI:
			var reach=(hip.distance_to(knee)+knee.distance_to(foot))*.998
			var dx=goal.x-hip.x;var vertical=sqrt(maxf(0,reach*reach-dx*dx))
			body_offset.y=maxf(body_offset.y,goal.y-vertical-hip.y)
	for side in range(2):
		var hip=point(rest.hips[side]);var knee=point(rest.knees[side]);var foot=point(rest.feet[side]);var root=hip+body_offset
		var l1=hip.distance_to(knee);var l2=knee.distance_to(foot);var direction: Vector2=feet[side]-root
		var distance=clampf(direction.length(),absf(l1-l2)+.01,l1+l2-.01);direction=direction.normalized()
		var goal=root+direction*distance;var along=(l1*l1-l2*l2+distance*distance)/(2*distance)
		var height=sqrt(maxf(0,l1*l1-along*along));var normal=direction.orthogonal()
		var sign_value=1 if normal.dot(forward)>0 else -1
		var bent=root+direction*along+normal*height*sign_value
		joints.legs.append({"hip":root,"knee":bent,"foot":goal,"stance":fposmod(gait+side*PI,TAU)<=PI})
		transforms["leg"+str(side)]=[bone_map(hip,knee,root,bent),bone_map(knee,foot,bent,goal)]
		var shoulder=point(rest.shoulders[side]);var elbow=point(rest.elbows[side]);var hand=point(rest.hands[side])
		var angle=float(profile.arm_swing)*cos(gait+side*PI)*(1 if facing=="front" else -1)
		var at=shoulder+body_offset;var middle=at+(elbow-shoulder).rotated(angle)
		var end=middle+(hand-elbow).rotated(angle*.8)
		joints.arms.append({"shoulder":at,"elbow":middle,"hand":end})
		transforms["arm"+str(side)]=[bone_map(shoulder,elbow,at,middle),bone_map(elbow,hand,middle,end)]
func _index_hits() -> void:
	hit_rows.clear()
	for i in range(36):hit_rows.append([])
	for tri in triangles:
		var low=minf(polygon[tri[0]].y,minf(polygon[tri[1]].y,polygon[tri[2]].y))
		var high=maxf(polygon[tri[0]].y,maxf(polygon[tri[1]].y,polygon[tri[2]].y))
		for row in range(_hit_row(low),_hit_row(high)+1):hit_rows[row].append(tri)
func _hit_row(y: float) -> int:return clampi(int((y/tex_size.y+.12)/1.24*36),0,35)
func hit(world_point: Vector2) -> bool:
	var p=to_local(world_point);var sample=Vector2(-1,-1)
	if not Rect2(-tex_size.x/2-tex_size.y*.15,-tex_size.y*.1,tex_size.x+tex_size.y*.3,tex_size.y*1.25).has_point(p):return false
	if p.y<tex_size.y*.27:sample=p-body_offset+Vector2(tex_size.x/2,0)
	else:
		for tri in hit_rows[_hit_row(p.y)]:
			var a=polygon[tri[0]];var ab=polygon[tri[1]]-a;var ac=polygon[tri[2]]-a;var ap=p-a;var den=ab.cross(ac)
			if absf(den)<.0001:continue
			var u=ap.cross(ac)/den;var v=ab.cross(ap)/den
			if u<0 or v<0 or u+v>1:continue
			sample=uv[tri[0]]+(uv[tri[1]]-uv[tri[0]])*u+(uv[tri[2]]-uv[tri[0]])*v;break
	return Rect2(Vector2.ZERO,tex_size).has_point(sample) and source.get_pixelv(Vector2i(sample)).a>.2
