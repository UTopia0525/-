extends Camera2D

# The camera follows the player's body, not the bottom of their feet.
@export_range(0.5, 3.0, 0.1) var exploration_zoom: float = 1.2
@export var focus_height: float = 36.0
var map_bounds: Rect2 = Rect2(0, 0, 1280, 720)

func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	ignore_rotation = true
	position = Vector2(0, -focus_height)
	offset = Vector2.ZERO
	get_viewport().size_changed.connect(_fit_view)
	set_map_bounds(map_bounds)

func set_focus_height(height: float) -> void:
	focus_height=height
	position=Vector2(0,-height)

func set_map_bounds(bounds: Rect2) -> void:
	assert(bounds.size.x > 0 and bounds.size.y > 0, "Camera requires positive map dimensions")
	map_bounds = bounds
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
	_fit_view()

func _fit_view() -> void:
	# A map smaller than the window must still cover the view without empty space.
	var view_size = get_viewport_rect().size
	var minimum_zoom = maxf(view_size.x / map_bounds.size.x, view_size.y / map_bounds.size.y)
	zoom = Vector2.ONE * maxf(exploration_zoom, minimum_zoom)
	if enabled:
		reset_smoothing()
		force_update_scroll()

func snap_to_player() -> void:
	enabled = true
	make_current()
	reset_smoothing()
	force_update_scroll()
