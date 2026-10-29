extends Node3D
const GEO=preload("res://scripts/geometry.gd")
var g
var m: Dictionary={}
var lights: Array[OmniLight3D]=[]
var boat: Node3D
var districts=[{"name":"绮灯长街 · 綺燈長街","point":Vector3(18,.6,20)}]
func _ready() -> void:build()
func build() -> void:
 g=GEO.new(self)
 for spec in [["timber","342424"],["red","7a2729"],["cream","d2bd8e"],["gold","b38a42"],["roof","153337"],["rib","275053"],["stone","626b68"],["wood","6b4633"],["dark","1f2428"],["silk","b8443c"],["teal","2c7975"],["purple","665071"],["paper","ffac42"],["fruit","df7935"],["leaf","486252"]]:m[spec[0]]=g.material(spec[0],Color(spec[1]),.25 if spec[0]=="gold" else 0,1.0 if spec[0]=="paper" else 0)
 var paving=ShaderMaterial.new();paving.shader=preload("res://shaders/stone.gdshader");m.paving=paving
 # Elevated banks: the canal is genuine nonwalkable water between them.
 g.box(Vector3(-29,-.5,0),Vector3(36,2,126),m.paving,true)
 g.box(Vector3(29,-.5,0),Vector3(36,2,126),m.paving,true)
 var water=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(118,175);plane.subdivide_width=96;plane.subdivide_depth=96;water.mesh=plane
 var wm=ShaderMaterial.new();wm.shader=preload("res://shaders/water.gdshader");water.material_override=wm;water.position.y=-.35;add_child(water)
 # Distant low-poly hills frame the water city beyond the playable banks.
 var hill=g.material("distant_hill",Color("243e44"))
 for i in range(8):g.sphere(Vector3(-100+i*29,-4,-100-abs(i-4)*3),Vector3(48,20+(i%3)*8,44),hill)
 # Stone courses and embankment edging.
 for side in [-1,1]:
  for z in range(-61,63,2):
   g.box(Vector3(side*11.12,.3,z),Vector3(.34,.50,1.94),m.stone)
   g.box(Vector3(side*11.07,.57,z),Vector3(.47,.15,1.99),m.cream)
  for z in range(-60,61,4):
   if abs(z+18)<5 or abs(z-24)<5 or (side==1 and z>=4 and z<=8):continue
   railing(Vector3(side*11.55,.58,z),Vector3(side*11.55,.58,z+3.9),.9)
 # Two arched bridges make a walkable loop across the water.
 bridge(-18);bridge(24)
 # Majestic Cuiyue tower at the northwestern end.
 pavilion(Vector3(-31,.5,-43),19,18,5,true)
 g.surface([Vector3(-33.3,.5,-30.5),Vector3(-28.7,.5,-30.5),Vector3(-33.3,.92,-34.2),Vector3(-28.7,.92,-34.2)],[[0,1,2],[1,3,2],[2,1,0],[2,3,1]],m.stone,true)
 text3d("취 월 루",Vector3(-31,4.3,-33.7),.014,Color("ffe2a6"),0)
 # Rows of detailed shop houses, courtyards and varied market stalls.
 var colors=[m.red,m.timber,m.teal]
 for i in range(9):
  var z=-51+i*12.3
  pavilion(Vector3(38,.5,z),11,10,2 if i%3 else 3,false,colors[i%3])
  if i<7:pavilion(Vector3(-37,.5,43-i*10.3),12,8.4,1 if i%3 else 2,false,colors[(i+1)%3])
 for i in range(17):
  var z=-54+i*6.4
  stall(Vector3(26,.5,z),i)
  if i%2==0:stall(Vector3(-25,.5,z+2),i+3)
  if i%2==0:
   lantern(Vector3(13.2,3.25,z),.29)
   g.cylinder(Vector3(13.2,1.9,z),.065,2.8,m.timber)
  if i%3==0:string_lights(Vector3(12,4.8,z),Vector3(29,4.8,z))
 # Open eating terraces; no NPC population in this test.
 for z in [1,12,38]:
  for x in [17,21]:table(Vector3(x,.5,z))
 for p in [Vector3(-19,.5,-29),Vector3(-18,.5,34),Vector3(17,.5,-34),Vector3(32,.5,55)]:tree(p)
 for z in [-53,52]:
  gateway(Vector3(18,.5,z))
 # Pier and the moored lantern pleasure barge; walking aboard is possible.
 pier();pleasure_barge()
 # Prevent disappearing beyond the hand-built playable area.
 for x in [-47.5,47.5]:g.collider(Vector3(x,2,0),Vector3(1,7,128))
 for z in [-63,63]:g.collider(Vector3(0,2,z),Vector3(98,7,1))
 # Limited actual lights; emissive lantern/window meshes provide the rest of the glow.
 for p in [Vector3(18,4,35),Vector3(18,4,8),Vector3(18,4,-22),Vector3(-24,5,-32),Vector3(-32,5,-43),Vector3(0,4,6)]:
  var light=OmniLight3D.new();light.position=p;light.light_color=Color("ffc58c");light.light_energy=1.1;light.omni_range=15;light.shadow_enabled=false;add_child(light);lights.append(light)
 g.flush()
