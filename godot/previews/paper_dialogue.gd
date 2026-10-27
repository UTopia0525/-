extends "res://scripts/paper_menu_base.gd"
## Dialogue composition review only. Does not change story or runtime cast layout.
var game
var cast_helper
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 cast_helper=preload("res://scripts/dialogue_portraits.gd").new()
func _exit_tree() -> void:
 if is_instance_valid(cast_helper):cast_helper.free()
func scene_for(kind: String) -> void:
 if is_instance_valid(content):remove_child(content);content.queue_free()
 content=Control.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(content)
 var shade=ColorRect.new();shade.color=Color(0.025,.045,.04,.64);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.add_child(shade)
 var ids: Array=[];var speaker: String;var quote: String;var place: String
 match kind:
  "pair":
   ids=["namgung_yeonseo"];speaker="namgung_yeonseo";place="남경 · 구휼 배분처"
   quote="배분 기록은 제가 확인하겠습니다. 도원 공자께서는 주민들이 실제로 받은 몫을 알아봐 주시겠어요?"
  "group":
   ids=["nj_crowd_book_buyer","nj_bookseller"];speaker="nj_bookseller";place="남경 · 서책거리"
   quote="진학명이 베낀 장이오. 글씨가 반듯하지? 이제 그 책에는 저 아이 손도 남았소."
  "hero":
   ids=["nj_crowd_book_buyer","nj_bookseller"];speaker="hero";place="남경 · 서책거리"
   quote="이제야 빌린 책이 돌아왔구려. 책에 담긴 뜻도 허투루 쓰지 않겠소."
  _:
   ids=["nj_vendor","nj_crowd_clerk_runner","nj_constable"];speaker="nj_constable";place="남경 · 관아 앞"
   quote="징수표와 돈을 대조하고 있소. 관의 이름을 내세우는 자가 있거든 내게 확인하시오."
 text(content,place,Rect2(62,28,650,30),17,Color("d9ccae"))
 text(content,"대화창 UI 검토",Rect2(1035,28,190,27),14,Color("a7ada1"))
 var portraits=Control.new();portraits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.add_child(portraits)
 var actors=["hero"]+ids;var choices={}
 for i in range(actors.size()):
  var id: String=actors[i];var data: Dictionary=game.PORTRAITS.ACTORS[id].duplicate()
  var x=61.0;var width=310.0
  if i>0:
   width=320.0 if ids.size()==1 else 285.0 if ids.size()==2 else 260.0
   x=870.0 if ids.size()==1 else 681.0+(i-1)*242 if ids.size()==2 else 526.0+(i-1)*218
  var view=TextureRect.new();view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portraits.add_child(view);view.position=Vector2(x,143);view.size=Vector2(width,372)
  cast_helper.apply_framing(view,data)
  var path: String=view.texture.resource_path if view.texture else ""
  assert(not path.is_empty() and not choices.has(path));choices[path]=true
  var natural: String=cast_helper.framing.profiles.get(path,{}).get("natural_facing","right")
  view.flip_h=natural!=("right" if id=="hero" else "left")
  view.self_modulate=Color.WHITE if id==speaker else Color(.48,.50,.49)
  view.z_index=1 if id==speaker else 0
  var label=text(portraits,data.name,Rect2(x,483,width,31),18,Color("ead8ad") if id==speaker else Color("b3b8aa"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_color_override("font_outline_color",Color("13221d"));label.add_theme_constant_override("outline_size",4);label.z_index=2
 box(content,Rect2(49,525,1182,173),Color("0b1715dc"),Color("9a8969"),4)
 paper(Rect2(58,532,1164,157),Color("eee5cf"))
 box(content,Rect2(86,511,201,39),TEAL,Color("8d805f"),2)
 var speaker_name=text(content,game.PORTRAITS.ACTORS[speaker].name,Rect2(100,514,173,32),25,Color("f3e8d2"),true);speaker_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var line_text=RichTextLabel.new();line_text.position=Vector2(91,564);line_text.size=Vector2(1091,64);line_text.bbcode_enabled=false;line_text.add_theme_font_override("normal_font",UI.BODY_FONT);line_text.add_theme_font_size_override("normal_font_size",23);line_text.add_theme_color_override("default_color",INK);line_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line_text.text=quote;content.add_child(line_text)
 box(content,Rect2(91,642,1090,1),LINE)
 text(content,"F  다음 대사",Rect2(92,654,175,25),15,MUTED)
 text(content,"H  지난 대화",Rect2(267,654,175,25),15,MUTED)
 text(content,"배치·미감 검토용 · 현재 게임의 일러스트 사용",Rect2(635,656,425,24),13,MUTED)
 button("다음  ▸",Rect2(1082,651,100,29),true)
