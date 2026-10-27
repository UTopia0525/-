extends RefCounted
## Native-resolution detail for terrain only. Geometry and source art stay intact.
const SHADER=preload("res://shaders/terrain_detail.gdshader")
const DETAIL=preload("res://assets/maps/materials/terrain-microdetail.png")
static func apply(background: Sprite2D, area: String, bounds: Rect2) -> void:
 if area in ["dock","deck"]:
  background.material=null;background.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;return
 var material=background.material as ShaderMaterial
 if material==null or material.shader!=SHADER:
  material=ShaderMaterial.new();material.shader=SHADER
 material.set_shader_parameter("terrain_detail",DETAIL)
 material.set_shader_parameter("world_size",bounds.size)
 background.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 background.material=material
