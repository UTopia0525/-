extends CharacterBody2D

@export var speed: float = 180.0
var movement_enabled: bool = true
var click_path: PackedVector2Array = []
var sprite: Sprite2D
var walk_time: float = 0.0

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/characters.png")
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (104.0 / (sprite.texture.get_height() / 2.0))
	sprite.position.y = -43
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0:
		click_path.clear()
	elif not click_path.is_empty():
		var destination = click_path[0]
		if position.distance_to(destination) < 5.0:
			click_path.remove_at(0)
		else:
			direction = position.direction_to(destination)
	velocity = direction * speed
	move_and_slide()
	if direction.length_squared() > 0:
		walk_time += delta * 11.0
		sprite.position.y = -43 + sin(walk_time) * 1.2
		if absf(direction.x) > absf(direction.y):
			sprite.frame = 2 if direction.x > 0 else 1
		else:
			sprite.frame = 0 if direction.y > 0 else 3
	else:
		sprite.position.y = -43

func stop() -> void:
	click_path.clear()
	velocity = Vector2.ZERO
