extends SceneTree
var failed=false
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	if not value:failed=true;push_error("EXPRESSIONS: "+message)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	var cast=game.dialogue_cast
	for base in cast.expression_library.registry.portraits:
		var sheet=cast.expression_library.sheet_for(base)
		check(sheet!=null,"four-expression sheet exists "+base)
		if sheet:check(sheet.get_width()>=1000 and sheet.get_height()>=1000,"four portraits have enough source resolution "+base)
	for actor in game.PORTRAITS.ACTORS.values():
		var base=cast.texture_for(actor)
		check(base!=null and cast.expression_library.registry.portraits.has(base.resource_path),"all live identities including reusable NPCs are covered")
	game.start_city()
	game.say([["hero","허만복 어르신!",{"emotion":"surprised"}],["sailor","고맙네.",{"emotion":"smile"}],["hero","다른 쪽으로 간 거다."]])
	check(cast.expression_states.hero=="surprised","explicit surprise applies")
	check(cast.portrait_choices.hero.ends_with("player/hero.png"),"base identity does not change")
	game.advance_dialogue();check(cast.expression_states.sailor=="smile","NPC smiling response")
	check(cast.portraits.hero.self_modulate==cast.DIM,"listener keeps expression while dimmed")
	game.advance_dialogue();check(cast.expression_states.hero=="sad","prologue regret cue")
	check(cast.valid_staging({"emotion":"sad","emotions":{"sailor":"surprised"}}),"valid expressions in legacy dialogue staging")
	check(not cast.valid_staging({"emotion":"unknown"}),"invalid expression rejected")
	game.say([["hero","전할 말이 있소.",{"emotion":"sad"}]])
	check(preload("res://tests/legacy_save_fixture.gd").write(game,1) and game.save_system.load_slot(1),"old dialogue saves can restore expression staging")
	check(cast.expression_states.hero=="sad","restored line keeps its expression")
	game.say([["hero","묵은 일이 떠올랐소.",{"emotion":"sad"}],["sailor","오늘은 쉬어 가게.",{"emotion":"smile"}]])
	game.advance_dialogue()
	check(preload("res://tests/legacy_save_fixture.gd").write(game,1) and game.save_system.load_slot(1),"restore an expression on a silent listener")
	check(cast.expression_states.hero=="sad" and cast.expression_states.sailor=="smile","restored expressions replay only the spoken prefix")
	game.say([["hero","평상시 설명입니다."]]);check(cast.expression_states.hero=="neutral","new scene resets expression")
	var source=cast.portraits.hero.texture.resource_path
	for mood in ["smile","angry","sad","surprised","neutral"]:
		cast.set_expression("hero",mood)
		check(cast.expression_states.hero==mood,"each hero expression "+mood)
		check(cast.portraits.hero.texture.resource_path==source,"same identity/framing through expression "+mood)
	game.reset();game.queue_free();await process_frame
	print("PORTRAIT_EXPRESSIONS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
