extends "res://prototypes/isometric/iso_world.gd"
const MotionScope=preload("res://prototypes/isometric/iso_interpolation_scope.gd")
var passage
var errand
var merchant
func _enter_tree() -> void:
 MotionScope.acquire(get_tree());physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_ON
func _exit_tree() -> void:
 MotionScope.release(get_tree());super._exit_tree()
func _ready() -> void:
 super._ready();actor.speed=4.8
 merchant=Actor.new();merchant.setup(art.npc,self);merchant.name="TownMerchant";merchant.display_name="약재 행상";merchant.interactive=false;merchant.speed=4.8;merchant.traffic_rank=3
 actors.add_child(merchant);moving_actors.append(merchant);npcs.append(merchant);merchant.set_logical(Vector2(20.5,6.8))
 # Same HUD/interaction implementation, with only trial-local target hysteresis.
 var parent=interaction.get_parent();parent.remove_child(interaction);interaction.queue_free()
 interaction=preload("res://prototypes/isometric/iso_town_interaction.gd").new();interaction.setup(self);parent.add_child(interaction)
 parent=visibility_hint.get_parent();parent.remove_child(visibility_hint);visibility_hint.queue_free()
 visibility_hint=preload("res://prototypes/isometric/iso_visibility_hint.gd").new();visibility_hint.setup(self);parent.add_child(visibility_hint)
 passage=preload("res://prototypes/isometric/iso_passage.gd").new();passage.setup(self);add_child(passage)
 errand=preload("res://prototypes/isometric/iso_town_errands.gd").new();errand.setup(self,passage);passage.add_child(errand)
 selection_message="장사 남문 안 · 짐꾼의 부탁 둘 · 약재 행상 · Q 의뢰 일지"
 last_sorted_positions=[];update_depth()

func reset_trial() -> void:
 reset_actor()
 for npc in npcs:
  if npc.patrol!=null:npc.patrol.reset()
 if is_instance_valid(merchant):merchant.set_logical(Vector2(20.5,6.8))
 if is_instance_valid(interaction) and interaction.has_method("invalidate"):interaction.invalidate()
