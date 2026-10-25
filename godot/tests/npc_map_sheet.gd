extends Node2D
## Accurate game-layer render with numbered resident pins and a separate event key.
const UI=preload("res://scripts/ui.gd")
var ground: Texture2D
var tiles: Array=[]
var district_data: Array=[]
var art_size:=Vector2.ONE
var bounds:=Vector2.ONE
var title:=""
var records: Array=[]
var note:=""
var map_rect:=Rect2()
const INK=Color("e8e7d5")
const TEAL=Color("73d5bc")
const GOLD=Color("e0bb70")
const CORAL=Color("f39a84")
const VIOLET=Color("bea0ea")
func _ready() -> void:
	var fit=minf(2048.0/bounds.x,1920.0/bounds.y)
	map_rect=Rect2(Vector2(34,154)+(Vector2(2048,1920)-bounds*fit)/2,bounds*fit)
func _text(pos: Vector2,value: String,size: int,color: Color=INK) -> void:
	var font=UI.BRUSH_FONT if size>=50 else UI.BODY_FONT
	draw_string_outline(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,5,Color("0b1715"))
	draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw() -> void:
	draw_rect(Rect2(0,0,3100,2160),Color("101c1a"))
	_text(Vector2(38,70),title+" · NPC 배치 지도",52,GOLD)
	_text(Vector2(40,116),"번호는 오른쪽 명단과 대응 · 실제 게임 배치 좌표 기준",28)
	draw_rect(map_rect.grow(4),GOLD)
	draw_texture_rect(ground,map_rect,false)
	for tile in tiles:
		var rect=Rect2(map_rect.position+tile.target.position/art_size*map_rect.size,tile.target.size/art_size*map_rect.size)
		draw_texture_rect_region(tile.texture,rect,tile.source)
	for district in district_data:
		var point=map_rect.position+Vector2(district.label[0],district.label[1])/art_size*map_rect.size
		_text(point,str(district.name),23,Color("f5eedc"))
	var y=177.0
	_text(Vector2(2130,y),"상시 배치 / 시설",33,TEAL);y+=52
	var previous=""
	for i in range(records.size()):
		var record: Dictionary=records[i];var kind: String=record.get("kind","resident")
		if kind=="event" and previous!="event":y+=14;_text(Vector2(2130,y),"사건별 위치 · 같은 인물의 다른 위치 포함",29,CORAL);y+=47
		var color=CORAL if kind=="event" else VIOLET if kind=="interior" else GOLD if record.get("service",false) else TEAL
		var point=map_rect.position+Vector2(record.position[0],record.position[1])/bounds*map_rect.size
		draw_circle(point,22,Color("0d1919"))
		if kind=="event":draw_arc(point,22,0,TAU,40,color,4)
		else:draw_circle(point,21,color)
		var number=str(i+1);var width=UI.BODY_FONT.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,27).x
		_text(point+Vector2(-width/2,9),number,27,color if kind=="event" else Color("15251e"))
		_text(Vector2(2130,y),"%02d  %s" % [i+1,record.name],31,color)
		_text(Vector2(2184,y+29),str(record.get("detail","")),23,Color("b9c9c1"));y+=74
		previous=kind
	_text(Vector2(40,2120),note,25)
	_text(Vector2(2130,2117),"노랑: 거래 시설 / 보라: 건물 내부",22,GOLD)