func roof(center: Vector3,width: float,depth: float,height: float) -> void:
 # Curved hip roof, pinched ridge and lifted eave corners, with real thickness.
 var verts=[];var tris=[];var steps=12
 for level in range(steps+1):
  var t=level/float(steps);var y=height*pow(t,.68)
  var w=width*(1-t*.72);var d=depth*(1-t*.95)
  for v in [Vector3(-w/2,y,-d/2),Vector3(w/2,y,-d/2),Vector3(w/2,y,d/2),Vector3(-w/2,y,d/2)]:
   v.y+=pow(1-t,5)*.4;verts.append(center+v)
 for j in range(steps):
  for k in range(4):
   var a=j*4+k;var b=j*4+(k+1)%4;tris.append([a,b,b+4]);tris.append([a,b+4,a+4]);tris.append([a+4,b+4,b]);tris.append([a+4,b,a])
 g.surface(verts,tris,m.roof)
 # Fine glazed tile ribs follow each curved slope.
 for x in range(-int(width),int(width)+1):
  var px=x*.5
  for side in [-1,1]:
   var previous=center+Vector3(px,.4,side*depth/2)
   for j in range(1,4):
    var t=j/3.0;var p=center+Vector3(px*(1-t*.72),height*pow(t,.68)+pow(1-t,5)*.4,side*depth/2*(1-t*.95))
    g.beam(previous,p,.025,m.rib);previous=p
 for side in [-1,1]:
  g.beam(center+Vector3(-width/2,.4,side*depth/2),center+Vector3(width/2,.4,side*depth/2),.065,m.gold)
 g.beam(center+Vector3(-width*.14,height,0),center+Vector3(width*.14,height,0),.09,m.gold)
 for sx in [-1,1]:
  for sz in [-1,1]:
   var end=center+Vector3(sx*width/2,.4,sz*depth/2)
   g.beam(end,end+Vector3(sx*.35,.42,sz*.22),.075,m.gold)
