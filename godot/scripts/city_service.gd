extends Control
## Empty service counters; goods, costs and training effects are authored later.
signal closed
const UI = preload("res://scripts/ui.gd")
var heading: Label
var message: Label
var tabs: Array[Button] = []
var service: Dictionary = {}
var selected_tab := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color("0b1414ce")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel = UI.panel(self, Rect2(300, 155, 680, 410))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	heading = UI.label(panel, "", Rect2(28, 20, 620, 38), 26, UI.GOLD)
	for i in range(2):
		var tab = UI.button(panel, "", Rect2(28 + i * 180, 85, 165, 42))
		tab.pressed.connect(select_tab.bind(i))
		tabs.append(tab)
	message = UI.label(panel, "", Rect2(28, 155, 620, 130), 20)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close = UI.button(panel, "돌아가기 · ESC", Rect2(443, 340, 208, 45))
	close.pressed.connect(close_counter)
	hide()

func open_counter(definition: Dictionary) -> void:
	service = definition.duplicate(true)
	heading.text = service.title + " · " + service.name
	var names: Array = {"market": ["구매", "판매"], "workshop": ["제작", "수리"], "training": ["수련", "무공 전수"]}[service.kind]
	for i in range(tabs.size()): tabs[i].text = names[i]
	select_tab(0)
	show()
	tabs[0].grab_focus()

func select_tab(index: int) -> void:
	selected_tab = index
	for i in range(tabs.size()): tabs[i].disabled = i == index
	var descriptions: Dictionary = {
		"market": ["아직 진열된 상품이 없습니다.", "아직 매입하는 품목이 없습니다."],
		"workshop": ["아직 제작할 수 있는 물품이 없습니다.", "아직 수리 의뢰를 받지 않습니다."],
		"training": ["아직 신청할 수 있는 수련이 없습니다.", "아직 전수받을 수 있는 무공이 없습니다."]}
	message.text = descriptions[service.kind][index] + "\n\n자세한 내용은 추후 추가됩니다."

func close_counter() -> void:
	hide()
	service.clear()
	closed.emit()

func dismiss() -> void:
	hide()
	service.clear()
