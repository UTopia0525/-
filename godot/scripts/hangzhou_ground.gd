extends Node2D
## Ground and streets are rendered from the same lots used for physical buildings.
var data: Dictionary
var terrain_atlas: Texture2D
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 terrain_atlas=load("res://assets/maps/hangzhou/materials.png");queue_redraw()
func patch(bounds: Rect2,kind: String,tint: Color=Color.WHITE) -> void:
 var half=Vector2(terrain_atlas.get_size())/2
 var origin={"water":Vector2.ZERO,"stone":Vector2(half.x,0),"grass":Vector2(0,half.y),"earth":half,"wood":half}[kind]
 var tile=160.0
 for y in range(int(floor(bounds.position.y/tile)),int(ceil(bounds.end.y/tile))):
  for x in range(int(floor(bounds.position.x/tile)),int(ceil(bounds.end.x/tile))):
   var cell=Rect2(Vector2(x,y)*tile,Vector2.ONE*tile);var part=cell.intersection(bounds)
   var source=Rect2(origin+(part.position-cell.position)/tile*half,part.size/tile*half)
   draw_texture_rect_region(terrain_atlas,part,source,tint)
func _draw() -> void:
 if not terrain_atlas:return
 patch(Rect2(0,0,1760,1280),"earth",Color(.93,.94,.90))
 patch(Rect2(0,0,395,1280),"water",Color(.85,.96,.97))
 patch(Rect2(395,0,38,1280),"stone",Color(.76,.78,.72))
 patch(Rect2(1490,0,270,60),"water")
 for r in [Rect2(495,0,540,430),Rect2(495,1190,1230,90),Rect2(1680,65,65,1120)]:patch(r,"grass",Color(.88,.95,.85))
 for o in data.objects:
  if not o.has("lot"):continue
  var a=o.lot.rect;var r=Rect2(a[0],a[1],a[2],a[3]);patch(r,o.lot.surface,Color(1.04,1.01,.94))
  if o.prefab=="hz_tower":
   var court=Rect2(r.position.x-30,r.end.y, r.size.x+60,10)
   patch(court,"stone");draw_rect(court,Color("9e9278"),false,1)
 for road in data.roads:
  var a=Vector2(road.points[0][0],road.points[0][1]);var b=Vector2(road.points[1][0],road.points[1][1]);var r=Rect2(a.min(b),a.max(b)-a.min(b)).grow(float(road.width)/2)
  patch(r,"stone",Color(.88,.87,.83));draw_rect(r,Color("777668"),false,2)
 # Re-cover intersections so kerbs do not form barriers across crossroads.
 for horizontal in data.roads:
  if horizontal.points[0][1]!=horizontal.points[1][1]:continue
  for vertical in data.roads:
   if vertical.points[0][0]!=vertical.points[1][0]:continue
   var x=float(vertical.points[0][0]);var y=float(horizontal.points[0][1])
   if x>=horizontal.points[0][0] and x<=horizontal.points[1][0] and y>=vertical.points[0][1] and y<=vertical.points[1][1]:
    patch(Rect2(x-float(vertical.width)/2,y-float(horizontal.width)/2,vertical.width,horizontal.width),"stone",Color(.88,.87,.83))
 # Low shoreline posts belong to the bank, outside the walking promenade.
 for y in range(30,1250,44):
  draw_rect(Rect2(406,y,8,10),Color("777c76"));draw_rect(Rect2(405,y-2,10,4),Color("ccc5b0"))