func pavilion(p: Vector3,width: float,depth: float,floors: int,open_hall: bool=false,wall: Material=null) -> void:
 if wall==null:wall=m.red
 g.box(p+Vector3(0,.18,0),Vector3(width+.6,.36,depth+.6),m.stone,not open_hall)
 for level in range(floors):
  var w=width-level*1.6;var d=depth-level*1.4;var h=4.1;var bottom=p.y+.4+level*4.9
  if level==0 and open_hall:
   g.box(Vector3(p.x,bottom-.13,p.z),Vector3(w,.26,d),m.wood,true)
   for sx in [-1,1]:
    g.box(Vector3(p.x+sx*w/2,bottom+h/2,p.z),Vector3(.4,h,d),wall,true)
    g.box(Vector3(p.x+sx*(w/4+1.2),bottom+h/2,p.z+d/2),Vector3(w/2-2.4,h,.35),wall,true)
   g.box(Vector3(p.x,bottom+h/2,p.z-d/2),Vector3(w,h,.4),wall,true)
   for x in [-5,5]:
    for z in [-4,2]:table(Vector3(p.x+x,bottom,p.z+z))
   for x in [-6,0,6]:lantern(Vector3(p.x+x,bottom+3.3,p.z+3),.45)
  else:
   g.box(Vector3(p.x,bottom+h/2,p.z),Vector3(w,h,d),wall,level==0)
  # columns, galleries and gold beamwork surround every storey.
  for sx in [-1,1]:
   for sz in [-1,1]:g.cylinder(Vector3(p.x+sx*(w/2+.12),bottom+h/2,p.z+sz*(d/2+.12)),.17,h,m.red)
  for zside in [-1,1]:
   var z=p.z+zside*(d/2+.21)
   g.box(Vector3(p.x,bottom+.35,z),Vector3(w+.4,.16,.23),m.gold)
   g.box(Vector3(p.x,bottom+h-.3,z),Vector3(w+.4,.20,.25),m.gold)
   var windows=int(w/1.7)
   for i in range(windows):
    var x=p.x-w/2+.9+i*(w-1.6)/maxf(1,windows-1)
    if open_hall and level==0 and zside==1 and absf(x-p.x)<2.7:continue
    g.box(Vector3(x,bottom+2.1,z),Vector3(1.05,1.55,.06),m.paper)
    for dx in [-.45,0,.45]:g.box(Vector3(x+dx,bottom+2.1,z+zside*.055),Vector3(.055,1.7,.05),m.timber)
    for dy in [-.6,-.2,.2,.6]:g.box(Vector3(x,bottom+2.1+dy,z+zside*.06),Vector3(1.15,.045,.06),m.timber)
   if level>0:railing(Vector3(p.x-w/2,bottom+.5,z+zside*.6),Vector3(p.x+w/2,bottom+.5,z+zside*.6),.8)
  roof(Vector3(p.x,bottom+h,p.z),w+3,d+3,1.65 if floors<3 else 2.2)
  for sx in [-1,1]:lantern(Vector3(p.x+sx*(w/2-.2),bottom+3.2,p.z+d/2+.6),.32 if floors<3 else .45)
func lantern(p: Vector3,r: float=.3) -> void:
 g.sphere(p,Vector3(r*1.8,r*2.3,r*1.8),m.paper)
 for y in [-r,r]:g.cylinder(p+Vector3(0,y,0),r*.7,.06,m.gold)
 for i in range(8):
  var a=i*TAU/8;var v=Vector3(cos(a)*r*.85,0,sin(a)*r*.85)
  g.beam(p+v+Vector3(0,-r*.75,0),p+v+Vector3(0,r*.75,0),.012,m.red)
 g.beam(p+Vector3(0,r,0),p+Vector3(0,r+.35,0),.018,m.dark)
 g.beam(p+Vector3(0,-r,0),p+Vector3(0,-r-.3,0),.027,m.silk)
func railing(a: Vector3,b: Vector3,height: float=1) -> void:
 var direction=b-a
 g.collider((a+b)/2+Vector3.UP*height/2,Vector3(.12,height,direction.length()),Vector3(0,atan2(direction.x,direction.z),0))
 g.beam(a+Vector3.UP*height,b+Vector3.UP*height,.055,m.wood)
 g.beam(a+Vector3.UP*.28,b+Vector3.UP*.28,.045,m.wood)
 var count=maxi(1,int(a.distance_to(b)/.75))
 for i in range(count+1):
  var p=a.lerp(b,i/float(count));g.beam(p,p+Vector3.UP*height,.045,m.wood)
func bridge(z: float) -> void:
 var verts=[];var triangles=[];var n=24
 for i in range(n+1):
  var x=-12+i;var y=.5+sin(i/float(n)*PI)*1.8
  verts.append(Vector3(x,y,z-2.4));verts.append(Vector3(x,y,z+2.4))
  if i<n:triangles.append([i*2,i*2+2,i*2+1]);triangles.append([i*2+1,i*2+2,i*2+3])
 g.surface(verts,triangles,m.stone,true)
 for i in range(n):
  var x=-12+i;var y=.5+sin(i/float(n)*PI)*1.8;var ny=.5+sin((i+1)/float(n)*PI)*1.8
  for side in [-1,1]:
   railing(Vector3(x,y,z+side*2.45),Vector3(x+1,ny,z+side*2.45),1)
   g.collider(Vector3(x+.5,y+.65,z+side*2.45),Vector3(1.1,1.3,.18))
