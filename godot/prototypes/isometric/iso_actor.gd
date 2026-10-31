extends CharacterBody2D
const Space=preload("res://prototypes/isometric/iso_space.gd")
var logical=Vector2.ZERO
var speed=2.4
var sprite: Sprite2D
var frames: Dictionary
var images: Dictionary={}
var hit_images: Dictionary={}
var base_scale=Vector2.ONE
var moving=false
var phase=0.0
var facing="front"
var picked=false
var interactive=true
var owner_world
var footprint: Rect2:
	get:return Rect2(logical-Vector2(.15,.15),Vector2(.3,.3))
func setup(art: Dictionary,world) -> void:
	frames=art;owner_world=world;name="VillageNPC";collision_layer=2;collision_mask=1
	var polygon=CollisionPolygon2D.new();var points=PackedVector2Array()
	for i in range(24):points.append(Space.project(Vector2(cos(i*TAU/24),sin(i*TAU/24))*.15))
	polygon.polygon=points;add_child(polygon)
	sprite=Sprite2D.new();sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
	for key in art:
		var data=art[key];var atlas=AtlasTexture.new();atlas.atlas=load(data.texture);atlas.region=Rect2(data.region[0],data.region[1],data.region[2],data.region[3]);images[key]=atlas
		var image=atlas.get_image()
		if image.is_compressed():image.decompress()
		hit_images[key]=image
	set_pose("front",false)
func set_pose(key: String,flip: bool) -> void:
	facing=key;sprite.texture=images[key];sprite.flip_h=flip
	base_scale=Vector2.ONE*96.0/sprite.texture.get_height();sprite.scale=base_scale
	sprite.position=Vector2(-sprite.texture.get_width()*base_scale.x/2,-96)
func set_logical(p: Vector2) -> void:
	logical=p;position=Space.project(p);velocity=Vector2.ZERO
func _physics_process(delta: float) -> void:
	var direction=Input.get_vector("iso_left","iso_right","iso_up","iso_down") if interactive else Vector2.ZERO
	var before=position
	# Screen-oriented controls, constant logical ground speed.
	velocity=Space.project(Space.unproject(direction).normalized()*speed) if direction!=Vector2.ZERO else Vector2.ZERO
	move_and_slide();logical=Space.unproject(position);moving=position.distance_to(before)>.01
	if moving:
		phase+=delta*10.0
		set_pose("back" if direction.y<0 else "front",direction.x<0 if direction.y>=0 else direction.x>0)
	else:phase+=delta*2.0
	# Placeholder idle breathing/step sway, pivot stays on ground. No full walk sheet claimed.
	sprite.scale=Vector2(base_scale.x,base_scale.y*(1.0+sin(phase)*(.009 if moving else .003)))
	sprite.rotation=sin(phase)*.018 if moving else 0.0
	sprite.position=-(Vector2(sprite.texture.get_width()/2.0,sprite.texture.get_height())*sprite.scale).rotated(sprite.rotation)
	queue_redraw()
func hit(point: Vector2) -> bool:
	var p=sprite.to_local(point);var size=sprite.texture.get_size()
	if not Rect2(Vector2.ZERO,size).has_point(p):return false
	var pixel=Vector2i(p)
	if sprite.flip_h:pixel.x=int(size.x)-1-pixel.x
	return hit_images[facing].get_pixelv(pixel).a>.2
func _draw() -> void:
	var points=PackedVector2Array()
	for i in range(32):points.append(Vector2(cos(i*TAU/32)*21,sin(i*TAU/32)*9))
	draw_colored_polygon(points,Color(.06,.10,.09,.3))
	if picked or owner_world.debug_footprints:draw_polyline(points+PackedVector2Array([points[0]]),Color("edcc80"),2)
