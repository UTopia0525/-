extends Panel
## Shared live dialogue/history paper surface. Content remains normal UI nodes.
func _ready() -> void:
 var style=StyleBoxFlat.new();style.bg_color=Color("0b1715dc");style.border_color=Color("9a8969");style.set_border_width_all(1);style.set_corner_radius_all(4);add_theme_stylebox_override("panel",style)
 var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=self
 painter.paper(Rect2(9,7,size.x-18,size.y-14),Color("eee5cf"))
 var paper=get_child(get_child_count()-1);paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper.offset_left=9;paper.offset_top=7;paper.offset_right=-9;paper.offset_bottom=-7
 painter.free()
