extends "res://prototypes/isometric/iso_world.gd"
var passage
func _ready() -> void:
 super._ready()
 passage=preload("res://prototypes/isometric/iso_passage.gd").new();passage.setup(self);add_child(passage)
