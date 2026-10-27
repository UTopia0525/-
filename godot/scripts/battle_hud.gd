extends RefCounted
## Presentation only: the battle controller still owns decisions and calculations.
const UI=preload("res://scripts/ui.gd")
const INK=Color("283e39")
const MUTED=Color("766f5e")
const TEAL=Color("285d59")
static func card(parent: Node,rect: Rect2) -> Panel:
 var panel=UI.panel(parent,rect,Color("e9dfc9f5"))
 var style=UI.box(Color("e9dfc9f5"),Color("ac9973"));style.set_corner_radius_all(4)
 style.shadow_color=Color(0,0,0,.22);style.shadow_size=4;style.shadow_offset=Vector2(0,2)
 panel.add_theme_stylebox_override("panel",style);return panel
static func text(parent: Node,value: String,rect: Rect2,size: int=16,color: Color=INK) -> Label:
 var label=UI.label(parent,value,rect,size,color)
 label.add_theme_font_override("font",UI.BRUSH_FONT if size>=22 else UI.BODY_FONT)
 return label
static func qi_style(bar: ProgressBar) -> void:
 var style=UI.box(Color("438f9d"),Color("438f9d"))
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,0)
 bar.add_theme_stylebox_override("fill",style)
static func build(b) -> void:
 var enemy=card(b,Rect2(912,24,344,144))
 b.enemy_name=text(enemy,"흑린채 수적",Rect2(16,8,312,30),22)
 b.enemy_faction=text(enemy,"흑린채 · 일반 수적",Rect2(16,37,312,18),12,MUTED)
 text(enemy,"● 체력",Rect2(16,58,70,20),13,Color("943e37"))
 b.enemy_text=text(enemy,"",Rect2(88,58,240,20),14);b.enemy_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 b.enemy_bar=b._health_bar(enemy,Rect2(16,81,312,9),b.Rules.ENEMY_MAX_HP)
 text(enemy,"◆ 내기",Rect2(16,98,70,20),13,TEAL)
 b.enemy_qi_text=text(enemy,"",Rect2(88,98,240,20),13,TEAL);b.enemy_qi_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 b.enemy_qi_bar=b._health_bar(enemy,Rect2(16,121,312,6),500,false);qi_style(b.enemy_qi_bar)
 var intent=UI.panel(b,Rect2(912,176,344,36),Color("102b30ed"))
 b.intent_label=UI.label(intent,"",Rect2(12,5,320,26),17,UI.GOLD)
 b.intent_icon=TextureRect.new();intent.add_child(b.intent_icon);b.intent_icon.hide()
 var player=card(b,Rect2(24,390,310,124))
 text(player,"도원",Rect2(16,6,70,30),22)
 b.weapon_label=text(player,"무문철검",Rect2(90,13,204,20),13,MUTED)
 b.weapon_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 text(player,"● 체력",Rect2(16,39,70,20),13,Color("943e37"))
 b.player_text=text(player,"",Rect2(86,39,208,20),14);b.player_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 b.player_bar=b._health_bar(player,Rect2(16,63,278,9),b.Rules.PLAYER_MAX_HP)
 text(player,"◆ 내기",Rect2(16,80,70,20),13,TEAL)
 b.qi_text=text(player,"",Rect2(86,80,208,20),13,TEAL);b.qi_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 b.qi_bar=b._health_bar(player,Rect2(16,104,278,6),b.qi.MAXIMUM,false);qi_style(b.qi_bar)
 b.qi.changed.connect(b._update_qi);b.enemy_qi.changed.connect(b._update_enemy_qi);b._update_qi();b._update_enemy_qi()
 b.turn_label=UI.label(b,"나의 차례",Rect2(24,24,280,26),14,UI.GOLD)
 b.turn_label.add_theme_color_override("font_outline_color",Color("142320"));b.turn_label.add_theme_constant_override("outline_size",3)
 var description=card(b,Rect2(24,530,548,174))
 b.heading=text(description,"펼칠 무공을 고르시오",Rect2(16,10,516,30),23,TEAL)
 b.executed_icon=TextureRect.new();b.executed_icon.position=Vector2(16,10);b.executed_icon.size=Vector2(44,44)
 b.executed_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;b.executed_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 b.executed_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;description.add_child(b.executed_icon);b.executed_icon.hide()
 b.metrics=text(description,"",Rect2(16,52,516,24),15,TEAL)
 b.detail=text(description,"",Rect2(16,80,516,44),16);b.detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.note=text(description,"",Rect2(16,132,366,34),14,MUTED);b.note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 b.use_button=UI.button(description,"사용  ↵",Rect2(400,128,132,38),true);b.use_button.pressed.connect(b.use_selected)
 b.use_button.add_theme_font_size_override("font_size",16)
 for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
  var style=b.use_button.get_theme_stylebox(state).duplicate();style.content_margin_top=5;style.content_margin_bottom=5;b.use_button.add_theme_stylebox_override(state,style)
 b.use_button.size=Vector2(132,38)
 var slots=card(b,Rect2(592,530,664,174))
 text(slots,"초식 네 자리",Rect2(16,6,200,24),16,TEAL)
 var hint=text(slots,"탐험 중 K로 정비",Rect2(280,7,368,22),13,MUTED);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 for i in range(4):
  var button=UI.button(slots,"—",Rect2(16+(i%2)*324,34+(i/2)*66,308,60))
  button.add_theme_font_size_override("font_size",16);button.alignment=HORIZONTAL_ALIGNMENT_LEFT
  button.pressed.connect(b.select_slot.bind(i));b.skill_buttons.append(button)
 b.basic_button=b.skill_buttons[0];b.select_button=b.skill_buttons[2];b._update_slots()
 b.damage_label=UI.label(b,"",Rect2(930,190,200,65),48,Color("ff4f55"))
 b.damage_label.add_theme_color_override("font_shadow_color",Color("151018"))
 b.damage_label.add_theme_color_override("font_outline_color",Color("1d1018"))
 b.damage_label.add_theme_constant_override("outline_size",5)
 b.damage_label.add_theme_constant_override("shadow_offset_x",3);b.damage_label.add_theme_constant_override("shadow_offset_y",3);b.damage_label.hide()
