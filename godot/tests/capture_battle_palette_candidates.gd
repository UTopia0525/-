extends SceneTree
## Review-only recolouring of live controls. Production palettes stay unchanged.
const UI=preload("res://scripts/ui.gd")
const HUD=preload("res://scripts/battle_hud.gd")
const PALETTES=[
 {"id":"a","title":"A · 먹빛 청록","bg":"112b2ff2","slot":"102225","selected":"2d5552","border":"68877b","text":"e7e7dc","muted":"a8b9b0","accent":"bad2bf","qi":"8bcbd1","hp":"f29a8b"},
 {"id":"b","title":"B · 청회색","bg":"1c283bf2","slot":"162135","selected":"344e6b","border":"738aa7","text":"e5e9f0","muted":"acb8ca","accent":"b5cbe6","qi":"91bddc","hp":"f29a9a"},
 {"id":"c","title":"C · 흑갈색 동빛","bg":"30251ff2","slot":"261d19","selected":"594234","border":"967853","text":"f0e6d6","muted":"c8b49b","accent":"dcba83","qi":"8ec8c1","hp":"f2a18d"}
]
var game
var colors: Dictionary={}
var title: Label
func _initialize() -> void:run.call_deferred()
func recolor_label(label: Label,p: Dictionary) -> void:
 var original: Color=colors[label]
 var result=original
 if original==HUD.INK:result=Color(p.text)
 elif original==HUD.MUTED:result=Color(p.muted)
 elif original==HUD.TEAL or original==UI.GOLD:result=Color(p.accent)
 elif original==Color("943e37"):result=Color(p.hp)
 label.add_theme_color_override("font_color",result)
 if label.text.begins_with("◆") or label in [game.battle.qi_text,game.battle.enemy_qi_text]:label.add_theme_color_override("font_color",Color(p.qi))
func recolor_button(button: Button,p: Dictionary) -> void:
 var primary: bool=button.get_meta("primary",false)
 var selected: bool=button.get_meta("selected",false)
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
  var style: StyleBoxFlat=button.get_theme_stylebox(state).duplicate()
  style.bg_color=Color(p.accent) if primary else Color(p.selected) if selected else Color(p.slot)
  style.border_color=Color(p.accent) if primary or selected else Color(p.border)
  if state in ["hover","hover_pressed","pressed"]:style.bg_color=style.bg_color.lightened(.07)
  if state=="disabled":style.bg_color=Color(p.slot);style.border_color=Color(p.border).darkened(.3)
  if state=="focus":style.bg_color=Color.TRANSPARENT;style.border_color=Color("ebcd92")
  button.add_theme_stylebox_override(state,style)
 for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:button.add_theme_color_override(state,Color(p.bg) if primary else Color(p.text))
 button.add_theme_color_override("font_disabled_color",Color(p.muted).darkened(.2))
 if button.has_node("SelectionMark"):button.get_node("SelectionMark").color=Color(p.accent)
func apply_palette(p: Dictionary) -> void:
 var b=game.battle
 for panel in b.find_children("*","Panel",true,false):
  var style: StyleBoxFlat=panel.get_theme_stylebox("panel").duplicate()
  style.bg_color=Color(p.bg);style.border_color=Color(p.border)
  panel.add_theme_stylebox_override("panel",style)
 for label in colors:recolor_label(label,p)
 for button in b.find_children("*","Button",true,false):recolor_button(button,p)
 recolor_button(game.settings_menu.gear,p)
 for bar in [b.qi_bar,b.enemy_qi_bar]:
  var style: StyleBoxFlat=bar.get_theme_stylebox("fill").duplicate();style.bg_color=Color(p.qi);style.border_color=Color(p.qi);bar.add_theme_stylebox_override("fill",style)
 title.text=p.title+"  ·  색상 검토용"
func run() -> void:
 root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["battle","city","dialogue","trade"]);game.start_battle();game.battle.select_samjae()
 await process_frame;await process_frame;await create_timer(.1).timeout
 for label in game.battle.find_children("*","Label",true,false):colors[label]=label.get_theme_color("font_color")
 var badge=UI.panel(game.ui_root,Rect2(368,18,442,38),Color("111c25ee"))
 title=UI.label(badge,"",Rect2(12,5,418,28),18,UI.TEXT);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 game.adventure_ui.pending_toasts.clear();game.adventure_ui.toast.hide();game.adventure_ui.notification_waiting=false
 for p in PALETTES:
  apply_palette(p)
  await create_timer(.25).timeout;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://screenshots/battle-palette-"+p.id+".png")==OK)
 for v in game.music.players:v.stop();v.stream=null
 for v in game.options.voices:v.stop();v.stream=null
 game.queue_free();await process_frame;print("BATTLE_PALETTE_CANDIDATES: PASS");quit()
