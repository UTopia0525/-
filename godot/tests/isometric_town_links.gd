extends "res://tests/isometric_town.gd"
## Existing NPCs only; missing links are tested on in-memory definitions/registries.
func run() -> void:
 create_timer(60).timeout.connect(func():push_error("LINKS watchdog");quit(2))
 root.size=Vector2i(1280,720);await start()
 for id in q.definitions:
  var data: Dictionary=q.definitions[id];var lines: Array=world.dialogue.data.conversations[data.giver]
  check(q.giver(id)!=null and not lines.is_empty(),"real giver and startup dialogue registered "+id)
  check(lines[0][0]==data.actor and world.dialogue.PORTRAITS.ACTORS.has(data.actor),"real startup speaker matches quest portrait "+id)
 # No JSON edits: a missing startup conversation must fail without changing state.
 await approach("GatePorter")
 var lines: Array=world.dialogue.data.conversations.GatePorter
 world.dialogue.data.conversations.erase("GatePorter")
 var before=quest_snapshot();var npc=q.giver("iso_errand")
 check(not world.dialogue.begin(npc),"missing startup registration rejects conversation")
 check(not world.dialogue.active and not world.actor.motion_paused and not npc.motion_paused and quest_snapshot()==before,"failed start preserves actor pauses and quest/wallet state")
 world.dialogue.data.conversations.GatePorter=lines
 # Temporarily make an existing NPC an ordinary speaker; no NPC/dialogue is added.
 var definition: Dictionary=q.definitions.iso_errand
 q.definitions.erase("iso_errand");before=quest_snapshot()
 await tap(KEY_F)
 check(world.dialogue.active and world.dialogue.quest_id=="","ordinary existing NPC still starts normal dialogue")
 check(world.dialogue.pending=="","ordinary NPC does not schedule shop action")
 await finish_dialogue()
 check(not q.shop.visible and not paused and quest_snapshot()==before,"ordinary dialogue ends without shop or quest/wallet changes")
 if q.shop.visible:q.shop.close_counter()
 q.definitions.iso_errand=definition;await frames(3)
 # Positive check for the only merchant and the existing report handoff.
 await approach("TownMerchant");await tap(KEY_F)
 check(world.dialogue.active and world.dialogue.pending=="trade","real merchant schedules trading")
 await finish_dialogue();check(q.shop.visible and paused,"real merchant still opens the shop")
 await tap(KEY_ESCAPE);check(not q.shop.visible and not paused,"merchant shop closes normally")
 q.resolve_for("iso_errand","accept");q.resolve_for("iso_errand","inspect");await frames(3)
 await approach("GatePorter");await tap(KEY_F)
 check(world.dialogue.pending=="report","ready quest still schedules report")
 await finish_dialogue();check(q.phases.iso_errand=="completed" and q.completions.iso_errand==1 and not q.shop.visible,"report completes once without opening shop")
 await tap(KEY_F);await finish_dialogue()
 check(q.completions.iso_errand==1 and not q.shop.visible and q.money==300,"completed quest dialogue stays ordinary and grants no duplicate reward")
 world.queue_free();await frames(2)
 check(not paused and not physics_interpolation,"focused link check cleans up global state")
 print("ISOMETRIC_TOWN_LINKS: "+("FAIL" if failed else "PASS")+" | checks="+str(checks));quit(1 if failed else 0)
