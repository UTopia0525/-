extends SceneTree
var game
var failed=false
var report={"gates":[],"movement":{}}
func _initialize() -> void:run.call_deferred()
func check(ok: bool,msg: String) -> void:
 if not ok:failed=true;push_error("WALK_PASSAGES: "+msg)
func press(direction: Vector2) -> void:
 for key in ["left","right","up","down"]:Input.action_release("move_"+key)
 if direction.x<0:Input.action_press("move_left")
 if direction.x>0:Input.action_press("move_right")
 if direction.y<0:Input.action_press("move_up")
 if direction.y>0:Input.action_press("move_down")
func walk(start: Vector2,direction: Vector2,steps: int) -> float:
 var p=game.exploration.player;p.position=start;p.stop();press(direction)
 for i in range(steps):
  await physics_frame
  if str(p.sprite.animation).begins_with("walk_"):
   var count=p.sprite.sprite_frames.get_frame_count(p.sprite.animation)
   check(p.sprite.frame==mini(count-1,floori(p.gait_phase/TAU*count)),"every direction follows physical gait phase")
   check(not p.sprite.is_playing(),"walk cannot run on a separate timer")
 press(Vector2.ZERO);await physics_frame
 return p.position.distance_to(start)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"]);game.start_city();var w=game.exploration;var p=w.player
 # Sweep the actual 16-radius body through every two-pillar opening.
 for area in ["changsha","wuchang","nanjing","alliance_office","qingya_hamlet","qingya_camp"]:
  if area=="wuchang":game.alliance_visit.phase="visiting"
  w.load_area(area);w.set_active(true);await physics_frame;await physics_frame
  var physical=[]
  for node in w.scenery_nodes:
   if node.get_meta("kind")!="gate" or node.collision_rects.size()!=2:continue
   var a: Rect2=node.collision_rects[0];var b: Rect2=node.collision_rects[1]
   var horizontal=absf(a.get_center().x-b.get_center().x)>absf(a.get_center().y-b.get_center().y)
   if (horizontal and a.position.x>b.position.x) or (not horizontal and a.position.y>b.position.y):var swap=a;a=b;b=swap
   var gap=b.position.x-a.end.x if horizontal else b.position.y-a.end.y
   var center=Vector2((a.end.x+b.position.x)/2,(a.get_center().y+b.get_center().y)/2) if horizontal else Vector2((a.get_center().x+b.get_center().x)/2,(a.end.y+b.position.y)/2)
   if node.definition.has("passage_point"):center=w.city_point(node.definition.passage_point)
   var direction=Vector2.DOWN if horizontal else Vector2.RIGHT
   var half=maxf(a.size.y,b.size.y)/2+42 if horizontal else maxf(a.size.x,b.size.x)/2+42
   var start=center-direction*half;var finish=center+direction*half
   if area=="wuchang" and str(node.name)=="east_gate":
    finish.x=minf(finish.x,w.regional_map.walk_bounds.end.x-20)
   var usable=w.can_stand(start) and w.can_stand(finish)
   var collision=KinematicCollision2D.new()
   var clear=not p.test_move(Transform2D(0,start),finish-start,collision)
   report.gates.append({"area":area,"id":node.name,"gap":gap,"usable_approach":usable,"sweep_clear":clear,"collider":"" if clear else str(collision.get_collider().name)})
   if str(node.name)!="main_gate":check(usable,"public gate has usable approach: "+area+"/"+node.name)
   else:check(not clear,"Qingya sealed gate remains closed by story design")
   if usable and gap>36:
    check(clear,"gate center must be clear: "+area+"/"+node.name)
    # The visible neighbouring wall may occupy the edge under a gate roof.
    # Measure the actual open span, not just the two prefab pillar footprints.
    var low=a.end.x if horizontal else a.end.y
    var high=b.position.x if horizontal else b.position.y
    for block in w.blockers:
     if horizontal and block.end.y>start.y and block.position.y<finish.y:
      if block.end.x<=center.x:low=maxf(low,block.end.x)
      elif block.position.x>=center.x:high=minf(high,block.position.x)
     elif not horizontal and block.end.x>start.x and block.position.x<finish.x:
      if block.end.y<=center.y:low=maxf(low,block.end.y)
      elif block.position.y>=center.y:high=minf(high,block.position.y)
    report.gates[-1]["effective_gap"]=high-low
    check(high-low>32,"opening fits unchanged32px feet: "+area+"/"+node.name)
    var tangent=Vector2.RIGHT if horizontal else Vector2.DOWN
    var axis=center.x if horizontal else center.y
    for side in [-1.0,1.0]:
     var offset=tangent*side*maxf(0,minf(axis-low,high-axis)-20)
     var hit=KinematicCollision2D.new();var blocked=p.test_move(Transform2D(0,start+offset),finish-start,hit)
     if w.can_stand(start+offset) and w.can_stand(finish+offset):
      if blocked and hit.get_collider() is CharacterBody2D:report["occupied_edges"]=int(report.get("occupied_edges",0))+1
      else:check(not blocked,"near-pillar clearance: "+area+"/"+node.name)
    physical.append({"start":start,"finish":finish,"direction":direction})
  if not physical.is_empty():
   var sample=physical[0];var length: float=sample.start.distance_to(sample.finish)
   var steps=ceili(length/(p.speed/60))+4
   var travelled: float=await walk(sample.start,sample.direction,steps)
   check(travelled>=length-12,"real input crosses gate: "+area)
  # Return any accidental contact with a portal to a known exploration state.
  game.state="explore";w.set_active(true)
 # A clear road stretch supports equal-speed, diagonal and gait checks.
 w.load_area("mountain_road");w.set_active(true);await physics_frame;await physics_frame
 var origin=w.city_point([360,1175]);var distances={}
 for spec in [["right",Vector2.RIGHT],["left",Vector2.LEFT],["up",Vector2.UP],["down",Vector2.DOWN],["diagonal",Vector2(1,1)]]:
  var distance: float=await walk(origin,spec[1],10);distances[spec[0]]=distance
 report.movement=distances
 for value in distances.values():check(absf(value-60.0)<6.1,"cardinal and diagonal speed remains360")
 # Real circular-foot sliding along a controlled narrow corner, without changing
 # any authored wall. This also verifies that slowed vertical steps follow travel.
 var wall=StaticBody2D.new();wall.collision_layer=2;wall.position=origin+Vector2(100,0)
 var shape=CollisionShape2D.new();var rect=RectangleShape2D.new();rect.size=Vector2(40,300);shape.shape=rect;wall.add_child(shape);w.add_child(wall);await physics_frame
 var start=origin+Vector2(62,-60);p.position=start;p.stop();press(Vector2(1,1))
 for i in range(20):
  await physics_frame
  check(p.position.x<=origin.x+64.2,"wall footprint cannot be penetrated")
  if str(p.sprite.animation).begins_with("walk_"):check(p.sprite.frame==floori(p.gait_phase/TAU*4),"slow diagonal sliding preserves gait phase")
 press(Vector2.ZERO);await physics_frame
 check(p.position.y-start.y>70,"diagonal input slides along wall without sticking")
 check(p.gait_phase==0 and str(p.sprite.animation).begins_with("idle_"),"release stops without residual gait")
 wall.free()
 print("PASSAGE_AUDIT "+JSON.stringify(report))
 game.queue_free();await process_frame;print("WALK_PASSAGES: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
