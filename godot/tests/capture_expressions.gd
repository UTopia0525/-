extends SceneTree
const CAST=preload("res://scripts/dialogue_portraits.gd")
var game
func _initialize() -> void:run.call_deferred()
func shot(path: String) -> void:
	await create_timer(.15).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+path+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_city()
	var examples=[
		["smile",[["apothecary","고마워요. 첫 표행이라 들었는데, 벌써 손이 바쁘네요."],["hero","쉬라 할 때는 쉬겠습니다."]]],
		["angry",[["hero","그 손부터 거두시오."],["cy_tak","항주에서 흑도방 사람을 이리 세워 두고도 무사할 줄 아느냐?"]]],
		["sad",[["hero","다른 쪽으로 간 거다."],["sailor","한 번만…… 잡아 주게!"]]],
		["surprised",[["sailor","배가 붙습니다! 저 깃발…… 흑린채입니다!"],["hero","표두님!"]]]]
	for example in examples:
		game.say(example[1]);await shot("expression-dialogue-"+example[0])
	game.queue_free();await process_frame
	root.size=Vector2i(1200,1800);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var library=preload("res://scripts/portrait_expressions.gd").new();var base_paths=library.registry.portraits.keys();base_paths.sort()
	for page in range(ceili(base_paths.size()/8.0)):
		var panel=ColorRect.new();panel.color=Color("1d2928");panel.size=Vector2(root.size);root.add_child(panel)
		for row in range(mini(8,base_paths.size()-page*8)):
			var base: String=base_paths[page*8+row]
			var cast=CAST.new();root.add_child(cast)
			for col in range(5):
				var view=TextureRect.new();view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;view.position=Vector2(col*240,row*225+25);view.size=Vector2(238,198);panel.add_child(view)
				cast.apply_framing(view,{"portrait":base})
				if col>0:
					view.material.set_shader_parameter("use_expression",true);view.material.set_shader_parameter("expression_sheet",library.sheet_for(base));view.material.set_shader_parameter("expression_cell",Vector2((col-1)%2,(col-1)/2))
			var name=Label.new();name.text=base.trim_prefix("res://assets/portraits/")+"  |  기본 · 웃음 · 분노 · 슬픔 · 놀람";name.position=Vector2(10,row*225);name.add_theme_font_override("font",preload("res://scripts/ui.gd").BODY_FONT);name.add_theme_font_size_override("font_size",14);panel.add_child(name)
			cast.queue_free()
		await shot("expressions-gallery-%02d" % (page+1));panel.queue_free();await process_frame;library.cache.clear()
	print("EXPRESSION_CAPTURE: PASS");quit()
