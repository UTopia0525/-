extends Node2D
## Reuses the equipped ready pose; articulated feet and dust while translating.
var pieces: Array=[]
var original: Sprite2D
var elapsed=0.0
var duration=.4
func configure(actor,seconds: float) -> void:
 original=actor.sprite;duration=seconds;position=original.position;scale=original.scale
 var texture=original.texture;var dimensions=texture.get_size();var seam=floorf(dimensions.y*.79)
 for area in [Rect2(0,0,dimensions.x,seam),Rect2(0,seam,dimensions.x/2,dimensions.y-seam),Rect2(dimensions.x/2,seam,dimensions.x/2,dimensions.y-seam)]:
  var sprite=Sprite2D.new();var part=AtlasTexture.new();part.atlas=texture;part.region=area;sprite.texture=part;sprite.centered=false;sprite.position=area.position;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite);pieces.append({"sprite":sprite,"home":area.position})
 original.hide()
func _process(delta: float) -> void:
 elapsed+=delta
 var wave=sin(elapsed/maxf(duration,.01)*TAU*2)
 pieces[0].sprite.position.y=-absf(wave)*2
 for index in range(1,3):
  var direction=1 if index==1 else -1
  pieces[index].sprite.position=pieces[index].home+Vector2(wave*3*direction,-maxf(0,wave*direction)*7)
func finish() -> void:
 if is_instance_valid(original):original.show()
 queue_free()
