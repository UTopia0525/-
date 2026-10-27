extends RefCounted
## Encounter-owned geometry. Terrain records are data, separate from actor occupancy.
var width=7
var height=5
var cells: Dictionary={}
var player_spawn=Vector2i(1,2)
var enemy_spawn=Vector2i(5,2)
func configure(config: Dictionary={}) -> void:
 width=clampi(int(config.get("width",7)),2,32);height=clampi(int(config.get("height",5)),2,24);cells.clear()
 for entry in config.get("terrain",[]):
  if entry is Dictionary and entry.get("cell") is Array and entry.cell.size()==2:
   var point=Vector2i(int(entry.cell[0]),int(entry.cell[1]))
   if inside(point):cells[point]=entry.duplicate(true)
 for entry in config.get("blocked",[]):
  if entry is Array and entry.size()==2:
   var point=Vector2i(int(entry[0]),int(entry[1]))
   if inside(point):cells[point]={"blocks_movement":true,"blocks_sight":true,"name":"장애물"}
 player_spawn=safe_spawn(config.get("player_spawn",[mini(1,width-1),height/2]),Vector2i(-1,-1))
 enemy_spawn=safe_spawn(config.get("enemy_spawn",[maxi(width-2,0),height/2]),player_spawn)
func inside(p: Vector2i) -> bool:return p.x>=0 and p.y>=0 and p.x<width and p.y<height
func walkable(p: Vector2i) -> bool:return inside(p) and not cells.get(p,{}).get("blocks_movement",false)
func safe_spawn(value,exclude: Vector2i) -> Vector2i:
 if value is Array and value.size()==2:
  var point=Vector2i(int(value[0]),int(value[1]))
  if walkable(point) and point!=exclude:return point
 for y in range(height):
  for x in range(width):
   if walkable(Vector2i(x,y)) and Vector2i(x,y)!=exclude:return Vector2i(x,y)
 # A fully blocked authoring fixture must still leave two playable spawn cells.
 for y in range(height):
  for x in range(width):
   if Vector2i(x,y)!=exclude:cells.erase(Vector2i(x,y));return Vector2i(x,y)
 return Vector2i.ZERO
func sight(from: Vector2i,to: Vector2i) -> bool:
 if not inside(to):return false
 var previous=from
 var delta=to-from;var steps=maxi(absi(delta.x),absi(delta.y))*4
 for i in range(1,steps+1):
  var p=Vector2i((Vector2(from)+Vector2(delta)*float(i)/maxi(steps,1)).round())
  if p.x!=previous.x and p.y!=previous.y:
   if cells.get(Vector2i(p.x,previous.y),{}).get("blocks_sight",false) or cells.get(Vector2i(previous.x,p.y),{}).get("blocks_sight",false):return false
  if p!=from and cells.get(p,{}).get("blocks_sight",false):return false
  previous=p
 return true
