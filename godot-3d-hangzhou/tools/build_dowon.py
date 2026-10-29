"""Original stylized 3D Dowon, matching the approved blue robe/cream collar/brown sash.
Run: blender -b --python tools/build_dowon.py. All geometry/materials are original.
Rigid articulated mesh groups keep the standalone GLB simple and reproducible.
"""
import bpy, math, pathlib
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
out=pathlib.Path(__file__).resolve().parents[1]/'assets/dowon.glb'
def mat(name,c,rough=.8,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
blue=mat('Indigo woven robe',(.075,.18,.29));edge=mat('Blue seams',(.13,.28,.40));darkblue=mat('Robe shaded folds',(.055,.115,.19));cream=mat('Undyed collar and cuffs',(.77,.72,.60));brown=mat('Brown cloth sash',(.19,.115,.072));leather=mat('Wrist bindings and boots',(.075,.047,.035));skin=mat('Warm skin',(.62,.38,.23),.75);hair=mat('Black hair',(.019,.023,.028),.55);hairshine=mat('Hair strand highlights',(.045,.050,.058),.6);black=mat('Eyes pupils',(.01,.008,.006),.25);white=mat('Eyes ivory',(.8,.76,.66),.65);lip=mat('Lips',(.34,.16,.10));iris=mat('Iris',(.13,.075,.035),.4)
def node(name,loc,parent=None):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=loc
 if parent:o.parent=parent
 return o
root=node('Dowon',(0,0,0));body=node('Body',(0,0,0),root)
def finish(o,name,m,parent):
 o.name=name;o.data.materials.append(m)
 if parent:o.parent=parent
 for f in o.data.polygons:f.use_smooth=True
 return o
def ell(name,loc,scale,m,parent=body):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,location=(0,0,0));o=bpy.context.object;o.location=loc;o.scale=scale;return finish(o,name,m,parent)
def box(name,loc,scale,m,parent=body,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object;o.location=loc;o.scale=scale;finish(o,name,m,parent)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Soft tailored edges','BEVEL');mod.width=bevel;mod.segments=2
  mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return o
def tube(name,points,r,m,parent=body):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=8;c.bevel_depth=r;c.bevel_resolution=2;s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for p,v in zip(s.bezier_points,points):p.co=v;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(m);o.parent=parent;return o
def profile(name,rings,m,parent=body,n=24):
 verts=[]
 for z,rx,ry in rings:
  for i in range(n):
   a=i*math.tau/n;fold=1+.025*math.cos(a*8);verts.append((math.cos(a)*rx*fold,math.sin(a)*ry*fold,z))
 faces=[]
 for j in range(len(rings)-1):
  for i in range(n):a=j*n+i;b=j*n+(i+1)%n;faces.append((a,b,b+n,a+n))
 faces += [tuple(range(n-1,-1,-1)),tuple((len(rings)-1)*n+i for i in range(n))]
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);return finish(o,name,m,parent)
# Approx. 1.83m tall; forward is Blender -Y (Godot -Z).
profile('Cross collar torso',[(.85,.20,.13),(1.02,.21,.14),(1.30,.265,.15),(1.43,.22,.135),(1.46,.13,.10)],blue)
# Tailored crossed lapels, attached to the torso, not a painted billboard.
a=box('Left cream lapel',(-.065,-.151,1.295),(.065,.024,.34),cream);a.rotation_euler.y=-.5
a=box('Right cream lapel',(.065,-.152,1.295),(.065,.025,.34),cream);a.rotation_euler.y=.5
a=box('Outer blue lapel',(.025,-.174,1.265),(.065,.024,.36),edge);a.rotation_euler.y=.48
profile('Sash belt',[(.94,.223,.145),(1.045,.218,.143)],brown)
for z in [.96,.985,1.015]:
 tube('Sash wrapped cord',[(-.22,-.09,z),(-.10,-.155,z+.008),(.15,-.145,z-.005),(.22,0,z)],.012,brown)
ell('Sash knot',(.14,-.17,.985),(.055,.035,.05),brown)
for x in [.12,.17]:
 a=box('Loose sash tail',(x,-.18,.77),(.045,.025,.35),brown);a.rotation_euler.y=.13
# Two robe skirts are jointed with the legs for readable cloth movement.
for side,x in [('L',-.11),('R',.11)]:
 leg=node('Leg_'+side,(x,0,.91),body)
 profile('Robe skirt '+side,[(-.46,.19,.18),(-.28,.17,.16),(.03,.125,.13)],blue,leg)
 tube('Skirt front seam '+side,[(-.12,-.13,-.43),(-.10,-.145,-.2),(-.08,-.12,0)],.008,edge,leg)
 ell('Trousers '+side,(0,0,-.48),(.095,.09,.25),darkblue,leg)
 box('Boot '+side,(0,-.035,-.79),(.16,.29,.20),leather,leg,.035)
 box('Boot sole '+side,(0,-.04,-.885),(.175,.3,.025),brown,leg,.009)
 for z in [-.69,-.73]:box('Boot ties '+side,(0,-.10,z),(.16,.045,.025),brown,leg,.008)
