extends Control
## Review-only UI rendered with shipped portraits, icons, fonts and catalogue data.
const UI=preload("res://scripts/ui.gd")
const Icons=preload("res://scripts/catalog_icons.gd")
const INK=Color("293c38")
const MUTED=Color("7d7769")
const TEAL=Color("244f4b")
const LINE=Color("c5b79c")
var mode:="inventory"
var content: Control
var progress=preload("res://scripts/player_progress.gd").new()
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 progress.stats={"strength":20,"agility":20,"constitution":20,"inner":20,"insight":20}
 show_mode(mode)
func box(parent: Node,rect: Rect2,color: Color,border: Color=Color.TRANSPARENT,radius: int=3) -> Panel:
 var panel=Panel.new();panel.position=rect.position;panel.size=rect.size
 var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=border;style.set_border_width_all(1);style.set_corner_radius_all(radius)
 panel.add_theme_stylebox_override("panel",style);parent.add_child(panel);return panel
func text(parent: Node,value: String,rect: Rect2,size: int=18,color: Color=INK,brush: bool=false) -> Label:
 var node=Label.new();node.text=value;node.position=rect.position;node.size=rect.size;node.add_theme_font_override("font",UI.BRUSH_FONT if brush else UI.BODY_FONT);node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",color);parent.add_child(node);return node
func icon(parent: Node,id: String,rect: Rect2) -> TextureRect:
 var node=TextureRect.new();node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.texture=Icons.texture(id);node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(node);node.position=rect.position;node.size=rect.size;return node
func line(rect: Rect2) -> void:box(content,rect,LINE)
func button(value: String,rect: Rect2,primary: bool=false) -> Button:
 var b=Button.new();b.text=value;b.position=rect.position;b.size=rect.size;b.add_theme_font_override("font",UI.BODY_FONT);b.add_theme_font_size_override("font_size",18)
 for state in ["normal","hover","pressed","focus"]:
  var style=StyleBoxFlat.new();style.bg_color=TEAL.lightened(.1) if state in ["hover","pressed"] else TEAL if primary else Color("e7ddc6");style.border_color=Color("af9b70") if state=="focus" else LINE;style.set_border_width_all(1);style.set_corner_radius_all(3);b.add_theme_stylebox_override(state,style)
 b.add_theme_color_override("font_color",Color("f5eedb") if primary else INK);b.add_theme_color_override("font_hover_color",Color("f5eedb"));content.add_child(b);return b
func paper(rect: Rect2,color: Color) -> void:
 var node=ColorRect.new();node.position=rect.position;node.size=rect.size
 var material=ShaderMaterial.new();var shader=Shader.new()
 shader.code="shader_type canvas_item; uniform vec4 paper_color : source_color; void fragment(){ vec2 p=floor(UV*vec2(1300.0,760.0)); float n=fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); float edge=pow(abs(UV.x-.5)*2.0,8.0)+pow(abs(UV.y-.5)*2.0,8.0); COLOR=vec4(paper_color.rgb+(n-.5)*.035-edge*.025,1.0); }"
 material.shader=shader;material.set_shader_parameter("paper_color",color);node.material=material;content.add_child(node)
func show_mode(value: String) -> void:
 mode=value
 if content!=null:remove_child(content);content.queue_free()
 content=Control.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(content)
 var bg=TextureRect.new();bg.texture=preload("res://assets/dock.png");bg.size=Vector2(1280,720);bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;bg.modulate=Color(.25,.28,.25);content.add_child(bg)
 box(content,Rect2(48,29,1184,666),Color("080e0ed9"),Color("786b50"),5)
 paper(Rect2(58,36,1164,648),Color("eee5cf"))
 text(content,"소지품" if mode=="inventory" else "무공",Rect2(88,53,240,52),38,INK,true)
 text(content,"여정에 필요한 것들을 갖추다" if mode=="inventory" else "실전에 펼칠 네 가지 초식",Rect2(245,66,500,30),17,MUTED)
 text(content,"도원  ·  절정",Rect2(863,64,170,30),18,INK)
 text(content,"◎  1,250문",Rect2(1060,64,150,30),19,INK)
 line(Rect2(88,113,1104,1));line(Rect2(88,639,1104,1))
 button("소지품  I",Rect2(88,648,122,28),mode=="inventory").pressed.connect(show_mode.bind("inventory"))
 button("무공  K",Rect2(218,648,112,28),mode=="martial").pressed.connect(show_mode.bind("martial"))
 text(content,"검토용 화면 · 기존 일러스트 / 아이콘 사용",Rect2(385,651,560,23),13,MUTED)
 text(content,"ESC  닫기",Rect2(1085,651,120,23),15,MUTED)
 if mode=="inventory":inventory()
 else:martial()
