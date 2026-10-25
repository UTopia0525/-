extends SceneTree
var game
var exported: Dictionary={}
func _initialize() -> void:run.call_deferred()
func find(id: String):
	for npc in game.exploration.ambient_nodes:
		if npc.get_meta("npc_id")==id:return npc
	return null
func record(id: String,name: String,detail: String,kind: String="event") -> Dictionary:
	var npc=find(id);assert(npc!=null,"NPC must exist to annotate: "+id)
	return {"id":id,"name":name,"detail":detail,"kind":kind,"position":[npc.position.x,npc.position.y]}
func save_sheet(area: String,records: Array,note: String) -> void:
	var w=game.exploration
	var view=SubViewport.new();view.world_2d=World2D.new();view.size=Vector2i(3100,2160);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var sheet=load("res://tests/npc_map_sheet.gd").new()
	sheet.ground=w.background.texture;sheet.tiles=w.art_tiles.duplicate();sheet.district_data=w.city_data.districts.duplicate(true);sheet.art_size=Vector2(w.city_data.art_size[0],w.city_data.art_size[1]);sheet.bounds=w.map_bounds.size;sheet.title=w.city_data.name;sheet.records=records;sheet.note=note;view.add_child(sheet)
	await create_timer(.6).timeout;await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png("res://screenshots/"+area+"-npc-map.png")==OK)
	exported[area]={"world_size":[w.map_bounds.size.x,w.map_bounds.size.y],"records":records,"note":note}
	view.free();await process_frame
func baseline() -> Array:
	var result=[]
	for npc in game.exploration.ambient_nodes:
		var id: String=npc.get_meta("npc_id");var service: String=npc.get_meta("service_id","")
		var label: String=npc.get_meta("display_name")
		var detail: String=npc.get_meta("post","")
		result.append({"id":id,"name":label,"detail":detail,"kind":"resident","service":not service.is_empty(),"position":[npc.position.x,npc.position.y]})
	return result
func run() -> void:
	root.size=Vector2i(1280,720);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_city()
	var changsha=baseline();assert(changsha.size()==16)
	await save_sheet("changsha",changsha,"장사 상시 NPC16명 · 송지겸의 초대는 플레이어 주변에서 발생하여 고정 위치 표시에서 제외")
	game.start_wuchang();var world=game.exploration;var rows=baseline();assert(rows.size()==13)
	rows.append({"id":"heo_mungyu","name":"허문규","detail":"총무당 내부 · 표시는 실내 출입 지점","kind":"interior","position":[1077*4,775*4]})
	game.inn_quest.phase="listening";game.inn_quest.refresh_world()
	rows.append(record("inn_worker","양복","객잔 시비 의뢰 진행 중"));rows.append(record("inn_warrior","장만길","객잔 시비 의뢰 진행 중"))
	game.duel_quest.phase="accepted";game.duel_quest.refresh_world();rows.append(record("training_student","유소강","연무장 대련 수락 후"))
	game.herbalist_quest.phase="ready";game.herbalist_quest.refresh_world();rows.append(record("herb_gatherer","임소평","구조 후 약재상 옆 · 보고 전"))
	game.impostor_quest.phase="confront";game.impostor_quest.refresh_world();rows.append(record("impostor_ma","마응칠","무림맹 사칭 사건 조사 후"))
	game.grain_quest.phase="receipt";game.grain_quest.refresh_world();rows.append(record("grain_yang_samro","양삼로","세곡 의뢰 수락~독촉 철회 전"))
	# Song's two event positions are recorded separately, never as permanent copies.
	game.alliance_story.stage_id="invited";game.alliance_story.playing=true;game.alliance_story.vouching=true;game.alliance_story.refresh_world()
	rows.append(record("song_jigyeom","송지겸 · 정문 보증","초대 후 정문 신원 확인 장면"))
	game.alliance_story.reset();game.impostor_quest.phase="thanks";game.impostor_quest.refresh_world()
	rows.append(record("song_jigyeom","송지겸 · 감사 방문","사칭 사건 보수 수령 직후"))
	game.grain_quest.phase="confront";game.grain_quest.hearing_active=true;game.grain_quest.refresh_world()
	rows.append(record("wc_lu_zhenghao","육정호 · 농촌 출장","세곡 대면 대화 중만 · 뒤 관아 복귀"))
	# Render the same static city layers while pins describe conditional event snapshots.
	await save_sheet("wuchang",rows,"무창 상시13명 + 총무당 실내1명 · 테두리 번호는 사건별 위치이며 동시에 등장한다는 뜻이 아닙니다")
	var output=FileAccess.open("res://../docs/cities/npc-locations.json",FileAccess.WRITE)
	if output==null:output=FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../docs/cities/npc-locations.json"),FileAccess.WRITE)
	assert(output!=null);output.store_string(JSON.stringify(exported,"  "));output.close()
	game.reset();await create_timer(.4).timeout
	for voice in game.music.players:voice.stop();voice.stream=null
	for voice in game.options.voices:voice.stop();voice.stream=null
	game.queue_free();await process_frame;print("NPC_MAPS: PASS");quit()
