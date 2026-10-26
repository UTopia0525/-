extends Control
const UI=preload("res://scripts/ui.gd")
var game
var shade: ColorRect
var panel: Control
var return_button: Button
var ready_to_return=false
var transition: Tween
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	z_index=30
	shade=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade)
	panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.z_index=1;add_child(panel)
	var heading=UI.label(panel,"강호에 쓰러지다",Rect2(190,170,900,85),48,Color("c49478"));heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var text=UI.label(panel,"도원이 목숨을 잃었습니다.\n그의 발걸음은 이곳에서 멈추었습니다.",Rect2(190,285,900,90),21,UI.TEXT);text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var hint=UI.label(panel,"처음 화면에서 이전 저장을 불러오거나 새 여정을 시작할 수 있습니다.",Rect2(180,410,920,40),18,UI.MUTED);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return_button=UI.button(panel,"처음 화면으로 · F / Enter",Rect2(440,505,400,62),true);return_button.pressed.connect(return_to_title)
	hide()
func present() -> void:
	dismiss();ready_to_return=false;shade.color=Color(.025,.015,.015,0);panel.hide();return_button.disabled=true;show()
	transition=create_tween()
	transition.tween_interval(.85)
	transition.tween_property(shade,"color:a",.97,.65)
	transition.tween_callback(_reveal)
func _reveal() -> void:
	ready_to_return=true;panel.show();return_button.disabled=false;return_button.grab_focus()
func return_to_title() -> void:
	if not visible or not ready_to_return or game.state!="game_over":return
	game.reset()
func dismiss() -> void:
	if transition and transition.is_valid():transition.kill()
	ready_to_return=false;hide()
