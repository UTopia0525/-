extends "res://prototypes/isometric/iso_world.gd"
func _ready() -> void:
 super._ready()
 actor.speed=4.8
 # The near sides are cut away; solid floor bounds still prevent walking out.
 for rect in [Rect2(0,0,8,.16),Rect2(0,.16,.16,5.84)]:
  var along_u=rect.size.x>rect.size.y;var length=maxf(rect.size.x,rect.size.y);var count=ceili(length/.75)
  for i in range(count):
   var start=length*i/count;var piece=rect
   if along_u:piece.position.x+=start;piece.size.x=length/count
   else:piece.position.y+=start;piece.size.y=length/count
   var wall=Wall.new();wall.wall_height=120
   wall.setup({"id":"room_wall_"+str(props.size()),"name":"실내 회벽","kind":"wall","rect":[piece.position.x,piece.position.y,piece.size.x,piece.size.y],"end_cap":i==count-1},art.wall_materials)
   actors.add_child(wall);props.append(wall)
 var door_art=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/room-art.json"))
 var door=Prop.new();door.setup({"id":"room_door","name":"열린 실내 출입문","kind":"gate","art":"room_door","rect":[3.1,5.6,1.85,.4],"opening":[3.45,5.6,1.15,.4],"colliders":[[3.1,5.6,.35,.4],[4.6,5.6,.35,.4]]},door_art)
 actors.add_child(door);props.append(door)
 var leaf=Rect2(4.95,5.6,.65,.4);door.physical_footprints.append(leaf)
 var shape=CollisionPolygon2D.new();var points=Space.diamond(leaf)
 for i in range(points.size()):points[i]-=door.position
 shape.polygon=points;door.add_child(shape)
 selection_message="소박한 민가 · 열린 문과 탁자·수납 항아리"
 last_sorted_positions=[];update_depth();grounding.queue_redraw()
