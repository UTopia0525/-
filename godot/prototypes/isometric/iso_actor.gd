extends CharacterBody2D
const Space=preload("res://prototypes/isometric/iso_space.gd")
var logical=Vector2.ZERO
var speed=4.8
var sprite: Sprite2D
var frames: Dictionary
var images: Dictionary={}
var hit_images: Dictionary={}
var rig
var base_scale=Vector2.ONE
var moving=false
var phase=0.0
var walk_frame=0
var facing="front"
var picked=false
var interactive=true
var display_name="조작 짐꾼"
var traffic_rank=0
var patrol
var occluded=false
var occluded_samples=0
var owner_world
var footprint: Rect2:
	get:return Rect2(logical-Vector2(.15,.15),Vector2(.3,.3))
func setup(art: Dictionary,world) -> void:
	frames=art;owner_world=world;name="VillageNPC";collision_layer=2;collision_mask=3
	var polygon=CollisionPolygon2D.new();var points=PackedVector2Array()
	for i in range(24):points.append(Space.project(Vector2(cos(i*TAU/24),sin(i*TAU/24))*.15))
	polygon.polygon=points;add_child(polygon)
	sprite=Sprite2D.new();sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
	rig=preload("res://prototypes/isometric/iso_walk_rig.gd").new();rig.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(rig)
	rig.configure(art.get("gait",{}))
	for key in ["front","back"]:
		images[key]=_atlas(art[key]);hit_images[key]=_pixels(images[key])
	base_scale=Vector2.ONE*96.0/float(art.get("canvas_height",images.front.get_height()))
	set_pose("front",false)
func _atlas(info: Dictionary) -> AtlasTexture:
	var result=AtlasTexture.new();result.atlas=load(info.texture);result.region=Rect2(info.region[0],info.region[1],info.region[2],info.region[3]);return result
func _pixels(texture: Texture2D) -> Image:
	var result=texture.get_image()
	if result.is_compressed():result.decompress()
	return result
func set_pose(key: String,flip: bool) -> void:
	facing=key;sprite.flip_h=flip
	sprite.texture=images[key]
	# Fixed cell size, scale and ground pivot across idle/walk/all four directions.
	sprite.scale=base_scale;sprite.rotation=0
	sprite.position=-Vector2(sprite.texture.get_width()/2.0,sprite.texture.get_height())*base_scale
	sprite.visible=not moving;rig.visible=moving
	if moving:
		rig.pose(sprite.texture,hit_images[key],key,phase)
		rig.scale=base_scale*Vector2(-1 if flip else 1,1)
		rig.position=Vector2(0,-sprite.texture.get_height()*base_scale.y)
func set_logical(p: Vector2) -> void:
	logical=p;position=Space.project(p);velocity=Vector2.ZERO;moving=false;phase=0;walk_frame=0
	if is_instance_valid(sprite):set_pose(facing,sprite.flip_h)
func _physics_process(delta: float) -> void:
	var direction=Input.get_vector("iso_left","iso_right","iso_up","iso_down") if interactive else Vector2.ZERO
	var ground_direction=Space.unproject(direction).normalized()
	if patrol!=null:
		ground_direction=patrol.direction(delta) if owner_world.patrols_enabled else Vector2.ZERO
		direction=Space.project(ground_direction).normalized()
	var before=position
	# Screen-oriented controls, constant logical ground speed.
	velocity=Space.project(ground_direction*speed)
	move_and_slide();logical=Space.unproject(position)
	var ground_travel=Space.unproject(position-before).length()
	moving=ground_travel>.0005
	if patrol!=null:patrol.observe(delta,ground_travel)
	if moving:
		# Distance-driven cycle stops on collision and does not run in place.
		phase=fmod(phase+ground_travel*TAU/1.9,TAU)
		walk_frame=int(phase/TAU*4)%4
		set_pose("back" if direction.y<0 else "front",direction.x<0 if direction.y>=0 else direction.x>0)
	else:
		phase=0;walk_frame=0;set_pose(facing,sprite.flip_h)
	queue_redraw()
func hit(point: Vector2) -> bool:
	if moving:return rig.hit(point)
	var p=sprite.to_local(point);var size=sprite.texture.get_size()
	if not Rect2(Vector2.ZERO,size).has_point(p):return false
	var pixel=Vector2i(p)
	if sprite.flip_h:pixel.x=int(size.x)-1-pixel.x
	return hit_images[facing].get_pixelv(pixel).a>.2
func _draw() -> void:
	var points=PackedVector2Array()
	for i in range(32):points.append(Vector2(cos(i*TAU/32)*21,sin(i*TAU/32)*9))
	draw_colored_polygon(points,Color(.06,.10,.09,.3))
	if picked or owner_world.debug_footprints:
		var color=Color("edcc80") if interactive else Color("8ec7d1")
		draw_polyline(points+PackedVector2Array([points[0]]),color,2)
