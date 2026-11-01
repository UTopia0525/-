extends "res://prototypes/isometric/iso_world.gd"
var passage
var errand
func _ready() -> void:
 super._ready()
 actor.speed=4.8
 selection_message="생활 구역 · 노란 ! 짐꾼에게 F · Q 의뢰 일지"
 passage=preload("res://prototypes/isometric/iso_passage.gd").new();passage.setup(self);add_child(passage)
 errand=preload("res://prototypes/isometric/iso_errand.gd").new();errand.setup(self,passage);passage.add_child(errand)
