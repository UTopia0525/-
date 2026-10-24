extends RefCounted
const AREAS=["changsha","mountain_road","wuchang"]
const LINKS={
 "changsha":[{"id":"travel:road_east","name":"무창 방면 산길 →","point":[768,94],"area":"mountain_road","arrival":[125,1175]}],
 "mountain_road":[{"id":"travel:changsha","name":"← 장사 북문","point":[80,1175],"area":"changsha","arrival":[768,125]}, {"id":"travel:wuchang","name":"↑ 무창 남문","point":[740,64],"area":"wuchang","arrival":[1100,1435]}],
 "wuchang":[{"id":"travel:road_south","name":"↓ 장사 방면 산길","point":[1100,1508],"area":"mountain_road","arrival":[740,110]}]}
static func install(world) -> void:
	world.travel_exits.clear()
	for link in LINKS.get(world.area_name,[]):
		var marker=preload("res://scripts/travel_portal.gd").new();marker.position=world.city_point(link.point)
		world.decorations.add_child(marker);world.occlusion_roots.append(marker)
		var label=preload("res://scripts/ui.gd").label(marker,link.name,Rect2(-180,-164,360,32),20,Color("9de5ff"))
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_color_override("font_outline_color",Color("14231e"));label.add_theme_constant_override("outline_size",5)
		world.travel_exits.append({"id":link.id,"name":link.name,"position":marker.position,"node":marker,"frame":-1,"travel":link,"important":true})
static func use(game,entry: Dictionary) -> bool:
	if not entry.has("travel"):return false
	var link: Dictionary=entry.travel
	game.exploration.set_active(false)
	game.exploration.load_area(link.area)
	game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point(link.arrival))
	game.exploration.player.stop();game.exploration.camera.snap_to_player()
	game.exploration.set_active(true);game.music.play_track("voyage" if link.area=="mountain_road" else "dock")
	game.ordinary_quests.refresh_world()
	game.adventure_ui.notify(game.exploration.city_data.name+"에 들어섰습니다.","confirm")
	return true
