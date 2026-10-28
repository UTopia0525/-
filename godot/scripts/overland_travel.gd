extends RefCounted
const AREAS=["changsha","mountain_road","wuchang","alliance_office","qingya_hamlet","qingya_camp","nanjing","namgung_estate","suzhou","nanjing_suzhou_road"]
const LINKS={
 "changsha":[{"id":"travel:road_east","name":"무창 방면 산길 →","point":[1490,510],"area":"mountain_road","arrival":[125,1175]}],
 "mountain_road":[{"id":"travel:changsha","name":"← 장사 동쪽 농촌","point":[80,1175],"area":"changsha","arrival":[1440,510]}, {"id":"travel:wuchang","name":"↑ 무창 남쪽 농촌","point":[740,64],"area":"wuchang","arrival":[1100,1790]}],
 "alliance_office":[{"id":"travel:office_exit","name":"무림맹 외원으로","point":[256,321],"area":"wuchang","arrival":[1077,795]}],
 "qingya_hamlet":[{"id":"travel:wuchang","name":"← 무창","point":[70,530],"area":"wuchang","arrival":[1920,945]},{"id":"travel:camp","name":"↑ 청애채","point":[780,60],"area":"qingya_camp","arrival":[1152,1480]},{"id":"travel:nanjing","name":"남경 →","point":[1470,530],"area":"nanjing","arrival":[255,530]}],
 "namgung_estate":[{"id":"travel:nanjing","name":"남경 방면 →","point":[768,1070],"area":"nanjing","arrival":[300,160]}],
 "suzhou":[{"id":"travel:suzhou_road","name":"← 남경 방면 산길","point":[48,512],"area":"nanjing_suzhou_road","arrival":[1450,570]}],
 "nanjing_suzhou_road":[{"id":"travel:nanjing","name":"← 남경","point":[35,460],"area":"nanjing","arrival":[1470,995]},{"id":"travel:suzhou","name":"소주 →","point":[1500,570],"area":"suzhou","arrival":[85,512]}],
 "nanjing":[{"id":"travel:suzhou_road","name":"소주 방면 산길 →","point":[1470,995],"area":"nanjing_suzhou_road","arrival":[85,462]},{"id":"travel:namgung","name":"합비 · 남궁세가 방면","point":[300,115],"area":"namgung_estate","arrival":[768,1050]},{"id":"travel:hamlet","name":"← 삼거리 산촌·무창 방면","point":[110,530],"area":"qingya_hamlet","arrival":[1410,530]}],
 "qingya_camp":[{"id":"travel:hamlet","name":"↓ 삼거리 산촌","point":[768,960],"area":"qingya_hamlet","arrival":[780,115]}],
 "wuchang":[{"id":"travel:office_entry","name":"총무당 · 들어가기","point":[1077,775],"area":"alliance_office","arrival":[256,289]}, {"id":"travel:road_south","name":"↓ 장사 방면 산길","point":[1100,1840],"area":"mountain_road","arrival":[740,110]},{"id":"travel:qingya","name":"산촌·청애채 방면 →","point":[1948,945],"area":"qingya_hamlet","arrival":[135,530]}]}
static func install(world) -> void:
	world.travel_exits.clear()
	for link in LINKS.get(world.area_name,[]):
		var marker=preload("res://scripts/travel_portal.gd").new();marker.position=world.city_point(link.point)
		world.decorations.add_child(marker);world.occlusion_roots.append(marker)
		var label_y=64 if world.map_bounds.end.x-marker.position.x<340 else -164
		var label=preload("res://scripts/ui.gd").label(marker,link.name,Rect2(-180,label_y,360,32),20,Color("9de5ff"))
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_color_override("font_outline_color",Color("14231e"));label.add_theme_constant_override("outline_size",5)
		world.travel_exits.append({"id":link.id,"name":link.name,"position":marker.position,"node":marker,"frame":-1,"travel":link,"important":true,"portal_label":label,"open_name":link.name})
static func use(game,entry: Dictionary) -> bool:
	if not entry.has("travel"):return false
	var link: Dictionary=entry.travel
	var reason=blocked_reason(game,link.area)
	if not reason.is_empty():
		game.say([["hero",reason]])
		return true
	game.exploration.set_active(false)
	game.qingya_quest.before_travel(game.exploration.area_name,link.area)
	game.qingya_quest.on_arrive(link.area)
	game.exploration.load_area(link.area)
	game.exploration.player.position=game.exploration.safe_player_position(game.exploration.city_point(link.arrival))
	game.exploration.player.stop();game.exploration.camera.snap_to_player()
	game.exploration.set_active(true);game.music.play_track("voyage" if link.area in ["mountain_road","qingya_hamlet","qingya_camp","nanjing_suzhou_road"] else "dock")
	game.ordinary_quests.refresh_world()
	game.adventure_ui.notify(game.exploration.city_data.name+"에 들어섰습니다.","confirm")
	return true

static func blocked_reason(game,destination: String) -> String:
	if game.exploration.area_name!="changsha" or destination=="changsha":return ""
	if game.bandit_story.stage=="completed" and game.bandit_story.reward_granted:return ""
	if game.bandit_story.stage=="report":return "도적은 물리쳤지만 아직 정 포두께 보고하지 않았다. 관아에서 보수를 받고 통행이 풀리면 떠나자."
	return "도적들 때문에 성밖 통행이 막혀 있다. 장사에서 근기를 쌓아 다섯 능력치의 총합을100 이상으로 높이고 새 무공을 익힌 뒤, 토벌을 마쳐 정 포두께 보고해야 떠날 수 있겠군."
