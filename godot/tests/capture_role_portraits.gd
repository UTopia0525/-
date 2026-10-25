extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func show_speaker(id: String) -> void:
	while game.dialogue_lines[game.dialogue_index][0]!=id:game.advance_dialogue()
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"])
	game.start_city()
	game.bandit_story.play("briefing",Callable())
	show_speaker("bandit_raider");await shot("role-bandit-dialogue")
	game.reset();game.start_story()
	game.exploration.load_area("deck")
	var prologue=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue_dialogues.json"))
	game.say(prologue.deck.lines)
	show_speaker("pirate");await shot("role-water-bandit-dialogue")
	game.reset();game.start_wuchang()
	game.say(game.inn_quest.data.scenes.warrior)
	await shot("role-wanderer-dialogue")
	game.say([["hero","청애채의 두 산적"],["qy_hou_liu","길을 지키는 데도 쌀이 든다."],["qy_ding_kui","용건부터 밝히시오."]])
	show_speaker("qy_hou_liu");await shot("role-bandit-pair-dialogue")
	game.reset();await create_timer(.3).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;quit()
