extends CharacterBody2D

@export var speed: float = 360.0
var movement_enabled: bool = true
var click_path: PackedVector2Array = []
var sprite: AnimatedSprite2D
var facing: String = "down"
var display_height:=140.0
var animation_metadata: Dictionary

func _ready() -> void:
	animation_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/hero_walk_frames.json"))
	display_height=float(animation_metadata.target_height)
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _build_animations()
	sprite.frame_changed.connect(_align_frame)
	add_child(sprite)
	_play("idle_" + facing)

func _build_animations() -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	var walking_sheet: Texture2D = preload("res://assets/animation/hero_walk.png")
	var idle_sheet: Texture2D = preload("res://assets/characters.png")
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
		frames.add_frame(idle, _atlas(idle_sheet, poses.idle.region))
	return frames

func _atlas(sheet: Texture2D, region: Array) -> AtlasTexture:
	var texture = AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(region[0], region[1], region[2], region[3])
	return texture

func _align_frame() -> void:
	var poses: Dictionary = animation_metadata.directions[facing]
	var walking = String(sprite.animation).begins_with("walk_")
	var info: Dictionary = poses.walk[sprite.frame] if walking else poses.idle
	# Per-frame atlas regions register the head center and foot baseline.
	sprite.offset = -Vector2(info.pivot[0], info.pivot[1])
	var reference: float = poses.reference_height if walking else poses.idle.height
	sprite.scale = Vector2.ONE * (display_height / reference)

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
		_play("idle_" + facing)
		return
	var click_distance: float=-1.0
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0:
		click_path.clear()
	else:
		while not click_path.is_empty() and position.distance_to(click_path[0])<2.0:click_path.remove_at(0)
		if not click_path.is_empty():
			click_distance=position.distance_to(click_path[0])
			direction=position.direction_to(click_path[0])
	var previous = position
	# Clamp a click step to its waypoint even at low FPS; keyboard retains full speed.
	var movement_speed: float=minf(speed,click_distance/maxf(_delta,.00001)) if click_distance>=0 else speed
	velocity = direction * movement_speed
	move_and_slide()
	if direction.length_squared() > 0:
		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"
	# Animate actual movement, not attempted motion into a wall.
	_play(("walk_" if position.distance_squared_to(previous) > 0.01 else "idle_") + facing)

func stop() -> void:
	click_path.clear()
	velocity = Vector2.ZERO
	if is_instance_valid(sprite):
		_play("idle_" + facing)
