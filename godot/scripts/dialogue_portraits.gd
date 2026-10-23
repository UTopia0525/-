extends Control
## Stable participant slots; identity is independent of the reusable portrait.
const UI = preload("res://scripts/ui.gd")
const EXTRA_ROOT = "res://assets/portraits/extras/"
const ACTORS = {
	"bandit_officer": {"name":"정 포두", "extra":"male_middle"},
	"bandit_messenger": {"name":"포졸", "extra":"male_young", "portrait":"res://assets/portraits/story/constable.png"},
	"bandit_farmer": {"name":"피해 농민", "extra":"male_elder"},
	"bandit_raider": {"name":"길목 산적", "extra":"male_middle"},
	"bandit_leader": {"name":"산적 우두머리", "extra":"male_middle"},
	"cloth_merchant": {"name": "포목상", "extra": "female_middle"},
	"pirate": {"name": "흑린채 수적", "extra": "male_middle"},
	"recipient": {"name": "수령인", "extra": "male_middle"},
	"city_merchant": {"name": "장사꾼", "extra": "male_young", "portrait": "res://assets/portraits/services/merchant.png"},
	"city_artisan": {"name": "장인", "extra": "female_middle", "portrait": "res://assets/portraits/services/artisan.png"},
	"city_instructor": {"name": "교관", "extra": "male_middle", "portrait": "res://assets/portraits/services/instructor.png"},
	"hero": {"name": "주인공", "extra": "male_young", "portrait": "res://assets/portraits/player/hero.png"},
	"captain": {"name": "서문길", "extra": "male_middle"},
	"apothecary": {"name": "진소옥", "extra": "female_young"},
	"sailor": {"name": "허만복", "extra": "male_middle"},
	"clerk": {"name": "육승", "extra": "male_young"},
}
const DIM = Color(0.32, 0.32, 0.32, 1.0)
var portraits: Dictionary = {}
var actor_names: Dictionary = {}
var active_actor: String = ""

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(24, 125)
	size = Vector2(1232, 410)

func texture_for(actor: Dictionary) -> Texture2D:
	# A dedicated illustration overrides the common age/sex portrait.
	var dedicated: String = actor.get("portrait", "")
	if not dedicated.is_empty() and ResourceLoader.exists(dedicated):
		return load(dedicated)
	var path = EXTRA_ROOT + str(actor.get("extra", "male_young")) + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	push_error("Missing dialogue portrait: " + path)
	return null

func set_participants(participants: Array) -> void:
	clear()
	var columns: int = mini(4, participants.size())
	var rows: int = ceili(participants.size() / 4.0)
	if columns == 0:
		return
	var row_height = size.y / rows
	for index in range(participants.size()):
		var actor: Dictionary = participants[index]
		var id: String = actor.id
		if portraits.has(id):
			continue
		var column: int = index % columns
		var row: int = index / columns
		var in_row: int = mini(columns, participants.size() - row * columns)
		var slot_width = minf(340.0, size.x / in_row)
		var portrait = TextureRect.new()
		portrait.name = id
		portrait.position = Vector2((size.x - slot_width * in_row) / 2.0 + column * slot_width, row * row_height)
		portrait.size = Vector2(slot_width, row_height - 26)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.texture = texture_for(actor)
		add_child(portrait)
		portraits[id] = portrait
		var label = UI.label(self, actor.get("name", id), Rect2(portrait.position + Vector2(0, row_height - 26), Vector2(slot_width, 26)), 16)
		label.add_theme_color_override("font_outline_color", Color("12201c"))
		label.add_theme_constant_override("outline_size", 6)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		actor_names[id] = label
	show()
	set_speaker("")

func set_speaker(id: String) -> void:
	active_actor = id
	for actor_id in portraits:
		portraits[actor_id].self_modulate = Color.WHITE if actor_id == id else DIM
		actor_names[actor_id].self_modulate = Color.WHITE if actor_id == id else Color(0.65, 0.65, 0.65)

func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	portraits.clear()
	actor_names.clear()
	active_actor = ""
	hide()
