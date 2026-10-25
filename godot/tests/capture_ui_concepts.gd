extends SceneTree
const UI=preload("res://scripts/ui.gd")
var game
var layer: CanvasLayer
var canvas: Control
var paper:=false
func _initialize() -> void:run.call_deferred()
func panel(rect: Rect2,fill: Color,border: Color) -> Panel:
	var p=Panel.new();p.position=rect.position;p.size=rect.size
	var style=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(1);style.set_corner_radius_all(2)
	p.add_theme_stylebox_override("panel",style);canvas.add_child(p);return p
func label(parent: Node,text: String,rect: Rect2,font_size: int,color: Color,brush: bool=false) -> Label:
	var l=UI.label(parent,text,rect,font_size,color);l.add_theme_font_override("font",UI.BRUSH_FONT if brush else UI.BODY_FONT);return l
func shot(name: String) -> void:
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://screenshots/"+name+".png")==OK)
func concept(is_paper: bool) -> void:
	paper=is_paper
	if is_instance_valid(layer):layer.free()
	layer=CanvasLayer.new();layer.layer=30;root.add_child(layer);canvas=Control.new();layer.add_child(canvas)
	var fill=Color("e8ddc7f5") if paper else Color("101e20ee")
	var ink=Color("352f29") if paper else Color("e9e8db")
	var accent=Color("a04436") if paper else Color("c8ad75")
	var muted=Color("756858") if paper else Color("9bafa6")
	var mini=panel(Rect2(24,24,218,202),fill,accent)
	label(mini,"長沙  ·  장사",Rect2(14,10,190,28),20,ink,true)
	var texture=TextureRect.new();texture.position=Vector2(12,48);texture.size=Vector2(194,115);texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;texture.stretch_mode=TextureRect.STRETCH_SCALE
	var atlas=AtlasTexture.new();atlas.atlas=game.exploration.background.texture
	var size: Vector2=atlas.atlas.get_size();atlas.region=Rect2(Vector2(size.x*.35,size.y*.24),Vector2(size.x*.3,size.y*.28));texture.texture=atlas;mini.add_child(texture)
	label(mini,"!",Rect2(68,72,30,36),32,Color("c38c17"),true)
	label(mini,"▲",Rect2(110,108,25,25),20,accent)
	label(mini,"상점가   ·   북 ↑",Rect2(14,169,190,24),14,muted)
	var top=panel(Rect2(265,24,444,54),fill,accent)
	label(top,"第 一 章",Rect2(18,12,95,30),20,accent,true)
	label(top,"도원   ·   절정까지 32",Rect2(125,15,290,26),17,ink)
	var wallet=panel(Rect2(1058,24,198,54),fill,accent)
	label(wallet,"소지금   1,150 문",Rect2(18,14,175,28),18,ink)
	var quests=panel(Rect2(904,106,352,376),fill,accent)
	label(quests,"강호 의뢰",Rect2(22,17,250,35),26,ink,true)
	label(quests,"Q  일지에서 추적 대상 선택",Rect2(22,60,310,25),15,muted)
	var selected=Panel.new();selected.position=Vector2(16,104);selected.size=Vector2(320,106)
	var chosen=StyleBoxFlat.new();chosen.bg_color=Color("d9c9ab") if paper else Color("203b36");chosen.border_color=accent;chosen.border_width_left=3;selected.add_theme_stylebox_override("panel",chosen);quests.add_child(selected)
	label(selected,"◆  뒤바뀐 바구니",Rect2(15,12,285,30),21,ink,true)
	label(selected,"장사 · 백문식에게 바구니 회수",Rect2(15,49,290,24),15,ink)
	label(selected,"추적 중",Rect2(15,77,290,20),13,accent)
	label(quests,"돌아오지 않는 약초꾼",Rect2(28,231,290,28),18,ink)
	label(quests,"무창 · 남쪽 산길에서 흔적 찾기",Rect2(28,264,292,22),14,muted)
	label(quests,"두 번 걷힌 곡식",Rect2(28,306,290,28),18,ink)
	label(quests,"무창 · 진문수에게 운송 기록 확인",Rect2(28,338,300,22),14,muted)
	var title=panel(Rect2(265,94,384,45),fill,accent)
	label(title,"B · 한지와 주인(朱印)" if paper else "A · 먹빛과 옅은 금선",Rect2(14,9,355,28),19,ink,true)
	var bar=panel(Rect2(256,646,768,52),fill,accent)
	for i in range(6):
		var text=["I  소지품","K  무공","Q  의뢰","R  세력","TAB  지도","ESC  설정"][i]
		label(bar,text,Rect2(18+i*125,15,121,26),15,ink)
	var note=panel(Rect2(24,650,206,44),fill,accent)
	label(note,"디자인 예시 · 미적용",Rect2(12,10,190,24),14,muted)
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
	var npc=game.exploration.ambient_nodes.filter(func(n):return n.get_meta("npc_id")=="vegetable_vendor")[0]
	game.exploration.player.position=game.exploration.safe_player_position(npc.position+Vector2(65,65));game.exploration.camera.snap_to_player()
	await shot("quest-icons-changsha")
	game.adventure_ui.toast.hide();game.toggle_city_map();await shot("quest-map-changsha");game.toggle_city_map()
	game.ui_root.hide();concept(false);await shot("ui-concept-ink-gold");concept(true);await shot("ui-concept-paper-seal");layer.free();game.ui_root.show()
	preload("res://scripts/overland_travel.gd").use(game,{"travel":{"area":"wuchang","arrival":[760,1190]}})
	await shot("quest-icons-wuchang");game.adventure_ui.toast.hide();game.toggle_city_map();await shot("quest-map-wuchang");game.toggle_city_map()
	game.adventure_ui.open_journal();game.adventure_ui.set_filter("available");await shot("quest-journal-global");game.adventure_ui.close_menu()
	game.start_battle();game.battle.select_skill("basic_defense");game.battle.use_selected()
	while game.battle.busy:await create_timer(.03).timeout
	game.battle.use_selected()
	while game.battle.turn_label.text!="상대의 차례":await create_timer(.02).timeout
	await shot("enemy-lower-art-executed")
	while game.battle.busy:await create_timer(.03).timeout
	game.reset();await create_timer(.3).timeout
	for v in game.music.players:v.stop();v.stream=null
	for v in game.options.voices:v.stop();v.stream=null
	game.queue_free();await process_frame;quit()
