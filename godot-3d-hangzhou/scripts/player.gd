extends CharacterBody3D
const WALK=4.2
const RUN=7.6
var yaw=0.0
var pitch=-.24
var zoom=5.5
var phase=0.0
var avatar: Node3D
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var joints: Dictionary={}
var rest: Dictionary={}
var walking=false
var control_enabled=true
var spawn=Vector3(19,.65,45)
func _ready() -> void:
 name="Dowon";collision_layer=2;collision_mask=1;floor_snap_length=.5;floor_max_angle=deg_to_rad(48)
 var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.85;shape.shape=capsule;shape.position.y=.95;add_child(shape)
 avatar=load("res://assets/dowon.glb").instantiate();add_child(avatar)
 avatar.rotation.y=PI
 for id in ["Leg_L","Leg_R","Arm_L","Arm_R","Fore_L","Fore_R","Head"]:
  var joint=avatar.find_child(id,true,false)
  if joint:joints[id]=joint;rest[id]=joint.rotation
 pivot=Node3D.new();pivot.position.y=1.42;add_child(pivot)
 arm=SpringArm3D.new();arm.spring_length=zoom;arm.margin=.2;arm.collision_mask=1;arm.add_excluded_object(get_rid());var sphere=SphereShape3D.new();sphere.radius=.19;arm.shape=sphere;pivot.add_child(arm)
 camera=Camera3D.new();camera.fov=65;camera.near=.08;camera.far=280;arm.add_child(camera);camera.current=true
 position=spawn;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and (Input.mouse_mode==Input.MOUSE_MODE_CAPTURED or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
  yaw-=event.relative.x*.003;pitch=clampf(pitch-event.relative.y*.0025,-.85,.22)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom=maxf(1.5,zoom-.6)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom=minf(11,zoom+.6)
  elif event.button_index==MOUSE_BUTTON_LEFT and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
  if event.keycode==KEY_R:reset_position()
func reset_position() -> void:position=spawn;velocity=Vector3.ZERO;yaw=0;pitch=-.24
func _physics_process(delta: float) -> void:
 var input=Input.get_vector("left","right","forward","back") if control_enabled else Vector2.ZERO
 var direction=Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
 var speed=RUN if Input.is_action_pressed("sprint") else WALK
 velocity.x=move_toward(velocity.x,direction.x*speed,delta*24)
 velocity.z=move_toward(velocity.z,direction.z*speed,delta*24)
 if not is_on_floor():velocity.y-=22*delta
 elif Input.is_action_just_pressed("jump") and control_enabled:velocity.y=7.0
 else:velocity.y=-.1
 move_and_slide()
 if position.y< -3:reset_position()
 pivot.rotation.y=yaw;arm.rotation.x=pitch;arm.spring_length=lerpf(arm.spring_length,zoom,delta*10)
 walking=Vector2(velocity.x,velocity.z).length()>.15
 if walking:
  avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(direction.x,direction.z),minf(1,delta*13))
  phase+=delta*(11.0 if speed==RUN else 8.2)
 var swing=sin(phase)*(.58 if speed==RUN else .38) if walking else 0.0
 for id in joints:
  var target: Vector3=rest[id]
  if id=="Leg_L":target.x+=swing
  elif id=="Leg_R":target.x-=swing
  elif id=="Arm_L":target.x-=swing*.75
  elif id=="Arm_R":target.x+=swing*.75
  elif id.begins_with("Fore"):target.x=-.12-absf(swing)*.2
  joints[id].rotation=joints[id].rotation.lerp(target,minf(1,delta*16))
 avatar.position.y=absf(sin(phase*2))*.022 if walking else 0.0
