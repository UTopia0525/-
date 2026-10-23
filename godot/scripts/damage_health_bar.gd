extends ProgressBar
## Red HP changes immediately; gold damage remains briefly then drains to the same value.
const HOLD := .20
const DRAIN := .38
var trail: ProgressBar
var current: ProgressBar
var drain: Tween
func _ready() -> void:
	show_percentage = false
	add_theme_font_size_override("font_size", 1)
	add_theme_stylebox_override("fill",_style(Color.TRANSPARENT))
	trail = _layer(Color("f0ce85"))
	current = _layer(Color("d64d48"))
	set_health(value,max_value,false)
func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style
func _layer(color: Color) -> ProgressBar:
	var layer := ProgressBar.new()
	layer.show_percentage = false
	layer.add_theme_font_size_override("font_size", 1)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_theme_stylebox_override("background",_style(Color.TRANSPARENT))
	layer.add_theme_stylebox_override("fill",_style(color))
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer
func set_health(amount: float, maximum: float, animate: bool = true) -> void:
	if drain and drain.is_valid(): drain.kill()
	var previous := value
	max_value = maximum
	value = clampf(amount,0,maximum)
	if not is_instance_valid(current): return
	trail.max_value = maximum
	current.max_value = maximum
	current.value = value
	if not animate or value >= previous:
		trail.value = value
		return
	trail.value = maxf(trail.value,previous)
	drain = create_tween()
	drain.tween_interval(HOLD)
	drain.tween_property(trail,"value",value,DRAIN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
func snap() -> void:
	set_health(value,max_value,false)