# Arms carry sleeve volumes, cuffs, wrist wraps and visible fingers.
for side,x,angle in [('L',-.27,-.09),('R',.27,.09)]:
 arm=node('Arm_'+side,(x,0,1.33),body);arm.rotation_euler.y=angle
 ell('Upper sleeve '+side,(x*.12,0,-.13),(.14,.15,.25),blue,arm)
 fore=node('Fore_'+side,(0,-.018,-.32),arm)
 profile('Wide lower sleeve '+side,[(-.16,.125,.13),(.12,.125,.14)],blue,fore)
 profile('Ivory cuff '+side,[(-.185,.13,.135),(-.135,.13,.135)],cream,fore)
 ell('Wrist '+side,(0,-.015,-.24),(.06,.065,.10),skin,fore)
 for z in [-.21,-.24,-.27]:profile('Wrist binding '+side,[(z-.012,.064,.07),(z+.012,.064,.07)],leather,fore,16)
 ell('Hand '+side,(0,-.02,-.34),(.067,.055,.09),skin,fore)
 for k in range(4):ell('Finger '+side+str(k),(-.045+k*.029,-.035,-.39),(.014,.025,.045),skin,fore)
 ell('Thumb '+side,(.066 if side=='L' else -.066,-.055,-.33),(.025,.03,.055),skin,fore)
# Detailed low-poly sculpted head: ears, brows, eyelids, nose, mouth and tied hair.
head=node('Head',(0,0,1.46),body)
ell('Neck',(0,0,.015),(.085,.085,.12),skin,head)
ell('Face',(0,-.015,.185),(.15,.125,.205),skin,head)
ell('Jaw',(0,-.045,.085),(.112,.095,.095),skin,head)
for x in [-.15,.15]:ell('Ear',(x,.0,.17),(.033,.026,.061),skin,head)
for x in [-.065,.065]:
 ell('Eye socket',(x,-.124,.205),(.049,.014,.027),brown,head)
 ell('Eye',(x,-.135,.205),(.038,.009,.016),white,head)
 ell('Iris',(x,-.143,.205),(.014,.006,.015),iris,head)
 ell('Pupil',(x,-.149,.205),(.007,.004,.011),black,head)
 tube('Upper eyelid',[(x-.036,-.138,.208),(x,-.145,.22),(x+.034,-.138,.21)],.004,brown,head)
 tube('Strong brow',[(x-.042,-.125,.245),(x,-.139,.253),(x+.037,-.127,.244)],.009,hair,head)
ell('Nose bridge',(0,-.135,.17),(.019,.03,.058),skin,head)
ell('Nose tip',(0,-.16,.135),(.027,.023,.019),skin,head)
tube('Neutral mouth',[(-.039,-.132,.095),(0,-.145,.09),(.039,-.132,.095)],.004,lip,head)
ell('Hair cap',(0,.018,.26),(.16,.133,.15),hair,head)
ell('Hair back',(0,.105,.17),(.155,.07,.18),hair,head)
ell('Tied knot',(0,.08,.40),(.09,.08,.075),hair,head)
tube('Brown hair tie',[(-.065,.045,.397),(0,.0,.40),(.07,.06,.40)],.015,brown,head)
for i in range(10):
 x=-.13+i*.028
 tube('Swept hair strand',[(x*.3,-.05,.37),(x,-.119,.31),(x*.9,-.133,.25-(.05 if i<4 else 0))],.014,hair if i%3 else hairshine,head)
for i in range(6):
 x=-.07+i*.028
 tube('Long ponytail',[(x,.12,.38),(x*.9,.19,.15),(x*.8,.19,-.09),(x*.5,.14,-.27)],.026,hair if i%2 else hairshine,head)
for sign in [-1,1]:tube('Loose temple lock',[(sign*.12,-.085,.28),(sign*.145,-.10,.15),(sign*.13,-.075,.03)],.013,hair,head)
# Convert curves for portable glTF and apply bevels; keep articulated node names.
for o in list(bpy.context.scene.objects):
 if o.type in {'MESH','CURVE'}:
  bpy.context.view_layer.objects.active=o;o.select_set(True)
  if o.type=='CURVE':bpy.ops.object.convert(target='MESH')
  for mod in list(o.modifiers):
   try:bpy.ops.object.modifier_apply(modifier=mod.name)
   except:pass
  o.select_set(False)
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_yup=True,export_animations=False)
print('DOWON_GLB:',out)
