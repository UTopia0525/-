extends RefCounted
## Shared art at one world scale; short end sections crop masonry, never squash it.
const WALL="res://assets/maps/hangzhou/painted/city-walls.png"
const FRONT="res://assets/maps/hangzhou/painted/city-gate.png"
const SIDE="res://assets/maps/fortifications/side-gate.png"
static func prefab(texture: String,source: Array,kind: String,footprints: Array) -> Dictionary:
	return {"texture":texture,"source":source,"kind":kind,"footprints":footprints,"preserve_aspect":true,"smooth_filter":true,"contact_shadow":true}
static func apply(data: Dictionary) -> void:
	if not data.has("fortification_plan") or data.get("fortifications_built",false):return
	data.fortifications_built=true
	if not data.has("prefabs"):data.prefabs={}
	var p: Dictionary=data.prefabs;var plan: Dictionary=data.fortification_plan
	p.fort_front=prefab(FRONT,[0,0,1254,1254],"gate",[[.02,.54,.32,.46],[.66,.54,.32,.46]])
	p.fort_postern=prefab("res://assets/maps/fortifications/postern-gate.png",[10,175,1515,710],"gate",[[.02,.45,.35,.55],[.63,.45,.35,.55]])
	p.fort_east=prefab(SIDE,[300,38,565,1468],"gate",[[.195,.356,.325,.184],[.474,.72,.41,.275]])
	p.fort_west=p.fort_east.duplicate(true);p.fort_west.flip_h=true
	for h in plan.get("horizontal",[]):horizontal(data,h[0],h[1],h[2],h[3])
	for v in plan.get("vertical",[]):vertical(data,v[0],v[1],v[2],v[3])
	for g in plan.get("gates",[]):
		var r: Array=g[2]
		data.objects.append({"id":g[0],"prefab":"fort_"+g[1],"rect":r,"opening_axis":"east_west" if g[1] in ["east","west"] else "north_south","passage_point":[r[0]+r[2]*.5,r[1]+r[3]*(.635 if g[1] in ["east","west"] else .96)]})
static func horizontal(data: Dictionary,id: String,from: float,to: float,bottom: float) -> void:
	var x=from;var index=0
	while x<to-.01:
		var w=minf(227.2,to-x);var key="fort_h_"+str(snappedf(w,.001))
		data.prefabs[key]=prefab(WALL,[60,73,w/.16,322],"wall",[[0,.55,1,.45]])
		data.objects.append({"id":id+"_"+str(index),"prefab":key,"rect":[x,bottom-51.52,w,51.52]});x+=w;index+=1
static func vertical(data: Dictionary,id: String,x: float,from: float,to: float) -> void:
	var y=from;var index=0
	while y<to-.01:
		var h=minf(84.48,to-y);var key="fort_v_"+str(snappedf(h,.001))
		data.prefabs[key]=prefab(WALL,[315,435,198,h/.16],"wall",[[.22,0,.56,1]])
		data.objects.append({"id":id+"_"+str(index),"prefab":key,"rect":[x,y,31.68,h]});y+=h;index+=1
