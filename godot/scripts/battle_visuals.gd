extends RefCounted
## Stable actor IDs link encounter portraits, exploration identity and battle art.
## Generic actors deliberately fall back to their equipped common weapon sheet.
static var DATA: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_visuals.json"))
