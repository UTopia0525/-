extends SceneTree
var failed:=false
var player
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("STRIDE_RENDER: "+message)
func frame() -> Image:
	await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func differences(a: Image,b: Image,rect: Rect2i) -> int:
	var result:=0
	rect=rect.intersection(Rect2i(Vector2i.ZERO,a.get_size())).intersection(Rect2i(Vector2i.ZERO,b.get_size()))
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if a.get_pixel(x,y)!=b.get_pixel(x,y):result+=1
	return result
func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	check(DisplayServer.get_name()!="headless","test requires real rendering")
	if failed:quit(1);return
	root.size=Vector2i(320,240)
	var background=ColorRect.new();background.color=Color("142422");background.size=root.size;root.add_child(background)
	player=load("res://scenes/player.tscn").instantiate();root.add_child(player);player.set_physics_process(false);player.position=Vector2(160,190)
	for facing in ["left","right"]:
		player.facing=facing;player.stop();player.sprite.pause();var idle=await frame()
		player._play("walk_"+facing);player.sprite.pause();player.side_material.set_shader_parameter("gait_phase",PI/2);var forward=await frame()
		player.side_material.set_shader_parameter("gait_phase",PI*1.5);var reverse=await frame()
		check(differences(forward,reverse,Rect2i(80,170,160,30))>60,"opposite strides visibly move boots: "+facing)
		check(differences(idle,forward,Rect2i(80,40,160,125))==0 and differences(forward,reverse,Rect2i(80,40,160,125))==0,"idle and walking keep identical head/torso pixels: "+facing)
		player.stop();player.sprite.pause();var stopped=await frame()
		check(differences(idle,stopped,Rect2i(60,30,200,175))==0,"stop restores identical neutral art: "+facing)
	player.free();await process_frame
	print("GODOT_SIDE_STRIDE_RENDER: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
