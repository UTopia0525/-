extends SceneTree
# Mid-dialogue/counter/combat snapshots below are legacy-file compatibility fixtures.

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
	print("GODOT_DIALOGUE: " + ("FAIL" if failed else "PASS — framing, facing, saved staging, six cutouts, stable cast, overrides, cleanup"))
	quit(1 if failed else 0)

func _check_dialogues(game) -> void:
	var cast = game.dialogue_cast
	_check_framing_and_facing(game)
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

	check(not cast.visible and not game.dialogue_backdrop.visible, "reset clears dialogue presentation")
	game.start_city()
	game.say([["city_merchant", "약을 살펴보시지요."]])
	check(game.dialogue_backdrop.visible, "city conversation shades the background")
	check(game.ui_root.get_children().find(game.dialogue_backdrop) < game.ui_root.get_children().find(cast), "portraits are above background shade")
	check(game.ui_root.get_children().find(game.dialogue_backdrop) < game.ui_root.get_children().find(game.dialogue_panel), "dialogue panel is above shade")
	check(cast.portraits.city_merchant.self_modulate == Color.WHITE and cast.portraits.hero.self_modulate == PORTRAITS.DIM, "speaker and listener brightness remain independent")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1) and game.save_system.load_slot(1) and game.dialogue_backdrop.visible, "city shade restored with saved dialogue")
	game.advance_dialogue()
	check(not game.dialogue_backdrop.visible and game.exploration.active, "conversation end restores city brightness")
	game.say([["city_merchant", "다시 오셨군요."]])
	game.start_battle()
	check(not game.dialogue_backdrop.visible, "battle entry removes city shade")
	game.reset()
	game.start_story()
	check(game.dialogue_backdrop.visible, "opening dialogue shares the paper UI backdrop")
	game.reset()

func _check_framing_and_facing(game) -> void:
	var cast = game.dialogue_cast
	for actor in game.PORTRAITS.ACTORS.values():
		var texture=cast.texture_for(actor)
		check(texture!=null and cast.framing.profiles.has(texture.resource_path),"every bound character illustration has framing")
	for path in cast.framing.profiles:
		var texture: Texture2D = load(path)
		var frame: Rect2 = cast.frame_for(texture, Vector2(340, 384))
		var profile: Dictionary = cast.framing.profiles[path]
		var eye_on_screen: float = (profile.eye_y - frame.position.y) * 384 / frame.size.y
		check(absf(eye_on_screen - 80) < 0.1, "shared eye height: " + path)
		check(frame.end.y <= texture.get_height() + 0.1, "torso fills frame to its bottom: " + path)
	var constable: Texture2D = cast.texture_for(game.PORTRAITS.ACTORS.bandit_messenger)
	check(constable.resource_path.ends_with("constable-duty.png"), "all existing constable lines use new duty uniform")
	var left_flip: bool=cast.framing.profiles[constable.resource_path].natural_facing=="right"
	game.start_city()
	game.say([["bandit_messenger", "확인했습니다."], ["hero", "알겠습니다."]])
	check(not cast.portraits.hero.flip_h and cast.portraits.bandit_messenger.flip_h==left_flip, "two participants face each other")
	check(cast.portraits.bandit_messenger.texture.resource_path=="res://assets/portraits/story/constable-duty.png", "existing dialogue displays replacement uniform")
	check(cast.portraits.bandit_messenger.material is ShaderMaterial, "portrait uses normalized display material")
	game.advance_dialogue()
	check(not cast.portraits.hero.flip_h and cast.portraits.bandit_messenger.flip_h==left_flip, "speaker changes preserve facing")
	game.say([["bandit_farmer", "포졸 나리.", {"to":"bandit_messenger"}], ["hero", "그쪽 이야기를 들었습니다."]], Callable(), ["hero", "bandit_farmer", "bandit_messenger"])
	check(not cast.portraits.bandit_farmer.flip_h, "NPC can address NPC on the right rather than hero on the left")
	game.advance_dialogue()
	check(not cast.portraits.hero.flip_h and cast.portraits.bandit_farmer.flip_h, "hero replies toward previous speaker")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1) and game.save_system.load_slot(1), "save and restore inferred reply direction")
	check(not cast.portraits.hero.flip_h and cast.portraits.bandit_farmer.flip_h, "reload preserves reply facing")
	game.say([["hero", "잠깐 돌아보았다.", "혼잣말", {"facing":{"hero":"left", "bandit_messenger":"right"}}]], Callable(), ["bandit_messenger"])
	check(cast.portraits.hero.flip_h and cast.portraits.bandit_messenger.flip_h!=left_flip, "explicit line facing overrides automatic facing")
	check(game.dialogue_name.text.contains("혼잣말"), "subtitle remains compatible with staging")
	check(preload("res://tests/legacy_save_fixture.gd").write(game, 1) and game.save_system.load_slot(1), "staging and subtitle survive save")
	check(cast.portraits.hero.flip_h and cast.portraits.bandit_messenger.flip_h!=left_flip, "explicit directions survive reload")
	check(not cast.valid_staging({"to":"unknown"}) and not cast.valid_staging({"facing":{"hero":"up"}}), "invalid direction or actor rejected")
	var malformed: Dictionary = game.save_system.capture()
	malformed.dialogue.lines[0][3] = {"facing":{"hero":"up"}}
	check(not game.save_system.validate(malformed), "malformed saved staging rejected before restoration")
	game.reset()
