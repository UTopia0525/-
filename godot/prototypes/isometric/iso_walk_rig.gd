extends Polygon2D
## Runtime skinning of the approved atlas, not a rescaled/rocking whole sprite.
## Upper body stays rigid. Opposite leg weights move the two feet independently.
var source: Image
var original=PackedVector2Array()
var triangles: Array[PackedInt32Array]=[]
var facing=""
var gait=0.0
var tex_size=Vector2.ZERO
var atlas_reference: Texture2D
var render_textures: Dictionary={}
func pose(atlas: Texture2D,pixels: Image,key: String,phase: float) -> void:
	if atlas_reference!=atlas:
		# Polygon2D UVs address the backing atlas, unlike Sprite2D's source rect.
		# Upload the registered region once at runtime so mesh UVs and alpha hits agree.
		atlas_reference=atlas
		if not render_textures.has(atlas):render_textures[atlas]=ImageTexture.create_from_image(pixels)
		texture=render_textures[atlas];source=pixels;tex_size=texture.get_size();_build_grid()
	facing=key;gait=phase
	var vertices=original.duplicate()
	for i in range(vertices.size()):vertices[i]+=_offset(original[i])
	polygon=vertices
func _build_grid() -> void:
	original.clear();triangles.clear();var coords=PackedVector2Array()
	var cols=16;var rows=20
	for y in range(rows+1):
		for x in range(cols+1):
			var uv_point=Vector2(x/float(cols),y/float(rows))*tex_size
			coords.append(uv_point);original.append(uv_point-Vector2(tex_size.x/2,0))
	for y in range(rows):
		for x in range(cols):
			var a=y*(cols+1)+x;var b=a+1;var c=a+cols+1;var d=c+1
			triangles.append(PackedInt32Array([a,b,d]));triangles.append(PackedInt32Array([a,d,c]))
	uv=coords;polygons=triangles
func _offset(p: Vector2) -> Vector2:
	var weight=smoothstep(.66,.98,p.y/tex_size.y)
	var side=clampf(p.x/(tex_size.x*.1),-1,1)
	var swing=sin(gait)*side
	var forward=Vector2(.090,.042) if facing=="front" else Vector2(-.090,-.042)
	return (forward*swing+Vector2(0,-maxf(0,-swing)*.022))*tex_size.y*weight
func hit(world_point: Vector2) -> bool:
	var point=to_local(world_point);var sample=Vector2(-1,-1)
	if not Rect2(-tex_size.x/2-tex_size.y*.1,0,tex_size.x+tex_size.y*.2,tex_size.y*1.1).has_point(point):return false
	if point.y<tex_size.y*.65:sample=point+Vector2(tex_size.x/2,0)
	else:
		# Barycentric UVs use the same deformed triangles as the renderer.
		for tri in triangles:
			if original[tri[2]].y<tex_size.y*.60:continue
			var a=polygon[tri[0]];var b=polygon[tri[1]];var c=polygon[tri[2]]
			var ab=b-a;var ac=c-a;var ap=point-a;var den=ab.cross(ac)
			if absf(den)<.0001:continue
			var u=ap.cross(ac)/den;var v=ab.cross(ap)/den
			if u<0 or v<0 or u+v>1:continue
			sample=uv[tri[0]]+(uv[tri[1]]-uv[tri[0]])*u+(uv[tri[2]]-uv[tri[0]])*v;break
	return Rect2(Vector2.ZERO,tex_size).has_point(sample) and source.get_pixelv(Vector2i(sample)).a>.2
