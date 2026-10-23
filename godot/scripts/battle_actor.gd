extends Node2D
## Weapon columns: sword / saber / spear / none. Pose rows: ready / windup / strike / hit.
const COLUMNS = {"sword":0,"saber":1,"spear":2,"none":3}
const ROWS = {"ready":0,"windup":1,"strike":2,"hit":3}
var sprite: Sprite2D
var weapon_type := "sword"
var pose := "ready"
var enemy_side := false
var home := Vector2.ZERO
var motion: Tween
var flash: Tween
var breath: Tween
var sprite_origin := Vector2.ZERO
var frame_index := 0
var frame_data: Dictionary = {}
var textures: Dictionary = {}
var display_scale := 1.0
var cell_width := 0.0

func configure(is_enemy: bool, weapon: String, foot: Vector2) -> void:
	enemy_side = is_enemy
	home = foot
	if not is_instance_valid(sprite):
		sprite = Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	var sheet: Texture2D = load("res://assets/battle/enemy-poses.png" if is_enemy else "res://assets/battle/hero-poses.png")
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/battle/frames.json"))["enemy" if is_enemy else "hero"]
	frame_data = metadata.frames
	cell_width = float(metadata.cell_width)
	var side := 300.0 if is_enemy else 380.0
	display_scale = side / cell_width
	sprite.scale = Vector2.ONE * display_scale
	sprite.centered = false
	textures.clear()
	for key in frame_data:
		var r: Array = frame_data[key].region
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(r[0],r[1],r[2],r[3])
		textures[key] = atlas
	set_weapon(weapon)
	reset_motion()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.22))
	draw_circle(Vector2.ZERO,53.0 if enemy_side else 65.0,Color(0,0,0,.24))

func set_weapon(value: String) -> void:
	weapon_type = value if COLUMNS.has(value) else "none"
	if is_instance_valid(sprite): set_pose(pose)

func set_pose(value: String) -> void:
	pose = value
	frame_index = int(ROWS[value]) * 4 + int(COLUMNS[weapon_type])
	var key := str(frame_index)
	sprite.texture = textures[key]
	var data: Dictionary = frame_data[key]
	var r: Array = data.region
	sprite_origin = Vector2((float(r[0])-float(data.cell_x)-cell_width/2.0)*display_scale,(float(r[1])-float(data.foot_y))*display_scale)
	sprite.position = sprite_origin

func _kill(tween: Tween) -> void:
	if tween and tween.is_valid(): tween.kill()

func reset_motion() -> void:
	_kill(motion);_kill(flash);_kill(breath)
	position = home
	rotation = 0
	if not is_instance_valid(sprite): return
	sprite.position = sprite_origin
	sprite.modulate = Color.WHITE
	set_pose("ready")
	_idle()

func _idle() -> void:
	_kill(breath)
	sprite.position = sprite_origin
	breath = create_tween().set_loops()
	breath.tween_property(sprite,"position:y",sprite_origin.y-2.0,.8).set_trans(Tween.TRANS_SINE)
	breath.tween_property(sprite,"position:y",sprite_origin.y,.8).set_trans(Tween.TRANS_SINE)

func _prepare_motion() -> void:
	_kill(motion);_kill(flash);_kill(breath)
	position = home
	rotation = 0
	sprite.position = sprite_origin
	sprite.modulate = Color.WHITE

func attack() -> void:
	_prepare_motion()
	set_pose("windup")
	var direction := Vector2(-1,.30) if enemy_side else Vector2(1,-.30)
	var reaches := {"sword":340.0,"saber":350.0,"spear":300.0,"none":390.0}
	var reach: float = 390.0 if enemy_side else float(reaches[weapon_type])
	motion = create_tween()
	motion.tween_property(self,"position",home-direction*10,.12)
	motion.tween_callback(set_pose.bind("strike"))
	motion.tween_property(self,"position",home+direction*reach,.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.tween_interval(.20)
	motion.tween_property(self,"position",home,.16).set_trans(Tween.TRANS_SINE)
	motion.tween_callback(set_pose.bind("ready"))
	motion.tween_callback(_idle)

func hurt() -> void:
	_prepare_motion()
	set_pose("hit")
	var away := Vector2(1,-.28) if enemy_side else Vector2(-1,.28)
	motion = create_tween()
	motion.tween_property(self,"position",home+away*20,.06)
	motion.tween_property(self,"position",home,.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	motion.tween_callback(set_pose.bind("ready"))
	motion.tween_callback(_idle)
	flash = create_tween()
	sprite.modulate = Color(1,.24,.24)
	flash.tween_property(sprite,"modulate",Color.WHITE,.10)
	flash.tween_property(sprite,"modulate",Color(1,.40,.40),.06)
	flash.tween_property(sprite,"modulate",Color.WHITE,.15)

func defend(hold: float = .55) -> void:
	_prepare_motion()
	set_pose("windup")
	flash = create_tween()
	sprite.modulate = Color(.65,.85,1)
	flash.tween_property(sprite,"modulate",Color.WHITE,.4)
	motion = create_tween()
	motion.tween_interval(hold)
	motion.tween_callback(set_pose.bind("ready"))
	motion.tween_callback(_idle)

func stop() -> void:
	reset_motion()
	_kill(breath)
