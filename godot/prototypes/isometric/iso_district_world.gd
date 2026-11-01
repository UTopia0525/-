extends "res://prototypes/isometric/iso_world.gd"
var passage
var errand
const MotionScope=preload("res://prototypes/isometric/iso_interpolation_scope.gd")
func _enter_tree() -> void:
 MotionScope.acquire(get_tree());physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_ON
func _exit_tree() -> void:
 MotionScope.release(get_tree());super._exit_tree()
func _ready() -> void:
 super._ready()
 actor.speed=4.8
 selection_message="생활 구역 · 노란 ! 짐꾼에게 F · Q 의뢰 일지"
 passage=preload("res://prototypes/isometric/iso_passage.gd").new();passage.setup(self);add_child(passage)
 errand=preload("res://prototypes/isometric/iso_errand.gd").new();errand.setup(self,passage);passage.add_child(errand)
