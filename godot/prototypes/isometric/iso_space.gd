extends RefCounted
## Continuous logical tile coordinates; elevation is deliberately excluded.
const TILE=Vector2(128,64)
static func project(p: Vector2) -> Vector2:return Vector2((p.x-p.y)*TILE.x/2,(p.x+p.y)*TILE.y/2)
static func unproject(p: Vector2) -> Vector2:return Vector2(p.x/TILE.x+p.y/TILE.y,p.y/TILE.y-p.x/TILE.x)
static func diamond(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([project(r.position),project(Vector2(r.end.x,r.position.y)),project(r.end),project(Vector2(r.position.x,r.end.y))])
static func from_legacy(rect: Array,units_per_tile: float) -> Rect2:
	return Rect2(Vector2(rect[0],rect[1])/units_per_tile,Vector2(rect[2],rect[3])/units_per_tile)
# Rectangles are logical ground footprints, never the visible roof bounds.
static func before(a: Rect2,b: Rect2) -> bool:
	var ab=a.end.x<=b.position.x or a.end.y<=b.position.y
	var ba=b.end.x<=a.position.x or b.end.y<=a.position.y
	return ab and not ba
