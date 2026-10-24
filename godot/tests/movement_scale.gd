extends SceneTree
var game
var failed:=false
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("MOVEMENT_SCALE: "+message)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_city();var world=game.exploration;var player=world.player
	var start: Vector2=world.city_point([770,500]);player.position=start;player.stop()
	Input.action_press("move_right")
	for i in range(30):await physics_frame
	Input.action_release("move_right");await physics_frame
	check(player.position.x-start.x>165 and player.position.x-start.x<195,"keyboard moves about 180 world units in half a second, twice the old distance")
	check(player.display_height==140 and player.get_node("Feet").shape.radius==world.FOOT_RADIUS,"city art and real feet use the enlarged proportions")
	var old_rate: int=Engine.physics_ticks_per_second;Engine.physics_ticks_per_second=30
	player.position=start;player.stop();var end:=start+Vector2(106,0)
	player.click_path=PackedVector2Array([start+Vector2(6,0),start+Vector2(26,0),start+Vector2(46,0),end])
	for i in range(30):await physics_frame
	check(player.click_path.is_empty() and player.position.distance_to(end)<2.1,"fast click movement reaches short waypoints at 30Hz without oscillation")
	Engine.physics_ticks_per_second=old_rate
	var resting=player.position;game.settings_menu.open_menu()
	await create_timer(.15).timeout
	check(player.position==resting,"settings still pauses movement")
	game.settings_menu.close_menu()
	game.exploration.load_area("deck")
	check(player.display_height==104 and player.speed==360,"narrow prologue map adapts size and retains doubled speed")
	player.stop();check(player.sprite.animation.begins_with("idle_"),"standing pose stays registered to feet after map change")
	game.reset();await create_timer(1).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	await create_timer(.25).timeout;game.queue_free();await process_frame
	print("GODOT_MOVEMENT_SCALE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
