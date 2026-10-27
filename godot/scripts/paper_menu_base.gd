extends Control
const UI=preload("res://scripts/ui.gd")
const Icons=preload("res://scripts/catalog_icons.gd")
const INK=Color("293c38")
const MUTED=Color("7d7769")
const TEAL=Color("244f4b")
const LINE=Color("c5b79c")
var content: Control
static var paper_shader: Shader
func box(parent: Node,rect: Rect2,color: Color,border: Color=Color.TRANSPARENT,radius: int=3) -> Panel:
 var panel=Panel.new();panel.position=rect.position;panel.size=rect.size
 var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=border;style.set_border_width_all(1);style.set_corner_radius_all(radius)
 panel.add_theme_stylebox_override("panel",style);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(panel);return panel
func text(parent: Node,value: String,rect: Rect2,size: int=18,color: Color=INK,brush: bool=false) -> Label:
 var node=Label.new();node.text=value;node.tooltip_text=value;node.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;node.position=rect.position;node.size=rect.size;node.add_theme_font_override("font",UI.BRUSH_FONT if brush else UI.BODY_FONT);node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",color);node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node);return node
func icon(parent: Node,id: String,rect: Rect2) -> TextureRect:
 var node=TextureRect.new();node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.texture=Icons.texture(id);node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(node);node.position=rect.position;node.size=rect.size;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;return node
func line(rect: Rect2) -> void:box(content,rect,LINE)
func button(value: String,rect: Rect2,primary: bool=false) -> Button:
 var b=Button.new();b.text=value;b.position=rect.position;b.size=rect.size;b.add_theme_font_override("font",UI.BODY_FONT);b.add_theme_font_size_override("font_size",18)
 for state in ["normal","hover","pressed","focus","disabled"]:
  var style=StyleBoxFlat.new();style.bg_color=Color("eee6d2") if state in ["hover","pressed"] and not primary else TEAL.lightened(.1) if state in ["hover","pressed"] else TEAL if primary else Color("e7ddc6");style.border_color=Color("af9b70") if state=="focus" else LINE;style.set_border_width_all(1);style.set_corner_radius_all(3)
  if state=="focus":style.bg_color=Color.TRANSPARENT;style.set_border_width_all(2)
  if state=="disabled":style.bg_color=Color("ddd7c8")
  b.add_theme_stylebox_override(state,style)
 b.add_theme_color_override("font_color",Color("f5eedb") if primary else INK);b.add_theme_color_override("font_hover_color",Color("f5eedb") if primary else INK);b.add_theme_color_override("font_disabled_color",Color("8f8b7f"));content.add_child(b);b.set_meta("primary",primary);UI.selection(b,false,true);return b
func paper(rect: Rect2,color: Color) -> void:
 var node=ColorRect.new();node.position=rect.position;node.size=rect.size
 var material=ShaderMaterial.new()
 if paper_shader==null:
  paper_shader=Shader.new()
  paper_shader.code="shader_type canvas_item; uniform vec4 paper_color : source_color; void fragment(){ vec2 p=floor(UV*vec2(1300.0,760.0)); float n=fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); float edge=pow(abs(UV.x-.5)*2.0,8.0)+pow(abs(UV.y-.5)*2.0,8.0); COLOR=vec4(paper_color.rgb+(n-.5)*.035-edge*.025,1.0); }"
 material.shader=paper_shader;material.set_shader_parameter("paper_color",color);node.material=material;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(node)
