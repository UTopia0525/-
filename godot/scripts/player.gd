extends CharacterBody2D

@export var speed: float = 360.0
var movement_enabled: bool = true
var sprite: AnimatedSprite2D
var facing: String = "down"
var display_height:=140.0
var animation_metadata: Dictionary
var side_mesh: MeshInstance2D
var side_material: ShaderMaterial
var side_direction := ""
var gait_phase := 0.0

func _ready() -> void:
	animation_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/hero_walk_frames.json"))
	display_height=float(animation_metadata.target_height)
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _build_animations()
	sprite.frame_changed.connect(_align_frame)
	add_child(sprite)
	side_mesh=MeshInstance2D.new();side_mesh.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	side_mesh.texture=preload("res://assets/animation/hero_walk.png")
	side_material=ShaderMaterial.new();side_material.shader=preload("res://scripts/side_walk.gdshader")
	side_mesh.material=side_material;add_child(side_mesh)
	_play("idle_" + facing)

func _build_animations() -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	var walking_sheet: Texture2D = preload("res://assets/animation/hero_walk.png")
	for direction in ["down", "left", "right", "up"]:
		var poses: Dictionary = animation_metadata.directions[direction]
		var walking = "walk_" + direction
		frames.add_animation(walking)
		frames.set_animation_speed(walking, animation_metadata.fps)
		frames.set_animation_loop(walking, true)
		for info in poses.walk:
			frames.add_frame(walking, _atlas(walking_sheet, info.region))
		var idle = "idle_" + direction
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 1.0)
		frames.set_animation_loop(idle, false)
		# Idle uses the same body art as walking, rather than a differently
		# proportioned sheet that changes head/body size at every stop.
		frames.add_frame(idle, _atlas(walking_sheet, poses.walk[0].region))
	return frames

func _atlas(sheet: Texture2D, region: Array) -> AtlasTexture:
	var texture = AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(region[0], region[1], region[2], region[3])
	return texture

func _align_frame() -> void:
	var poses: Dictionary = animation_metadata.directions[facing]
	var walking = String(sprite.animation).begins_with("walk_")
	var side := facing in ["left","right"]
	var info: Dictionary = poses.walk[0] if side or not walking else poses.walk[sprite.frame]
	# Per-frame atlas regions register the head center and foot baseline.
	sprite.offset = -Vector2(info.pivot[0], info.pivot[1])
	var reference: float = poses.walk[0].height
	sprite.scale = Vector2.ONE * (display_height / reference)
	sprite.visible=not side;side_mesh.visible=side
	if side:
		if side_direction!=facing:
			side_direction=facing;_build_side_mesh(info)
		side_mesh.scale=sprite.scale
		side_material.set_shader_parameter("gait_phase",gait_phase)
		side_material.set_shader_parameter("walking",1.0 if walking else 0.0)

func _build_side_mesh(info: Dictionary) -> void:
	var size=Vector2(info.region[2],info.region[3]);var pivot=Vector2(info.pivot[0],info.pivot[1])
	var origin=Vector2(info.region[0],info.region[1]);var sheet_size=side_mesh.texture.get_size()
	var vertices=PackedVector2Array();var uvs=PackedVector2Array();var indices=PackedInt32Array();var groups=PackedColorArray()
	const COLS=10
	const ROWS=40
	# Duplicate the middle seam so opposite legs cannot stretch each other's
	# boot pixels when they pass. Boots translate rigidly below the ankle.
	for leg in range(2):
		var base=vertices.size()
		for y in range(ROWS+1):
			for x in range(COLS+1):
				var local=Vector2((leg+float(x)/COLS)*.5,float(y)/ROWS)*size
				vertices.append(local-pivot);uvs.append((origin+local)/sheet_size);groups.append(Color(float(leg),1,1,1))
		for y in range(ROWS):
			for x in range(COLS):
				var a=base+y*(COLS+1)+x;var b=a+1;var c=a+COLS+1;var d=c+1
				indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices;arrays[Mesh.ARRAY_COLOR]=groups
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);side_mesh.mesh=mesh
	side_material.set_shader_parameter("frame_origin",origin/sheet_size);side_material.set_shader_parameter("frame_extent",size/sheet_size);side_material.set_shader_parameter("source_size",size)

func set_display_height(height: float) -> void:
	display_height=height
	if is_instance_valid(sprite):
		sprite.speed_scale=float(animation_metadata.target_height)/height
		_align_frame()

func _play(animation_name: String) -> void:
	if sprite.animation != animation_name:
		sprite.play(animation_name)
	_align_frame()

func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		gait_phase=0.0
		_play("idle_" + facing)
		return
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var previous = position
	velocity = direction * speed
	move_and_slide()
	var travelled:=position.distance_to(previous)
	if travelled>0.01:gait_phase=fmod(gait_phase+travelled/display_height*TAU,TAU)
	else:gait_phase=0.0
	if direction.length_squared() > 0:
		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"
	# Animate actual movement, not attempted motion into a wall.
	_play(("walk_" if position.distance_squared_to(previous) > 0.01 else "idle_") + facing)

func stop() -> void:
	velocity = Vector2.ZERO
	gait_phase=0.0
	if is_instance_valid(sprite):
		_play("idle_" + facing)
