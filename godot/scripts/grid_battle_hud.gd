extends RefCounted
const UI=preload("res://scripts/ui.gd")
const H=preload("res://scripts/battle_hud.gd")
static func build(b) -> void:
 b.grid_ui=Control.new();b.grid_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);b.grid_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(b.grid_ui)
 for index in range(2):
  var panel=H.card(b.grid_ui,Rect2(24 if index==0 else 896,22,360,141))
  var name_label=H.text(panel,"도원" if index==0 else "상대",Rect2(14,5,204,28),23)
  var weapon=H.text(panel,"",Rect2(226,12,118,20),12);weapon.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  var hp=H.text(panel,"",Rect2(14,36,332,19),13)
  var bar=b._health_bar(panel,Rect2(14,58,332,8),300)
  var qi=H.text(panel,"",Rect2(14,71,332,18),13,H.TEAL)
  var gauge=H.text(panel,"",Rect2(14,94,332,19),14,H.TEAL)
  var gauge_bar=ProgressBar.new();gauge_bar.position=Vector2(14,115);gauge_bar.size=Vector2(332,3);gauge_bar.show_percentage=false;gauge_bar.add_theme_font_size_override("font_size",1);gauge_bar.max_value=100;gauge_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var flat=StyleBoxFlat.new();flat.bg_color=Color("467b68");gauge_bar.add_theme_stylebox_override("fill",flat);var background=StyleBoxFlat.new();background.bg_color=Color("b8ad94");gauge_bar.add_theme_stylebox_override("background",background);panel.add_child(gauge_bar);gauge_bar.size=Vector2(332,3)
  var stats=H.text(panel,"",Rect2(14,119,334,17),11,H.MUTED)
  b.status_cards.append({"name":name_label,"weapon":weapon,"hp":hp,"bar":bar,"qi":qi,"gauge":gauge,"gauge_bar":gauge_bar,"stats":stats})
  if index==0:b.player_bar=bar;b.player_text=hp;b.qi_text=qi;b.weapon_label=weapon
  else:b.enemy_bar=bar;b.enemy_text=hp;b.enemy_qi_text=qi;b.enemy_name=name_label
 UI.panel(b.grid_ui,Rect2(402,22,476,142),Color("102924e8"))
 b.phase_label=H.text(b.grid_ui,"교전 준비",Rect2(402,28,476,35),24,UI.GOLD);b.phase_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 b.clock_label=H.text(b.grid_ui,"",Rect2(402,65,476,65),14,UI.TEXT);b.clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.clock_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.field_label=H.text(b.grid_ui,"",Rect2(390,143,500,24),13,UI.TEXT);b.field_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var panel=H.card(b.grid_ui,Rect2(24,536,548,168))
 b.heading=H.text(panel,"발걸음을 고르시오",Rect2(16,8,516,30),23,H.TEAL)
 b.metrics=H.text(panel,"",Rect2(16,42,516,22),15,H.TEAL)
 b.detail=H.text(panel,"",Rect2(16,69,516,47),14);b.detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.note=H.text(panel,"",Rect2(16,120,350,37),13,H.MUTED);b.note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.use_button=UI.button(panel,"출수 ↵",Rect2(389,117,143,40),true);b.use_button.pressed.connect(b.use_selected);b.use_button.add_theme_font_size_override("font_size",16)
 for state in ["normal","hover","pressed","focus","disabled"]:
  var style=b.use_button.get_theme_stylebox(state).duplicate();style.content_margin_top=5;style.content_margin_bottom=5;b.use_button.add_theme_stylebox_override(state,style)
 var slots=H.card(b.grid_ui,Rect2(592,536,664,168));b.skill_buttons.clear()
 H.text(slots,"편성한 초식",Rect2(16,4,330,23),16,H.TEAL)
 for i in range(4):
  var button=UI.button(slots,"",Rect2(16+(i%2)*324,31+(i/2)*65,308,58));button.add_theme_font_size_override("font_size",15)
  button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.pressed.connect(b.select_slot.bind(i));b.skill_buttons.append(button)
 b.basic_button=b.skill_buttons[0];b.select_button=b.skill_buttons[2]
 for i in range(4):
  var value=["이동 · WASD","방향 전환 · R","기본공격","숨 고르기"][i]
  var button=UI.button(b.grid_ui,value,Rect2(24+i*173,493,163,34));button.add_theme_font_size_override("font_size",13)
  for state in ["normal","hover","pressed","focus","disabled"]:
   var style=button.get_theme_stylebox(state).duplicate();style.content_margin_top=4;style.content_margin_bottom=4;button.add_theme_stylebox_override(state,style)
  button.pressed.connect(b.utility.bind(i));b.utility_buttons.append(button)
 H.text(b.grid_ui,"청록 이동 · 주홍 공격 · 방향을 고른 뒤 출수 · L 교전 기록",Rect2(745,500,510,24),12,UI.TEXT)
