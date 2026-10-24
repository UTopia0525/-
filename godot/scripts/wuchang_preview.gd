extends Node2D
signal closed
const UI=preload("res://scripts/ui.gd")
const MAP=preload("res://scripts/wuchang_map.gd")
var city
var player
var camera
var overview: Control
var mini: TextureRect
var map_dot: ColorRect
var overview_dot: ColorRect
var location: Label
var notice: Label
var atlas_view: SubViewport
var embedded=false
var legend_labels: Array=[]
func _ready() -> void:
	for action in {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN]}:
		if InputMap.has_action(action):continue
		InputMap.add_action(action)
		for key in {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN]}[action]:
			var event=InputEventKey.new();event.physical_keycode=key;InputMap.action_add_event(action,event)
	city=MAP.new();add_child(city)
	player=preload("res://scenes/player.tscn").instantiate();city.actors.add_child(player);player.position=city.point(city.data.spawn)
	camera=preload("res://scripts/follow_camera.gd").new();camera.exploration_zoom=1.0;player.add_child(camera);camera.set_map_bounds(city.map_bounds);camera.set_focus_height(player.display_height*.44);camera.snap_to_player()
	# A second rendering of exactly the same ground/props supplies both map views.
	atlas_view=SubViewport.new();atlas_view.world_2d=World2D.new();atlas_view.size=Vector2i(1024,768);atlas_view.render_target_update_mode=SubViewport.UPDATE_ONCE;atlas_view.handle_input_locally=false;add_child(atlas_view)
	var replica=MAP.new();replica.scale=Vector2.ONE*.125;atlas_view.add_child(replica)
	var layer=CanvasLayer.new();layer.layer=30;add_child(layer)
	var hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.theme=Theme.new();hud.theme.default_font=UI.BODY_FONT;hud.theme.default_font_size=18
	layer.add_child(hud)
	var panel=UI.panel(hud,Rect2(18,18,280,264))
	location=UI.label(panel,"무창 · 남문길",Rect2(12,8,260,30),21)
	mini=TextureRect.new();mini.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mini.texture=atlas_view.get_texture();mini.position=Vector2(12,45);mini.size=Vector2(256,192);mini.stretch_mode=TextureRect.STRETCH_SCALE;panel.add_child(mini)
	mini.mouse_filter=Control.MOUSE_FILTER_STOP
	map_dot=ColorRect.new();map_dot.color=UI.GOLD;map_dot.size=Vector2(6,6);map_dot.mouse_filter=Control.MOUSE_FILTER_IGNORE;mini.add_child(map_dot)
	UI.label(panel,"▲ 나     TAB 전체 지도",Rect2(12,237,260,25),14,UI.GOLD)
	var exit=UI.button(hud,"답사 마치기",Rect2(1080,20,180,42));exit.pressed.connect(close)
	notice=UI.label(hud,"무창 · 남문에서 들어서는 길",Rect2(335,25,700,35),24,UI.GOLD)
	UI.label(hud,"WASD / 방향키 · 클릭 이동     TAB 전체 지도     ESC 돌아가기",Rect2(25,677,1200,30),17)
	_build_overview(hud)
func _build_overview(hud: Control) -> void:
	overview=Control.new();hud.add_child(overview);overview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.panel(overview,Rect2(0,0,1280,720),Color("101c19ff"))
	UI.label(overview,"武昌 · 무창",Rect2(24,15,360,45),30,UI.GOLD)
	UI.label(overview,"장강과 강호의 성도",Rect2(25,65,190,65),20)
	UI.label(overview,"남쪽 육로로 입성\n\n북동쪽 무림맹 본단\n외원 · 대연무장 · 내원",Rect2(25,160,190,200),18,UI.MUTED)
	var image=TextureRect.new();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.texture=atlas_view.get_texture();image.position=Vector2(220,14);image.size=Vector2(840,630);image.stretch_mode=TextureRect.STRETCH_SCALE;overview.add_child(image)
	image.mouse_filter=Control.MOUSE_FILTER_STOP
	for district in city.data.districts:
		var pos=Vector2(district.label[0],district.label[1])/Vector2(2048,1536)*image.size
		var label=UI.label(image,district.name,Rect2(pos-Vector2(86,12),Vector2(172,28)),17,UI.GOLD)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_color_override("font_outline_color",Color("14231e"));label.add_theme_constant_override("outline_size",5);legend_labels.append(label)
	overview_dot=ColorRect.new();overview_dot.size=Vector2(8,8);overview_dot.color=Color("ffe6a1");image.add_child(overview_dot)
	UI.label(overview,"▲ 남문 · 장사에서 오는 길",Rect2(590,650,470,30),20,UI.GOLD)
	UI.label(overview,"TAB / ESC 돌아가기",Rect2(25,650,210,30),16)
	overview.hide()
func _process(_delta: float) -> void:
	location.text="무창 · "+city.district_at(player.position)
	map_dot.position=player.position/city.map_bounds.size*mini.size-map_dot.size/2
	overview_dot.position=player.position/city.map_bounds.size*Vector2(840,630)-overview_dot.size/2
func toggle_map() -> void:
	overview.visible=not overview.visible;player.stop();player.movement_enabled=not overview.visible
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_TAB:toggle_map();get_viewport().set_input_as_handled()
		elif event.keycode==KEY_ESCAPE:
			if overview.visible:toggle_map()
			else:close()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not overview.visible:
		player.click_path=city.path_to(player.position,get_global_mouse_position())
		notice.text="무창 · "+city.district_at(player.position) if not player.click_path.is_empty() else "담장과 건물을 돌아서 가야 합니다."
func close() -> void:
	if embedded:closed.emit();queue_free()
	else:get_tree().change_scene_to_file("res://scenes/main.tscn")
