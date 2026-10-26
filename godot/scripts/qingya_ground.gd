extends Node2D
var data: Dictionary
var terrain_texture: Texture2D
func _ready() -> void:
	terrain_texture=load(data.ground_texture)
func _draw() -> void:
	if terrain_texture:draw_texture_rect(terrain_texture,Rect2(Vector2.ZERO,Vector2(data.art_size[0],data.art_size[1])),false)
