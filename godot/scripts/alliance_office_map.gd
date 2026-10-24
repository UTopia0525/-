extends "res://scripts/wuchang_map.gd"
func _init() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/alliance-office/layout.json"))
