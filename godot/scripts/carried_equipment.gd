extends Node2D
## Separate rigid equipment: boot deformation never bends a shaft or scabbard.
const SHEET=preload("res://assets/animation/carried_weapons.png")
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/carried_weapons.json"))
var sprite: Sprite2D
var weapon_type="sword"
var textures: Dictionary={}
func _ready() -> void:
 z_index=0
 sprite=Sprite2D.new();sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
 for id in definitions:
  var r=definitions[id].region;var atlas=AtlasTexture.new();atlas.atlas=SHEET;atlas.region=Rect2(r[0],r[1],r[2],r[3]);textures[id]=atlas
 set_weapon(weapon_type)
func set_weapon(kind: String) -> void:
 weapon_type=kind;visible=kind in definitions
 if not visible or not is_instance_valid(sprite):return
 sprite.texture=textures[kind];var grip=definitions[kind].grip;sprite.offset=-Vector2(grip[0],grip[1])
func update_pose(facing: String,phase: float,walking: bool,height: float) -> void:
 if not visible:return
 z_index=1 if weapon_type=="saber" else 0
 var data: Dictionary=definitions[weapon_type];var side=facing in ["left","right"]
 var anchor: Vector2
 if weapon_type=="spear":anchor={"down":Vector2(-.16,-.35),"up":Vector2(.15,-.37),"left":Vector2(-.26,-.42),"right":Vector2(.26,-.42)}[facing]*height
 else:anchor={"down":Vector2(.15,-.40),"up":Vector2(-.15,-.40),"left":Vector2(.10,-.40),"right":Vector2(-.10,-.40)}[facing]*height
 if walking and not side and weapon_type=="spear":anchor+=Vector2(sin(phase)*1.3,cos(phase)*.6)
 position=anchor
 var sign=-1.0 if facing in ["down","left"] and weapon_type=="spear" or facing in ["up","left"] and weapon_type=="saber" else 1.0
 var scale_value=height*float(data.height_ratio)/float(data.region[3])
 sprite.scale=Vector2(sign*scale_value,scale_value);sprite.rotation=-float(data.tilt)*sign
