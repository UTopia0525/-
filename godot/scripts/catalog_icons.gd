extends RefCounted
## Stable atlas entries. New catalogue entries must ship art and a mapping together.
static var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/icon_manifest.json"))
static var cache: Dictionary = {}
static func texture(id: String) -> Texture2D:
	if cache.has(id): return cache[id]
	var data: Dictionary = entries.get(id, {})
	if data.is_empty(): return null
	var sheet: Texture2D = load("res://assets/icons/" + str(data.atlas) + ".png")
	var result := AtlasTexture.new()
	result.atlas = sheet
	var cell := sheet.get_size() / Vector2(float(data.cols),float(data.get("rows",data.cols)))
	result.region = Rect2(Vector2(int(data.cell) % int(data.cols), int(data.cell) / int(data.cols)) * cell, cell)
	cache[id] = result
	return result
static func apply(button: Button, id: String, width: int = 40) -> void:
	button.icon = texture(id)
	preload("res://scripts/ui.gd").item_highlight(button,button.icon != null)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", width)
	button.add_theme_constant_override("h_separation", 10)
