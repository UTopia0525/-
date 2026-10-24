extends Node2D
## Authored terrain only; independent scenery retains collision and foot sorting.
var data: Dictionary
var atlas_mode=false
var terrain_texture: Texture2D
func _draw() -> void:
	var path="res://assets/maps/wuchang/"+("furniture.png" if atlas_mode else "ground.png")
	terrain_texture=load(path)
	var size=Vector2(384,200) if atlas_mode else Vector2(data.art_size[0],data.art_size[1]) if not data.is_empty() else Vector2(512,360)
	draw_texture_rect(terrain_texture,Rect2(Vector2.ZERO,size),false)
