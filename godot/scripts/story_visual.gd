extends Control
## Runtime cutscene staging using existing art and native Godot water/debris drawing.
const UI = preload("res://scripts/ui.gd")
var mode := ""
var phase := 0.0
var paused := false
var picture: TextureRect
var note: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	picture = TextureRect.new()
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	note = UI.label(self, "", Rect2(36, 92, 1200, 30), 17, UI.TEXT)
	note.add_theme_color_override("font_outline_color", Color("091718"))
	note.add_theme_constant_override("outline_size", 5)
	hide()

func present(value: String) -> void:
	mode = value
	paused = false
	picture.visible = mode != "river"
	picture.texture = load("res://assets/battle-bandit-road.png" if mode == "bandit_road" else "res://assets/deck.png" if mode == "wreck" else "res://assets/dock.png")
	picture.modulate = Color(0.32, 0.39, 0.42) if mode != "delivery" else Color(0.62, 0.64, 0.56)
	if mode == "bandit_road": picture.modulate = Color(0.55, 0.61, 0.55)
	note.text = {"bandit_road":"장사 동쪽 산길 · 포졸은 길목을 지키고 지원자는 위쪽을 살핀다.", "wreck":"선체가 얕은 수로에 걸렸다. 부서진 옆판으로 물이 밀려든다.", "river":"귀물함과 밧줄에 얽힌 허만복이 서로 반대쪽으로 떠밀려간다.", "shore":"기슭의 임시 피난처 · 살아남은 사람들이 돌아오지 않는 이름을 기다린다.", "delivery":"수령처 · 마지막으로 남은 인도 서류를 내민다."}.get(mode, "")
	show()
	queue_redraw()

func _process(delta: float) -> void:
	if visible and mode == "river" and not paused:
		phase += delta
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("102b35"))
	if mode != "river": return
	for row in range(24):
		var y = 40.0 + row * 29
		var offset = sin(phase * 0.7 + row) * 18
		for column in range(6):
			var x = column * 240.0 + offset
			draw_line(Vector2(x, y), Vector2(x + 95, y - 12), Color("2a4d57"), 3)
	# Broken vessel, opposite currents, sealed cargo and the trapped sailor.
	for i in range(4):
		draw_set_transform(Vector2(520 + i * 70, 375 + i * 24), -0.3 + i * 0.17)
		draw_rect(Rect2(-90, -8, 180, 16), Color("635246"))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(194, 288, 125, 83), Color("765f42"))
	draw_rect(Rect2(203, 296, 107, 67), Color("9a7c52"), false, 4)
	draw_line(Vector2(256, 290), Vector2(256, 370), Color("a64534"), 8)
	var sailor = AtlasTexture.new()
	sailor.atlas = load("res://assets/characters.png")
	sailor.region = Rect2(829, 529, 272, 440)
	draw_texture_rect(sailor, Rect2(941, 260, 62, 100), false)
	draw_line(Vector2(952, 338), Vector2(1080, 395), Color("a08b65"), 5)
	draw_line(Vector2(1080, 395), Vector2(1110, 465), Color("695e4d"), 8)
