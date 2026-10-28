extends SceneTree
const UI=preload("res://scripts/ui.gd")
const METRICS=preload("res://scripts/exploration_metrics.gd")
func _initialize() -> void:run.call_deferred()
func label(parent: Node,value: String,rect: Rect2,size: int=20,color: Color=Color("e9e3ce")) -> Label:
 var l=UI.label(parent,value,rect,size,color);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;return l
func panel(parent: Node,r: Rect2) -> void:
 UI.panel(parent,r,Color("263735"))
func viewport(size: Vector2i) -> SubViewport:
 var view=SubViewport.new();view.world_2d=World2D.new();view.size=size;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var bg=ColorRect.new();bg.size=size;bg.color=Color("152321");view.add_child(bg);return view
func player(parent: Node,point: Vector2,weapon: String="sword",direction: String="down"):
 var p=preload("res://scenes/player.tscn").instantiate();parent.add_child(p);p.position=point;p.scale=Vector2.ONE*2;p.movement_enabled=false;p.set_physics_process(false);p.set_display_height(140);p.facing=direction
 p.set_equipped_weapon({"sword":"plain_iron_sword","saber":"thickback_saber","spear":"balanced_spear","none":""}[weapon],weapon);p.stop();return p
func save(view: SubViewport,path: String) -> void:
 for i in range(4):await process_frame;await RenderingServer.frame_post_draw
 assert(view.get_texture().get_image().save_png(path)==OK)
func run() -> void:
 var data: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/exploration_sprite_inventory.json"))
 var view=viewport(Vector2i(1760,1680));label(view,"탐험 캐릭터 전체 비교 · 도원 + NPC %d종" % data.size(),Rect2(20,16,1720,40),30)
 label(view,"도시 표시 기준 ×2 · 발밑 기준선 동일 · 폭 제한과 원본 여백 유지 · 카메라 줌 제외",Rect2(20,60,1720,30),20)
 for i in range(data.size()+1):
  var x=40+(i%6)*280;var y=105+(i/6)*380
  panel(view,Rect2(x+4,y,268,365))
  var foot=Vector2(x+140,y+290)
  var line=ColorRect.new();line.position=Vector2(x+20,foot.y);line.size=Vector2(240,2);line.color=Color("bca877");view.add_child(line)
  if i==0:
   player(view,foot);label(view,"01 · 도원",Rect2(x,y+300,280,28),21);label(view,"주인공 · 높이140",Rect2(x,y+333,280,25),17);continue
  var n: Dictionary=data[i-1];var region=Rect2(n.region[0],n.region[1],n.region[2],n.region[3]);var atlas=AtlasTexture.new();atlas.atlas=load(n.texture);atlas.region=region
  var sprite=Sprite2D.new();sprite.texture=atlas;sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.offset=Vector2(-region.size.x/2,-region.size.y);sprite.position=foot
  var factor=minf(METRICS.CITIZEN_HEIGHT/region.size.y,88.0/region.size.x);sprite.scale=Vector2.ONE*factor*2;view.add_child(sprite)
  label(view,"%02d · %s" % [i+1,n.name],Rect2(x,y+300,280,28),20)
  label(view,n.group+" · 영역 높이%.0f" % (region.size.y*factor),Rect2(x,y+333,280,25),16)
 await save(view,"res://screenshots/exploration-characters-all.png");view.queue_free();await process_frame
 view=viewport(Vector2i(1440,1610));label(view,"도원 · 무기와 방향별 탐험 외형",Rect2(20,16,1400,42),30)
 label(view,"실제 플레이어 렌더러 사용 · 도시140 ×2 · 무기 포함 · 걷기 애니메이션은 정지 상태",Rect2(20,60,1400,30),19)
 var kinds=["sword","saber","spear","none"];var directions=["down","left","right","up"]
 for row in range(4):
  for col in range(4):
   var x=20+col*350;var y=110+row*370;panel(view,Rect2(x,y,340,355));player(view,Vector2(x+170,y+290),kinds[row],directions[col])
   label(view,{"sword":"검","saber":"도","spear":"창","none":"맨손"}[kinds[row]]+" · "+{"down":"정면","left":"왼쪽","right":"오른쪽","up":"뒷면"}[directions[col]],Rect2(x,y+310,340,30),22)
 await save(view,"res://screenshots/exploration-player-variants.png");view.queue_free();await process_frame
 print("EXPLORATION_SPRITES: PASS · "+str(data.size())+" NPC regions + player");quit()
