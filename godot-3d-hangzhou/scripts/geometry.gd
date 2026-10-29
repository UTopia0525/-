extends RefCounted
## Batched original geometry: one rendered mesh per material, physical volumes separate.
var root: Node3D
var mats: Dictionary={}
var batches: Dictionary={}
var boxes: Array=[]
func _init(parent: Node3D) -> void:root=parent
func material(id: String,color: Color,metal: float=0.0,emit: float=0.0) -> Material:
 if mats.has(id):return mats[id]
 var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.8;m.metallic=metal;m.cull_mode=BaseMaterial3D.CULL_DISABLED
 if emit>0:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=emit
 mats[id]=m;return m
func append(mesh: Mesh,at: Vector3,mat: Material,rotation: Vector3=Vector3.ZERO,scale: Vector3=Vector3.ONE) -> void:
 var id=mat.get_instance_id()
 if not batches.has(id):
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(mat);batches[id]=st
 var transform=Transform3D(Basis.from_euler(rotation).scaled(scale),at)
 batches[id].append_from(mesh,0,transform)
func box(at: Vector3,size: Vector3,mat: Material,solid: bool=false,rotation: Vector3=Vector3.ZERO) -> void:
 var mesh=BoxMesh.new();mesh.size=size;append(mesh,at,mat,rotation)
 if solid:collider(at,size,rotation)
func collider(at: Vector3,size: Vector3,rotation: Vector3=Vector3.ZERO) -> void:
 var body=StaticBody3D.new();body.collision_layer=1;body.position=at;body.rotation=rotation;root.add_child(body)
 var shape=CollisionShape3D.new();var box_shape=BoxShape3D.new();box_shape.size=size;shape.shape=box_shape;body.add_child(shape);boxes.append(body)
func cylinder(at: Vector3,radius: float,height: float,mat: Material,sides: int=12) -> void:
 var mesh=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=sides;mesh.rings=1;append(mesh,at,mat)
func sphere(at: Vector3,size: Vector3,mat: Material) -> void:
 var mesh=SphereMesh.new();mesh.radius=.5;mesh.height=1;mesh.radial_segments=12;mesh.rings=8;append(mesh,at,mat,Vector3.ZERO,size)
func beam(a: Vector3,b: Vector3,r: float,mat: Material) -> void:
 var mesh=CylinderMesh.new();mesh.top_radius=r;mesh.bottom_radius=r;mesh.height=a.distance_to(b);mesh.radial_segments=6;mesh.rings=1
 var direction=(b-a).normalized();var basis=Basis()
 if absf(direction.dot(Vector3.UP))<.999:basis=Basis.looking_at(direction,Vector3.UP)*Basis(Vector3.RIGHT,PI/2)
 elif direction.y<0:basis=Basis(Vector3.RIGHT,PI)
 var id=mat.get_instance_id()
 if not batches.has(id):var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(mat);batches[id]=st
 batches[id].append_from(mesh,0,Transform3D(basis,(a+b)/2))
func surface(vertices: Array,triangles: Array,mat: Material,solid: bool=false) -> void:
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var seen={}
 for tri in triangles:
  var key: Array=tri.duplicate();key.sort()
  if seen.has(str(key)):continue
  seen[str(key)]=true
  for index in tri:st.set_uv(Vector2(vertices[index].x,vertices[index].z));st.add_vertex(vertices[index])
 st.generate_normals();var mesh=st.commit();append(mesh,Vector3.ZERO,mat)
 if solid:
  var body=StaticBody3D.new();body.collision_layer=1;root.add_child(body)
  var shape=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();shape.shape.backface_collision=true;body.add_child(shape)
func flush() -> void:
 for st in batches.values():
  var mesh=st.commit();var instance=MeshInstance3D.new();instance.mesh=mesh;instance.name="Architecture";root.add_child(instance)
 batches.clear()
