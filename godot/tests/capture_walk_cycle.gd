extends SceneTree
const UI=preload("res://scripts/ui.gd")
var players=[]
func _initialize() -> void:run.call_deferred()
func shot(path: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK)
func make_player(direction: String,point: Vector2,walking: bool):
	var p=load("res://scenes/player.tscn").instantiate();root.add_child(p);p.set_physics_process(false);p.set_display_height(180);p.facing=direction;p.position=point;p._play(("walk_" if walking else "idle_")+direction);p.sprite.pause();return p
func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size=Vector2i(1080,620)
	var back=ColorRect.new();back.size=root.size;back.color=Color("142422");root.add_child(back)
	UI.label(root,"가로 걷기 · 같은 몸체 크기와 교차 보행",Rect2(24,16,1000,40),25,UI.GOLD)
	for y in range(2):
		var direction="right" if y==0 else "left"
		for x in range(6):
			var moving=x>0 and x<5;var p=make_player(direction,Vector2(90+x*180,285+y*275),moving)
			if moving:p.side_material.set_shader_parameter("gait_phase",(x-1)*PI/2)
			UI.label(root,"정지" if not moving else "걸음 %d" % x,Rect2(38+x*180,61+y*275,110,28),18,UI.TEXT)
			var line=ColorRect.new();line.color=Color("bda573");line.position=Vector2(35+x*180,285+y*275);line.size=Vector2(110,1);root.add_child(line);players.append(p)
	await shot("res://screenshots/walk-cycle-side.png")
	for p in players:p.free()
	for node in root.get_children():node.queue_free()
	await process_frame;root.size=Vector2i(640,360)
	back=ColorRect.new();back.size=root.size;back.color=Color("142422");root.add_child(back)
	UI.label(root,"고정 크기 · 발 교차 보행",Rect2(20,12,600,35),24,UI.GOLD)
	var left=make_player("left",Vector2(185,280),true);var right=make_player("right",Vector2(455,280),true)
	DirAccess.make_dir_recursive_absolute("/tmp/murim-walk-frames")
	for i in range(24):
		var phase=TAU*float(i)/24
		left.side_material.set_shader_parameter("gait_phase",phase);right.side_material.set_shader_parameter("gait_phase",phase)
		await shot("/tmp/murim-walk-frames/frame-%02d.png" % i)
	quit()
