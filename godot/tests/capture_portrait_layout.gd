extends SceneTree
var game
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/" + name + ".png") == OK)
func group(ids: Array, name: String) -> void:
	game.say([["hero", "일러스트의 얼굴 크기와 눈높이를 확인합니다."]])
	var people: Array = []
	for id in ids:
		var person: Dictionary = game.PORTRAITS.ACTORS.get(id, {"name":id, "extra":id}).duplicate()
		person.id = id
		people.append(person)
	game.dialogue_cast.set_participants(people)
	game.dialogue_cast.set_speaker("hero")
	await shot(name)
func run() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_city()
	game.say([["bandit_messenger", "이쪽에서 집결 준비를 마치겠습니다."], ["hero", "알겠습니다. 상황이 달라지면 알려주십시오."]])
	await shot("portrait-framing-constable")
	await group(["hero", "male_young", "male_middle", "male_elder"], "portrait-framing-male")
	await group(["hero", "female_young", "female_middle", "female_elder"], "portrait-framing-female")
	await group(["hero", "city_artisan", "city_instructor", "city_merchant"], "portrait-framing-services")
	game.say([["bandit_farmer", "포졸 나리, 이 길을 다시 다닐 수 있겠소?", {"to":"bandit_messenger"}], ["hero", "저도 상황을 살피겠습니다."]], Callable(), ["hero", "bandit_farmer", "bandit_messenger"])
	await shot("portrait-facing-conversation")
	game.reset()
	await create_timer(1.0).timeout
	for voice in game.music.players:
		voice.stop()
		voice.stream = null
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	print("PORTRAIT_LAYOUT_CAPTURE: PASS")
	quit()
