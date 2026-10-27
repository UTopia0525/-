extends Node2D
## Rigid equipment stays separate from the deforming boot mesh.
const SHEET=preload("res://assets/animation/carried_weapons.png")
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/carried_weapons.json"))
var sprite: Sprite2D
var weapon_type="sword"
var textures: Dictionary={}
var back_strap=false
var body_height=140.0
func _ready() -> void:
 z_index=0
 sprite=Sprite2D.new();sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
 for id in definitions:
  var r=definitions[id].region;var atlas=AtlasTexture.new();atlas.atlas=load(definitions[id].texture) if definitions[id].has("texture") else SHEET;atlas.region=Rect2(r[0],r[1],r[2],r[3]);textures[id]=atlas
 set_weapon(weapon_type)
func set_weapon(kind: String) -> void:
 weapon_type=kind;visible=kind in definitions;back_strap=false;queue_redraw()
 if not visible or not is_instance_valid(sprite):return
 sprite.texture=textures[kind];var grip=definitions[kind].grip;sprite.offset=-Vector2(grip[0],grip[1])
func update_pose(facing: String,_phase: float,_walking: bool,height: float) -> void:
 if not visible:return
 var data: Dictionary=definitions[weapon_type]
 body_height=height;back_strap=weapon_type=="spear" and facing=="up"
 z_index=1 if weapon_type=="saber" or back_strap else 0
 var sign_value: float
 if weapon_type=="spear":
  # Centre the shaft on the back, with the head above the opposite shoulder.
  # Front/side views hide the middle behind the torso; rear view exposes it.
  position={"down":Vector2(.02,-.58),"up":Vector2(-.02,-.58),"left":Vector2(.13,-.58),"right":Vector2(-.13,-.58)}[facing]*height
  sprite.offset=-Vector2(280,580)
  sign_value=-1.0 if facing in ["down","right"] else 1.0
  sprite.rotation=0.0
 else:
  position={"down":Vector2(.15,-.40),"up":Vector2(-.15,-.40),"left":Vector2(.10,-.40),"right":Vector2(-.10,-.40)}[facing]*height
  sign_value=-1.0 if facing in ["up","left"] else 1.0
  sprite.rotation=-float(data.tilt)*sign_value
 var scale_value=height*float(data.height_ratio)/float(data.region[3])
 sprite.scale=Vector2(sign_value*scale_value,scale_value)
 queue_redraw()
func _draw() -> void:
 if not back_strap:return
 var from=Vector2(-.19,-.58)*body_height-position
 var to=Vector2(.19,-.36)*body_height-position
 draw_line(from,to,Color("34271e"),body_height*.035,true)
 draw_line(from,to,Color("8b6542"),body_height*.017,true)