func inventory() -> void:
 var portrait=TextureRect.new();portrait.position=Vector2(88,148);portrait.size=Vector2(245,275);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;content.add_child(portrait)
 var framing=preload("res://scripts/dialogue_portraits.gd").new()
 framing.apply_framing(portrait,{"portrait":"res://assets/portraits/player/hero.png"});framing.free()
 text(content,"도원",Rect2(110,425,200,40),28,INK,true)
 text(content,"장착 무기",Rect2(110,479,170,25),15,MUTED)
 box(content,Rect2(104,514,222,87),Color("e3d8be"),LINE)
 icon(content,"plain_iron_sword",Rect2(110,520,70,70));text(content,"무문철검",Rect2(190,533,125,28),20,INK)
 text(content,"검  ·  장착 중",Rect2(190,567,125,22),14,MUTED)
 line(Rect2(352,146,1,463))
 for i in range(5):
  button(["전체","무기","영약","서적","의뢰"][i],Rect2(377+i*71,143,65,35),i==0)
 var ids=["refined_sword","thickback_saber","balanced_spear","plain_iron_sword","bear_strength_pill","light_step_pill","swaerang_manual","bone_fortifying_pill","qi_nourishing_pill"]
 for i in range(ids.size()):
  var pos=Vector2(379+(i%3)*115,199+(i/3)*117)
  box(content,Rect2(pos,Vector2(103,103)),Color("f4eddb") if i==0 else Color("e5dac2"),TEAL if i==0 else LINE)
  icon(content,ids[i],Rect2(pos+Vector2(12,10),Vector2(80,79)))
  if i==0:box(content,Rect2(pos+Vector2(4,4),Vector2(4,95)),TEAL)
  if i>=4 and i!=6:
   box(content,Rect2(pos+Vector2(62,77),Vector2(35,21)),Color("f4eddb"),LINE)
   text(content,"×3",Rect2(pos+Vector2(66,77),Vector2(30,21)),14,INK)
 text(content,"무기를 선택하면 장착 상태와 비교합니다.",Rect2(378,571,360,46),14,MUTED)
 line(Rect2(747,147,1,460))
 text(content,"정련검",Rect2(785,154,280,48),32,INK,true)
 text(content,"검  /  하급",Rect2(787,205,250,28),16,MUTED)
 icon(content,"refined_sword",Rect2(1058,157,104,104))
 text(content,"고르게 벼린 날과 안정적인 무게 중심.",Rect2(787,267,400,28),17,INK)
 line(Rect2(787,314,373,1))
 text(content,"공격 보정",Rect2(787,338,200,30),19,INK);text(content,"+5%",Rect2(1091,335,80,35),26,TEAL)
 text(content,"받는 피해",Rect2(787,385,200,30),19,INK);text(content,"−3%",Rect2(1091,382,80,35),26,TEAL)
 box(content,Rect2(787,444,373,87),Color("e3d8be"))
 text(content,"현재 장비  ·  무문철검",Rect2(802,454,340,24),15,MUTED)
 text(content,"공격 보정 +5%p     피해 감소 +3%p",Rect2(802,490,350,25),17,TEAL)
 button("정련검 장착",Rect2(787,558,373,46),true)
func martial() -> void:
 var ids=["basic_attack","basic_defense","samjae","swaerang"]
 for i in range(4):
  var pos=Vector2(90+i*277,139)
  box(content,Rect2(pos,Vector2(261,113)),Color("f4eedf") if i==3 else Color("e5dac2"),TEAL if i==3 else LINE)
  icon(content,ids[i],Rect2(pos+Vector2(11,13),Vector2(82,82)))
  text(content,str(i+1),Rect2(pos+Vector2(220,9),Vector2(30,25)),16,MUTED)
  text(content,progress.arts.get_skill(ids[i]).name,Rect2(pos+Vector2(106,44),Vector2(150,36)),21,INK)
  if i==3:box(content,Rect2(pos+Vector2(4,4),Vector2(253,3)),TEAL)
 for i in range(7):button(["전체","검","도","창","권","장","보조"][i],Rect2(90+i*68,277,62,32),i==0)
 var list=["samjae","paak","swaerang","gwanak"]
 for i in range(4):
  var pos=Vector2(90,331+i*68)
  box(content,Rect2(pos,Vector2(466,59)),Color("d7dfd3") if i==2 else Color("e7ddc7"),TEAL if i==2 else LINE)
  icon(content,list[i],Rect2(pos+Vector2(9,5),Vector2(50,50)))
  text(content,progress.arts.get_skill(list[i]).name,Rect2(pos+Vector2(78,13),Vector2(245,33)),20,INK)
  text(content,"편성 4" if i==2 else "검" if i==0 else "창" if i==3 else "도",Rect2(pos+Vector2(366,18),Vector2(91,23)),15,TEAL if i==2 else MUTED)
 line(Rect2(595,279,1,325))
 text(content,"쇄랑도법",Rect2(633,278,370,46),33,INK,true)
 text(content,"도법  /  중급",Rect2(635,327,300,25),16,MUTED)
 icon(content,"swaerang",Rect2(1049,276,110,95))
 var values=["300","22","도"]
 for i in range(3):
  var pos=Vector2(635+i*180,378)
  box(content,Rect2(pos,Vector2(165,84)),Color("e4dac4"))
  text(content,["위력 · 보정 전","내기 소모","필요 무기"][i],Rect2(pos+Vector2(13,8),Vector2(143,24)),14,MUTED)
  text(content,values[i],Rect2(pos+Vector2(13,35),Vector2(143,40)),29,INK)
 text(content,"근력×8  +  기민×5  +  근골×2",Rect2(636,481,530,30),19,INK)
 text(content,"!  도 장착 필요 · 현재 무문철검 장착",Rect2(636,520,530,25),16,Color("9c4b3d"))
 button("4번 칸에 편성",Rect2(635,565,525,44),true)
func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_I:show_mode("inventory")
 elif event.keycode==KEY_K:show_mode("martial")