func stall(p: Vector3,index: int) -> void:
 var width=3.7 if index%3 else 4.3;var fabric=[m.silk,m.teal,m.purple,m.cream][index%4]
 g.box(p+Vector3(0,.8,0),Vector3(width,1.1,2.4),m.wood,true)
 for x in [-width/2,width/2]:
  for z in [-1.2,1.2]:g.cylinder(p+Vector3(x,1.5,z),.06,3,m.timber)
 var v=[p+Vector3(-width/2-.2,2.6,-1.5),p+Vector3(width/2+.2,2.6,-1.5),p+Vector3(-width/2-.2,3.05,0),p+Vector3(width/2+.2,3.05,0),p+Vector3(-width/2-.2,2.6,1.5),p+Vector3(width/2+.2,2.6,1.5)]
 g.surface(v,[[0,2,1],[1,2,3],[2,4,3],[3,4,5],[1,2,0],[3,2,1],[3,4,2],[5,4,3]],fabric)
 var side=-1.0 if p.x>0 else 1.0
 var front=p+Vector3(side*(width/2+.23),2.45,0)
 g.box(front,Vector3(.05,.4,3.05),fabric)
 for stripe in range(6):g.box(front+Vector3(side*.035,0,-1.25+stripe*.5),Vector3(.03,.4,.16),m.cream)
 text3d(["향 차","비 단","과 실"][index%3],p+Vector3(side*(width/2+.30),2.1,0),.004,Color("f9d99c"),side*PI/2)
 for x in [-1.2,1.2]:lantern(p+Vector3(x,2.35,1.4),.22)
 # Deliberate differences: silk rolls, ceramic vessels and fresh produce.
 for i in range(6):
  var x=-1.35+(i%3)*1.15;var z=-.5+int(i/3)*.9
  if index%3==0:
   g.cylinder(p+Vector3(x,1.53,z),.22,.35,m.cream);g.cylinder(p+Vector3(x,1.74,z),.12,.12,m.teal)
  elif index%3==1:
   g.box(p+Vector3(x,1.47,z),Vector3(.9,.13,.55),[m.silk,m.teal,m.purple][i%3]);g.cylinder(p+Vector3(x,1.65,z),.13,.7,fabric)
  else:
   g.box(p+Vector3(x,1.41,z),Vector3(.9,.12,.65),m.wood)
   for j in range(5):g.sphere(p+Vector3(x+(j%3)*.22-.2,1.56,z+(j/3)*.22-.1),Vector3(.2,.2,.2),m.fruit if j%2 else m.leaf)
func string_lights(a: Vector3,b: Vector3) -> void:
 var prev=a
 for i in range(1,13):
  var p=a.lerp(b,i/12.0)-Vector3.UP*sin(i/12.0*PI)*.8;g.beam(prev,p,.014,m.dark);prev=p
  if i%2==0:lantern(p-Vector3.UP*.25,.18)
func table(p: Vector3) -> void:
 g.cylinder(p+Vector3(0,.75,0),.73,.12,m.wood);g.cylinder(p+Vector3(0,.36,0),.13,.7,m.timber)
 g.collider(p+Vector3(0,.45,0),Vector3(1.4,.9,1.4))
 for angle in [0,PI]:
  var v=Vector3(cos(angle)*1.1,0,sin(angle)*1.1)
  g.box(p+v+Vector3(0,.36,0),Vector3(.45,.7,.45),m.wood,true)
 for x in [-.35,.35]:g.cylinder(p+Vector3(x,.86,0),.09,.13,m.cream)
 g.sphere(p+Vector3(0,.88,.2),Vector3(.22,.25,.22),m.teal)
