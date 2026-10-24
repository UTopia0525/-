extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	# Ground is the same authored asset in standalone views and actual gameplay.
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.start_wuchang()
	for spec in [["wuchang","wuchang_map.gd","wuchang"],["mountain_road","mountain_road_map.gd","changsha-wuchang"],["alliance_office","alliance_office_map.gd","alliance-office"]]:
		game.exploration.load_area(spec[0]);var w=game.exploration
		assert(w.background.texture.resource_path=="res://assets/maps/"+spec[2]+"/ground.png")
		assert(w.can_stand(w.player.position));assert(not w.travel_exits.is_empty())
		for exit in w.travel_exits:assert(w.can_stand(exit.position))
		for node in w.scenery_nodes:
			if not w.regional_map.prefabs[node.definition.prefab].has("content_rect"):continue
			var expected=Rect2((node.position+node.sprite.position)/w.regional_map.world_scale,node.sprite.texture.get_size()*node.sprite.scale/w.regional_map.world_scale)
			assert(w.art_tiles.any(func(t):return t.target.is_equal_approx(expected)))
		game.minimap.refresh()
		assert(game.minimap.world_window.has_point(w.player.position))
		game.toggle_city_map();assert(game.city_overview.map_image.texture==w.background.texture);game.toggle_city_map()
		assert(w.regional_map.get_child(0).get_script().resource_path=="res://scripts/"+({"wuchang":"wuchang_ground.gd","mountain_road":"mountain_road_ground.gd","alliance_office":"alliance_office_ground.gd"}[spec[0]]))
	print("MAP ART PASS: authored source, gameplay/overview/minimap, clear portal locations")
	game.free();quit()
