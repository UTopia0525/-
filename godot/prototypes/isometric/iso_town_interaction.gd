extends "res://prototypes/isometric/iso_interaction.gd"
var held_target
var cached_tick=-1
var cached_player=Vector2(INF,INF)
var cached_target
func invalidate() -> void:cached_tick=-1
func choose_target():
 var tick=Engine.get_physics_frames()
 if tick==cached_tick and cached_player==world.actor.logical:return cached_target
 cached_tick=tick;cached_player=world.actor.logical
 var best=super.choose_target()
 # Keep an accessible target across tiny distance ties; never keep one through a wall.
 if held_target!=best and is_instance_valid(held_target) and best!=null and reachable(held_target):
  if world.actor.logical.distance_to(held_target.logical)<=world.actor.logical.distance_to(best.logical)+.18:best=held_target
 held_target=best;cached_target=best;return best
func refresh() -> void:
 super.refresh()
 if is_instance_valid(world.errand) and world.errand.blocked():
  visible=false
  for npc in world.npcs:
   if npc.interaction_target:npc.interaction_target=false;npc.queue_redraw()