func tree(p: Vector3) -> void:
 g.cylinder(p+Vector3(0,1.4,0),.18,2.8,m.wood);g.collider(p+Vector3(0,1.4,0),Vector3(.4,2.8,.4))
 for i in range(5):g.sphere(p+Vector3(sin(i*2.4)*1.3,3.5+cos(i*2)*.7,cos(i*2.4)*1.3),Vector3(2.4,2.2,2.4),m.leaf)
func gateway(p: Vector3) -> void:
 for x in [-3.4,3.4]:
  g.box(p+Vector3(x,2.6,0),Vector3(.45,5.2,.55),m.red,true)
  g.box(p+Vector3(x,.3,0),Vector3(.75,.6,.8),m.stone)
 g.box(p+Vector3(0,4.8,0),Vector3(7.5,.5,.7),m.gold)
 roof(p+Vector3(0,5.3,0),8,2.4,1)
func text3d(text: String,p: Vector3,size: float,color: Color,angle: float) -> void:
 var label=Label3D.new();label.text=text;label.font=load("res://assets/title.ttf");label.font_size=96;label.pixel_size=size;label.modulate=color;label.outline_size=10;label.position=p;label.rotation.y=angle;label.no_depth_test=false;add_child(label)
func pier() -> void:
 g.box(Vector3(7.7,.43,8),Vector3(8,.18,3.2),m.wood)
 g.surface([Vector3(11.8,.51,6.4),Vector3(11.8,.51,9.6),Vector3(3.6,1.01,6.4),Vector3(3.6,1.01,9.6)],[[0,1,2],[1,3,2],[2,1,0],[2,3,1]],m.wood,true)
 for x in [4,7,10]:
  for z in [6.5,9.5]:g.cylinder(Vector3(x,-.25,z),.15,2,m.timber)
 for z in [6.35,9.65]:railing(Vector3(4,.7,z),Vector3(11,.7,z),.65)
func pleasure_barge() -> void:
 # Hull: taper both ends; the deck and boarding surface are separate colliders.
 var c=Vector3(0,.05,7);var verts=[];var tris=[]
 for j in range(3):
  for i in range(20):
   var a=i*TAU/20;var width=[2.8,4.1,4.4][j];var length=[10.1,12.0,12.2][j]
   verts.append(c+Vector3(cos(a)*width,[-.7,.2,.9][j],sin(a)*length))
 for j in range(2):
  for i in range(20):var a=j*20+i;var b=j*20+(i+1)%20;tris.append([a,b,a+20]);tris.append([b,b+20,a+20]);tris.append([a+20,b,a]);tris.append([a+20,b+20,b])
 g.surface(verts,tris,m.timber)
 g.box(c+Vector3(0,.83,0),Vector3(7.8,.25,20.2),m.wood,true)
 for x in [-3.9,3.9]:
  for z in [-3,2,7,12,17]:
   if x>0 and z==7:continue
   railing(Vector3(x,1,z),Vector3(x,1,z+2.5),.9)
   lantern(Vector3(x,2.6,z),.25)
 for z in [-2.6,16.8]:railing(Vector3(-3.8,1,z),Vector3(3.8,1,z),.9)
 for z in [2,8,13]:
  for x in [-2.8,2.8]:g.cylinder(Vector3(x,2.4,z),.12,3,m.red)
 text3d("등 영 화 방",Vector3(0,3.1,13.8),.005,Color("ffe2a6"),0)
 roof(Vector3(0,4.1,7),7.7,13,1.4)
 roof(Vector3(0,6.4,7),5.8,7,1.1)
 g.box(Vector3(0,5.2,7),Vector3(5.2,1.7,6.5),m.red)
 for z in [4.8,6.9,9]:
  for x in [-2.65,2.65]:g.box(Vector3(x,5.2,z),Vector3(.07,1.0,1.3),m.paper)
 for z in [3.0,10.4]:table(Vector3(0,.99,z))
 # The barge does not drift away from its boarding collision.
 for x in [-3,3]:string_lights(Vector3(x,3.8,1),Vector3(x,3.8,13))
