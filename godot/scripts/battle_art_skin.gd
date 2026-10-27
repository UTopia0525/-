extends RefCounted
static var sources: Dictionary={}
const UI=preload("res://scripts/ui.gd")
static func texture_style(paper: bool=false,tint: Color=Color.WHITE) -> StyleBoxTexture:
 var style=StyleBoxTexture.new()
 var key="paper" if paper else "jade"
 if not sources.has(key):
  var texture=load("res://assets/battle/premium/"+key+"-frame.png")
  sources[key]={"texture":texture,"bounds":texture.get_image().get_used_rect()}
 style.texture=sources[key].texture;style.region_rect=Rect2(sources[key].bounds);style.modulate_color=tint
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,8)
 return style
static func panel(parent: Node,area: Rect2,paper: bool=false,flip: bool=false) -> Panel:
 var node=Panel.new();node.position=area.position;node.size=area.size;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 node.add_theme_stylebox_override("panel",texture_style(paper));parent.add_child(node)
 if flip:
  node.add_theme_stylebox_override("panel",StyleBoxEmpty.new());var back=TextureRect.new();var atlas=AtlasTexture.new();atlas.atlas=sources["paper" if paper else "jade"].texture;atlas.region=Rect2(sources["paper" if paper else "jade"].bounds)
  back.texture=atlas;back.flip_h=true;back.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;back.size=area.size;back.mouse_filter=Control.MOUSE_FILTER_IGNORE;node.add_child(back)
 return node
static func button(parent: Node,value: String,area: Rect2) -> Button:
 var b=UI.button(parent,value,area);b.add_theme_font_size_override("font_size",20)
 for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
  var tint=Color(1.28,1.22,1.04) if state in ["hover","focus","hover_pressed"] else Color(.65,.7,.68) if state=="disabled" else Color.WHITE
  b.add_theme_stylebox_override(state,texture_style(false,tint))
 b.add_theme_color_override("font_color",Color("f3ebd1"));b.add_theme_font_override("font",UI.BODY_FONT)
 return b
static func selection(b: Button,selected: bool) -> void:
 b.add_theme_stylebox_override("normal",texture_style(false,Color(1.35,1.26,1.06) if selected else Color.WHITE))
