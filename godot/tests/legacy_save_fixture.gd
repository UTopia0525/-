extends RefCounted
## Test-only historical saves. New gameplay must reject these writes, while old files load.
static func write(game, slot: int) -> bool:
	var saves = game.save_system
	if game.state not in ["story", "service", "battle"] and not game.dialogue_panel.visible: return false
	if saves.write_slot(slot) or saves.error.is_empty(): return false
	var data: Dictionary = saves.capture()
	if not saves.validate(data): return false
	DirAccess.make_dir_recursive_absolute(saves.ROOT)
	var file = FileAccess.open(saves.path(slot), FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true
