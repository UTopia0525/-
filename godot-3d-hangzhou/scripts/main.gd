extends Node3D
var world
var player
var title: Label
var district: Label
var fps: Label
var help: PanelContainer
var music: AudioStreamPlayer
var scenic: Camera3D
var sky_environment: WorldEnvironment
var sun: DirectionalLight3D
var night=true
var overview=false
var low_quality=false
func _ready() -> void:
 _inputs();_environment()
 world=preload("res://scripts/world.gd").new();world.name="Hangzhou";add_child(world)
 player=preload("res://scripts/player.gd").new();add_child(player)
 scenic=Camera3D.new();scenic.fov=58;scenic.far=300;add_child(scenic);scenic.position=Vector3(56,51,66);scenic.look_at(Vector3(-2,3,-5))
 _ui()
 music=AudioStreamPlayer.new();music.stream=load("res://assets/canal.ogg");music.stream.loop=true;music.volume_db=-21;add_child(music);music.play()
func _inputs() -> void:
 for spec in [["forward",KEY_W,KEY_UP],["back",KEY_S,KEY_DOWN],["left",KEY_A,KEY_LEFT],["right",KEY_D,KEY_RIGHT],["sprint",KEY_SHIFT],["jump",KEY_SPACE]]:
  InputMap.add_action(spec[0])
  for key in spec.slice(1):var event=InputEventKey.new();event.physical_keycode=key;InputMap.action_add_event(spec[0],event)
func _environment() -> void:
 sky_environment=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_SKY
 var sky=Sky.new();var material=ProceduralSkyMaterial.new();material.sky_top_color=Color("15263e");material.sky_horizon_color=Color("b38782");material.ground_horizon_color=Color("796a72");material.ground_bottom_color=Color("1d3039");sky.sky_material=material;env.sky=sky
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("9eafbd");env.ambient_light_energy=.28
 env.reflected_light_source=2;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.fog_enabled=true;env.fog_light_color=Color("536675");env.fog_density=.002;env.fog_sky_affect=.12
 sky_environment.environment=env;add_child(sky_environment)
 sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-24,-32,0);sun.light_color=Color("abc0df");sun.light_energy=.45;sun.shadow_enabled=true;sun.directional_shadow_max_distance=80;add_child(sun)
func label(parent: Node,text: String,size: int,color: Color=Color("eee4cb"),brush: bool=false) -> Label:
 var l=Label.new();l.text=text;l.add_theme_font_override("font",load("res://assets/title.ttf" if brush else "res://assets/body.ttf"));l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.add_theme_color_override("font_shadow_color",Color("0d181be0"));l.add_theme_constant_override("shadow_offset_x",2);l.add_theme_constant_override("shadow_offset_y",2);parent.add_child(l);return l
func _ui() -> void:
 var layer=CanvasLayer.new();add_child(layer)
 var root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
 title=label(root,"杭 州   ·   항주",43,Color("f5d8a0"),true);title.position=Vector2(28,17)
 district=label(root,"등불과 물길",20);district.position=Vector2(31,71)
 fps=label(root,"",15,Color("c4cbbd"));fps.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);fps.offset_left=-230;fps.offset_right=-20;fps.offset_top=24;fps.offset_bottom=74;fps.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 var bottom=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_top=-49;bottom.offset_left=22;bottom.offset_right=-22;bottom.offset_bottom=-12;root.add_child(bottom)
 var style=StyleBoxFlat.new();style.bg_color=Color("102329db");style.border_color=Color("9f865b");style.border_width_top=1;style.content_margin_left=16;style.content_margin_top=7;bottom.add_theme_stylebox_override("panel",style)
 label(bottom,"WASD 이동   ·   Shift 달리기   ·   마우스 시점   ·   휠 거리   ·   Space 뛰기   ·   Tab 전경   ·   Esc 커서   ·   F1 안내",15)
 help=PanelContainer.new();help.position=Vector2(25,125);help.custom_minimum_size=Vector2(365,265);root.add_child(help);help.add_theme_stylebox_override("panel",style);help.hide()
 var lines=VBoxContainer.new();help.add_child(lines);label(lines,"등불을 따라 걸어 보세요",29,Color("f5d8a0"),true)
 for text in ["북서쪽 높은 누각은 취월루입니다.","야시장은 물길을 따라 길게 이어집니다.","두 돌다리를 건너 맞은편 거리를 거닐고,","나루에서 유람선 갑판에 올라 보세요.","", "R 시작 위치로  ·  F3 저녁/낮  ·  F4 경량 모드  ·  M 음악", "별도 3D 탐험 테스트 · NPC/퀘스트 없음"]:label(lines,text,17)
func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_F1:help.visible=not help.visible
 elif event.keycode==KEY_TAB:
  overview=not overview;player.control_enabled=not overview;scenic.current=overview;player.camera.current=not overview
 elif event.keycode==KEY_F4:
  low_quality=not low_quality;sun.shadow_enabled=not low_quality
  get_viewport().msaa_3d=Viewport.MSAA_DISABLED if low_quality else Viewport.MSAA_2X
 elif event.keycode==KEY_M:music.stream_paused=not music.stream_paused
 elif event.keycode==KEY_F3:
  night=not night;sun.light_energy=.45 if night else 1.6;sun.rotation_degrees.x=-24 if night else -48;sky_environment.environment.ambient_light_energy=.28 if night else .9
func _process(_delta: float) -> void:
 if not is_instance_valid(player):return
 var p=player.position;var place="운하 야시장"
 if p.x< -20 and p.z< -30:place="취월루 · 비단 누각"
 elif absf(p.x)<4.5 and p.z> -4 and p.z<20:place="유람선 · 등영화방"
 elif absf(p.x)<12:place="월하교 · 두 물가를 잇는 길"
 elif p.x< -11:place="풍류거리 · 서안"
 elif p.z< -36:place="홍등장 · 북쪽 야시장"
 district.text=place
 fps.text="3D 탐험 테스트\n%d FPS" % Engine.get_frames_per_second()
