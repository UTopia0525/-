extends SceneTree
const UI=preload("res://scripts/ui.gd")
var game
func _initialize() -> void:run.call_deferred()
func frames() -> void:
	await create_timer(.2).timeout
	for i in range(4):await process_frame;await RenderingServer.frame_post_draw
func overview(area: String,script: String,size: Vector2i,factor: float) -> void:
	var w=game.exploration;w.load_area(area)
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=size;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var map=load(script).new();view.add_child(map);map.scale=Vector2.ONE/factor
	for npc in w.ambient_nodes:
		var node=Node2D.new();node.position=npc.position;map.actors.add_child(node)
		node.add_child(npc.get_child(1).duplicate())
		var text=UI.label(node,npc.get_meta("display_name"),Rect2(-150,8,300,46),int(16*factor),Color("ffe6aa"));text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_color_override("font_outline_color",Color("17201b"));text.add_theme_constant_override("outline_size",int(2*factor))
	await frames();assert(view.get_texture().get_image().save_png("res://screenshots/"+area.replace("_","-")+"-residents.png")==OK)
	view.queue_free();await process_frame
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
	await overview("hangzhou","res://scripts/hangzhou_map.gd",Vector2i(1760,1280),3.2)
	await overview("cuiyue_hall","res://scripts/cuiyue_hall_map.gd",Vector2i(1536,1024),2)
	var w=game.exploration
	for id in ["cy_manager","cy_pipa","cy_dancer"]:
		var n=w.decorations.get_node(id);w.player.position=w.safe_player_position(n.position+Vector2(110,90));w.player.stop();w.camera.snap_to_player()
		var entry=w.city_data.residents.filter(func(e):return e.id==id)[0]
		game.say([[id,entry.dialogue[0][1]],["hero","이곳의 풍경을 조금 둘러보겠소."]])
		await frames();assert(root.get_texture().get_image().save_png("res://screenshots/"+id+"-dialogue.png")==OK)
		while not game.dialogue_lines.is_empty():game.advance_dialogue()
	# A comparison sheet combines original portraits and actual exploration sprites.
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(1440,1000);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var bg=ColorRect.new();bg.size=view.size;bg.color=Color("182621");view.add_child(bg)
	for i in range(3):
		var id=["cy_manager","cy_pipa","cy_dancer"][i];var n=w.decorations.get_node(id)
		var entry=w.city_data.residents.filter(func(e):return e.id==id)[0]
		var image=TextureRect.new();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.texture=load(entry.portrait);image.position=Vector2(i*480+20,20);image.size=Vector2(440,650);image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;view.add_child(image)
		var dot=n.get_child(1).duplicate();dot.position=Vector2(i*480+240,940);dot.scale*=1.6;view.add_child(dot)
		var label=UI.label(view,entry.name+" · "+entry.role,Rect2(i*480+10,680,460,42),24,UI.GOLD);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	await frames();assert(view.get_texture().get_image().save_png("res://screenshots/cuiyue-character-sheet.png")==OK)
	view.queue_free();game.queue_free();await process_frame;print("HANGZHOU_RESIDENT_CAPTURE: PASS");quit()
