extends RefCounted
const UI=preload("res://scripts/ui.gd")
const H=preload("res://scripts/battle_hud.gd")
const ArtSkin=preload("res://scripts/battle_art_skin.gd")
static func build(b) -> void:
 b.grid_ui=Control.new();b.grid_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);b.grid_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(b.grid_ui)
 for index in range(2):
  var panel=ArtSkin.panel(b.grid_ui,Rect2(16 if index==0 else 902,18,362,136),true,index==1)
  var portrait=TextureRect.new();portrait.position=Vector2(12 if index==0 else 254,12);portrait.size=Vector2(94,110)
  var original=load("res://assets/portraits/player/hero.png" if index==0 else "res://assets/portraits/archetypes/bandit.png")
  var atlas=AtlasTexture.new();atlas.atlas=original;atlas.region=Rect2(0,0,original.get_width(),original.get_height()*.64)
  portrait.texture=atlas;portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(portrait)
  var x=112 if index==0 else 16
  var name_label=H.text(panel,"도원" if index==0 else "상대",Rect2(x,10,232,28),25)
  name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  var weapon=H.text(panel,"",Rect2(x,37,232,17),11)
  var hp=H.text(panel,"",Rect2(x,55,232,18),12)
  var bar=b._health_bar(panel,Rect2(x,75,232,6),300)
  var qi=H.text(panel,"",Rect2(x,84,232,17),12,H.TEAL)
  var gauge=H.text(panel,"",Rect2(x,104,232,19),13,H.TEAL)
  var gauge_bar=ProgressBar.new();gauge_bar.position=Vector2(x,125);gauge_bar.show_percentage=false;gauge_bar.add_theme_font_size_override("font_size",1);gauge_bar.max_value=100
  var flat=StyleBoxFlat.new();flat.bg_color=Color("528d79");gauge_bar.add_theme_stylebox_override("fill",flat);panel.add_child(gauge_bar);gauge_bar.size=Vector2(232,2);gauge_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var stats=H.text(panel,"",Rect2(x,128,232,1),10);stats.hide()
  b.status_cards.append({"portrait":portrait,"name":name_label,"weapon":weapon,"hp":hp,"bar":bar,"qi":qi,"gauge":gauge,"gauge_bar":gauge_bar,"stats":stats})
  if index==0:b.player_bar=bar;b.player_text=hp;b.qi_text=qi;b.weapon_label=weapon
  else:b.enemy_bar=bar;b.enemy_text=hp;b.enemy_qi_text=qi;b.enemy_name=name_label
 ArtSkin.panel(b.grid_ui,Rect2(434,22,412,60))
 b.phase_label=H.text(b.grid_ui,"교전 준비",Rect2(453,35,374,32),24,UI.GOLD);b.phase_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 b.clock_label=H.text(b.grid_ui,"",Rect2(446,88,388,36),12,UI.TEXT);b.clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 b.clock_label.add_theme_color_override("font_outline_color",Color("071912"));b.clock_label.add_theme_constant_override("outline_size",3)
 b.field_label=H.text(b.grid_ui,"",Rect2(490,129,300,22),12,UI.TEXT);b.field_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var left=ArtSkin.panel(b.grid_ui,Rect2(16,493,252,203),true)
 H.text(left,"보법",Rect2(22,13,208,38),30)
 H.text(left,"상하좌우 한 칸 이동",Rect2(22,57,208,24),15)
 H.text(left,"↑\n←   ·   →\n↓",Rect2(52,83,150,70),20,H.TEAL).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 H.text(left,"R 방향 · B 공격 · G 대기",Rect2(30,165,204,22),12)
 var panel=ArtSkin.panel(b.grid_ui,Rect2(288,551,612,145))
 b.heading=H.text(panel,"발걸음을 고르시오",Rect2(22,12,568,29),24,UI.GOLD)
 b.metrics=H.text(panel,"",Rect2(22,45,568,24),17,UI.TEXT)
 b.detail=H.text(panel,"",Rect2(22,75,403,33),13,UI.TEXT);b.detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.note=H.text(panel,"",Rect2(22,112,410,22),11,UI.GOLD);b.note.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 b.use_button=ArtSkin.button(panel,"출수 ↵",Rect2(449,84,143,45));b.use_button.pressed.connect(b.use_selected)
 ArtSkin.panel(b.grid_ui,Rect2(924,466,340,230));b.skill_buttons.clear()
 var movement=ArtSkin.button(b.grid_ui,"이동",Rect2(936,476,316,52));movement.pressed.connect(b.utility.bind(0));b.utility_buttons.append(movement)
 for i in range(4):
  var button=ArtSkin.button(b.grid_ui,"",Rect2(936+(i%2)*161,535+(i/2)*75,155,70))
  button.add_theme_font_size_override("font_size",18);button.alignment=HORIZONTAL_ALIGNMENT_LEFT
  button.pressed.connect(b.select_slot.bind(i));b.skill_buttons.append(button)
 b.basic_button=b.skill_buttons[0];b.select_button=b.skill_buttons[2]
