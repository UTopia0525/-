extends SceneTree
var scene
var orientations: Dictionary={}
func _initialize() -> void:run.call_deferred()
func frames(count: int) -> void:
	for i in range(count):await process_frame
func key(code: int,pressed: bool) -> void:
	var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
func tap(code: int) -> void:
	await key(code,true);await key(code,false)
func shot(name: String) -> void:
	scene.update_depth();scene.update_occlusion();scene.visibility_hint.refresh()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://prototypes/isometric/screenshots/dialogue-"+name+".png")==OK)
	orientations[name]={"pose":[scene.actor.facing,scene.actor.facing_flipped],"position":[scene.actor.logical.x,scene.actor.logical.y],"npc_speeds":[scene.npcs[0].speed,scene.npcs[1].speed]}
func run() -> void:
	root.size=Vector2i(1280,720);scene=load("res://prototypes/isometric/main.tscn").instantiate();root.add_child(scene);await frames(2)
	scene.actor.set_logical(Vector2(5.5,9.7));await frames(4);await shot("target")
	await tap(KEY_F);assert(scene.dialogue.active);await frames(45);await shot("npc")
	await tap(KEY_F);await frames(45);await shot("hero")
	await tap(KEY_H);assert(scene.dialogue.dialogue_history.visible);await frames(30);await shot("history")
	await tap(KEY_ESCAPE);await tap(KEY_F);await frames(20);await tap(KEY_F);await tap(KEY_F);await frames(20);await tap(KEY_F)
	assert(not scene.dialogue.active);await frames(60);await shot("resume")
	# Authored comparison: exercise real W+D input, then release D before W.
	scene.patrols_enabled=false;scene.actor.set_logical(Vector2(7.5,10.5));await frames(2)
	await key(KEY_W,true);await key(KEY_D,true);await frames(6);await shot("facing-moving")
	await key(KEY_D,false);await key(KEY_W,false);await frames(8);await shot("facing-idle")
	assert(orientations["facing-moving"].pose==orientations["facing-idle"].pose)
	# Place the second speaker at the start of its actual route for a clear sample.
	scene.reset_trial();scene.actor.set_logical(Vector2(8.3,5.35));await frames(2);await tap(KEY_F);assert(scene.dialogue.target==scene.npcs[1])
	await frames(30);await shot("second-npc")
	root.size=Vector2i(2560,1440);await frames(3);await shot("1440p")
	var output=FileAccess.open("res://prototypes/isometric/screenshots/dialogue-capture.json",FileAccess.WRITE);output.store_string(JSON.stringify(orientations,"  "));output.close()
	scene.dialogue.finish();scene.queue_free();await process_frame;print("ISOMETRIC_DIALOGUE_CAPTURE: PASS");quit()
