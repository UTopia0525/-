extends SceneTree
var game
var failed=false
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	if not value:failed=true;push_error("MARKET_SLICE: "+message)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.options.seen.append_array(["city","dialogue","trade"]);game.start_wuchang()
	var w=game.exploration
	w.load_area("nanjing");w.set_active(true);await physics_frame
	w.player.position=w.city_point([888,530])
	var shops=[]
	for node in w.scenery_nodes:
		if not str(node.name).begins_with("market_shop_"):continue
		shops.append(node)
		check(is_equal_approx(node.sprite.scale.x,node.sprite.scale.y),"building keeps aspect")
		check(is_zero_approx(node.sprite.rotation),"facade not rotated")
		check(not node.collision_rects.is_empty(),"independent building collision")
		var body=node.collision_rects[0].get_center()
		check(not w.can_stand(body),"cannot walk through shop")
		for actor in w.ambient_nodes:
			for bounds in node.collision_rects:check(not bounds.grow(16).has_point(actor.position),"NPC feet outside building "+str(actor.name))
	check(shops.size()==4,"only four authored market storefronts")
	for p in [[888,315],[888,360],[888,405],[888,490],[888,530],[820,402],[960,402],[820,521],[961,521]]:
		var point=w.city_point(p)
		check(w.can_stand(point),"clear alley/doorstep "+str(p))
		check(not w.path_to(point).is_empty(),"reachable alley/doorstep "+str(p))
	for actor in w.ambient_nodes:check(not w.path_to(actor.position,true).is_empty(),"all residents remain accessible "+str(actor.name))
	# Test actual physics rather than navigation alone on the central north-south lane.
	w.player.position=w.city_point([888,442]);w.player.set_physics_process(false)
	for i in range(90):
		w.player.velocity=Vector2(0,-360);w.player.move_and_slide();await physics_frame
	check(w.player.position.y<w.city_point([888,360]).y,"physical walk crosses market alley")
	w.player.velocity=Vector2.ZERO;w.player.set_physics_process(true)
	var merchant=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")=="nj_merchant")[0]
	var approach=w.path_to(merchant.position,true)
	check(not approach.is_empty(),"merchant F approach after reposition")
	if not approach.is_empty():
		w.player.position=approach[-1];await physics_frame
		check(w.nearest().get("id")=="nj_merchant","merchant can be selected with F")
	game.queue_free();await process_frame
	print("MARKET_SLICE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
