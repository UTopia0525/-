extends Node2D
var data: Dictionary
var texture: Texture2D
func _ready() -> void:
	var rng=RandomNumberGenerator.new();rng.seed=1421
	var noise=FastNoiseLite.new();noise.seed=731;noise.frequency=.024
	var image=Image.create(512,1280,false,Image.FORMAT_RGB8)
	for y in range(1280):
		for x in range(512):
			var v=noise.get_noise_2d(x,y)*.15+rng.randf_range(-.018,.018)
			image.set_pixel(x,y,Color(.32+v,.37+v,.24+v*.6))
	texture=ImageTexture.create_from_image(image)
func _draw() -> void:
	if not is_instance_valid(texture):return
	draw_texture_rect(texture,Rect2(0,0,1024,2560),false)
	var rng=RandomNumberGenerator.new();rng.seed=1234
	# Rock faces form terrain relief; trees and individual boulders are independent sprites.
	for side in [0,1]:
		var edge=PackedVector2Array([Vector2(-10 if side==0 else 1100,-10)])
		for y in range(0,2640,80):
			var x=rng.randf_range(220,340) if side==0 else rng.randf_range(930,1050)
			edge.append(Vector2(x,y))
		edge.append(Vector2(-10 if side==0 else 1100,2600))
		draw_colored_polygon(edge,Color("616b52") if side==0 else Color("56654c"))
		for i in range(1,edge.size()-2):
			var p=edge[i];var toward=Vector2(-rng.randf_range(70,150),36) if side==0 else Vector2(rng.randf_range(70,150),36)
			draw_colored_polygon(PackedVector2Array([p,edge[i+1],p+toward]),Color("77806b",.42))
			draw_line(p,edge[i+1],Color("91947b",.45),2)
	var path=PackedVector2Array()
	for p in data.route:path.append(Vector2(p[0],p[1]))
	for layer in [[49.0,Color("777656")],[39.5,Color("9a8862")],[29.0,Color("b6a077")]]:
		draw_polyline(path,layer[1],layer[0]*2,false)
		for p in path:draw_circle(p,layer[0],layer[1])
	for a in range(path.size()-1):
		var delta=path[a+1]-path[a];var tangent=delta.normalized().orthogonal()
		for j in range(int(delta.length()*1.7)):
			var p=path[a].lerp(path[a+1],rng.randf())+tangent*rng.randf_range(-27,27)
			draw_rect(Rect2(p,Vector2(rng.randf_range(.6,2.7),rng.randf_range(.3,1))),Color("75654c",.36))
