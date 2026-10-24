extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("PROLOGUE F: "+message)
func key(code: Key,logical: int=-1) -> void:
	var e=InputEventKey.new();e.keycode=code if logical<0 else logical;e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e);await process_frame
	e=InputEventKey.new();e.keycode=code if logical<0 else logical;e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e);await physics_frame
func drain() -> void:
	for i in range(160):
		if game.dialogue_lines.is_empty():return
		await key(KEY_F)
	check(false,"F advances and terminates dialogue")
func approach(id: String) -> void:
	var w=game.exploration
	var entry=w.npcs.filter(func(n):return n.id==id)[0]
	var path=w.path_to(entry.position,true)
	check(not path.is_empty(),"keyboard route reaches "+id)
	for waypoint in path:
		for i in range(90):
			var offset: Vector2=waypoint-w.player.position
			for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
			if offset.length()<9:break
			var action="move_right" if offset.x>0 else "move_left"
			if absf(offset.y)>absf(offset.x):action="move_down" if offset.y>0 else "move_up"
			Input.action_press(action);await physics_frame
	for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
	await physics_frame
	check(w.nearest().get("id","")==id,"keyboard walking selects "+id+" for F")

func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_story();await physics_frame
	await drain();check(game.exploration.active,"F clears opening and enables exploration")
	for id in ["apothecary","sailor","clerk","captain"]:
		await approach(id)
		await key(KEY_E);check(game.dialogue_lines.is_empty(),"E is not an interaction key")
		# Korean keyboard can report a Hangul logical symbol at physical F.
		await key(KEY_F,0x3147 if id=="captain" else -1)
		check(not game.dialogue_lines.is_empty(),"physical F starts "+id+" conversation")
		await drain()
	check(game.talked_captain,"captain greeting was completed")
	await approach("boarding");await key(KEY_F);check(not game.dialogue_lines.is_empty(),"F starts boarding conversation");await drain()
	check(game.exploration.area_name=="deck","F dialogue boards ship")
	await approach("deck-sailor");await key(KEY_F);check(not game.dialogue_lines.is_empty(),"F speaks on deck");await drain()
	await approach("deck-captain");await key(KEY_F);check(not game.dialogue_lines.is_empty(),"F starts deck captain dialogue");await drain()
	check(game.state=="battle","F dialogue reaches tutorial battle")
	game.reset();await create_timer(.25).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame
	if not failed:print("PROLOGUE F PASS: keyboard navigation, physical F including Hangul, all dock actors, boarding, deck, tutorial")
	quit(1 if failed else 0)
