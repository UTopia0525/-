extends SceneTree

const PORTRAITS = preload("res://scripts/dialogue_portraits.gd")
var failed := false

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("DIALOGUE TEST: " + message)

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_check_dialogues(game)
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("GODOT_DIALOGUE: " + ("FAIL" if failed else "PASS — six cutouts, listeners, stable cast, shared identity, overrides, cleanup"))
	quit(1 if failed else 0)

func _check_dialogues(game) -> void:
	var cast = game.dialogue_cast
	for category in ["male_young", "female_young", "male_middle", "female_middle", "male_elder", "female_elder"]:
		var texture = cast.texture_for({"extra": category})
		check(texture != null, "all six reusable portraits load: " + category)
		if texture:
			var artwork = texture.get_image()
			check(artwork.detect_alpha() != Image.ALPHA_NONE, "transparent cutout: " + category)
	game.start_story()
	game.advance_dialogue()
	game.say([["captain", "상대만 말해도 주인공은 듣고 있습니다."]])
	check(cast.portraits.size() == 2 and cast.portraits.has("hero"), "silent protagonist remains on screen")
	check(cast.portraits.captain.self_modulate == Color.WHITE, "speaker full brightness")
	check(cast.portraits.hero.self_modulate == PORTRAITS.DIM, "listener darkened")
	check(not game.exploration.active, "movement disabled during conversation")
	game.advance_dialogue()
	check(not cast.visible and cast.portraits.is_empty(), "conversation ending clears portraits")
	game.say([["hero", "보고합니다."], ["captain", "좋다."], ["sailor", "수적입니다!"]])
	check(cast.portraits.size() == 3, "all conversation participants visible from first line")
	var positions = {}
	for id in cast.portraits:
		positions[id] = cast.portraits[id].position
	game.advance_dialogue()
	check(cast.portraits.captain.self_modulate == Color.WHITE, "second speaker highlighted")
	check(cast.portraits.sailor.self_modulate == PORTRAITS.DIM, "shared portrait does not imply shared identity")
	game.advance_dialogue()
	check(cast.portraits.sailor.self_modulate == Color.WHITE and cast.portraits.captain.self_modulate == PORTRAITS.DIM, "highlight changes between identical common portraits")
	for id in cast.portraits:
		check(cast.portraits[id].position == positions[id], "speaker changes keep stable slots")
	var six: Array = []
	for category in ["male_young", "female_young", "male_middle", "female_middle", "male_elder", "female_elder"]:
		six.append({"id": category, "name": category, "extra": category})
	cast.set_participants(six)
	check(cast.portraits.size() == 6, "larger cast retains every participant")
	for portrait in cast.portraits.values():
		check(Rect2(Vector2.ZERO, cast.size).encloses(Rect2(portrait.position, portrait.size)), "all portrait slots inside gallery bounds")
	var path = "res://assets/portraits/extras/female_elder.png"
	var override_texture = cast.texture_for({"extra": "male_young", "portrait": path})
	check(override_texture.resource_path == path, "dedicated portrait overrides reusable category")
	game.start_battle()
	check(not cast.visible and cast.portraits.is_empty(), "battle hides all dialogue portraits")
	game.reset()
	check(not cast.visible, "reset clears dialogue presentation")
