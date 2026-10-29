extends SceneTree
## Art placement reference only: no named combatant, stats, quest or reward.
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1280,720)
 var bg=TextureRect.new();bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.texture=load("res://assets/battle/premium/cuiyue-hall.png");bg.size=Vector2(1280,720);root.add_child(bg)
 var field=preload("res://scripts/battle_field.gd").new();field.configure({"width":7,"height":5})
 var board=preload("res://scripts/grid_battle_board.gd").new()
 board.battle={"grid":{"field":field,"units":[{"position":Vector2i(1,2),"facing":Vector2i.RIGHT},{"position":Vector2i(5,2),"facing":Vector2i.LEFT}]},"choice":"","facing":Vector2i.RIGHT}
 board.size=Vector2(1280,720);root.add_child(board)
 var label=preload("res://scripts/ui.gd").label(root,"취월루 · 전투 배경 배치안 · 7 × 5",Rect2(340,25,600,48),26,Color("ffe4aa"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_color_override("font_outline_color",Color("17231d"));label.add_theme_constant_override("outline_size",5)
 for i in range(5):await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/cuiyue-battle-layout.png")==OK)
 print("CUIYUE_BATTLE_LAYOUT: PASS");quit()
