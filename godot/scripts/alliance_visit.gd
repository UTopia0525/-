extends Node
## Gate access and visit closure; main-story events live in alliance_story.gd.
const PHASES=["unverified","visiting","training_complete","closed"]
const GATE_ART=Rect2(1405,854,150,50)
var game
var phase="unverified"
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/alliance_characters.json"))
var gate_shape: CollisionShape2D
var gate_bounds=Rect2()
var armed=true
func _ready() -> void:
	for npc in data.npcs:
		var actor={"name":npc.name,"extra":npc.extra}
		if npc.has("portrait"):actor.portrait=npc.portrait
		game.PORTRAITS.ACTORS[npc.id]=actor
func reset() -> void:
	phase="unverified";armed=true
func snapshot() -> Dictionary:return {"phase":phase}
func valid(value) -> bool:return value is Dictionary and value.get("phase") in PHASES
func restore(value: Dictionary) -> void:phase=value.phase;armed=true
func admitted() -> bool:return phase in ["visiting","training_complete"]
# Admission and closure are committed by the main-story dialogue callbacks.
func grant_visit() -> bool:
	if phase!="unverified":return false
	phase="visiting";_refresh_gate();return true
func mark_training_complete() -> bool:
	if phase!="visiting":return false
	phase="training_complete";return true
func install(world) -> void:
	gate_shape=null;armed=true
	if world.area_name!="wuchang":return
	gate_bounds=Rect2(GATE_ART.position*4,GATE_ART.size*4)
	var body=StaticBody2D.new();body.name="AllianceEntryBarrier";body.collision_layer=2;body.collision_mask=1
	gate_shape=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=gate_bounds.size;gate_shape.shape=shape;gate_shape.position=gate_bounds.get_center();body.add_child(gate_shape)
	world.decorations.add_child(body);world.occlusion_roots.append(body)
	_refresh_gate()
func _refresh_gate() -> void:
	var world=game.exploration
	if world.area_name!="wuchang" or not is_instance_valid(gate_shape):return
	world.blockers.erase(gate_bounds);world.regional_map.blockers.erase(gate_bounds)
	if not admitted():world.blockers.append(gate_bounds);world.regional_map.blockers.append(gate_bounds)
	world.regional_map._build_navigation();world.astar=world.regional_map.astar
	# Existing saves inside the compound may always leave; this never opens entry
	# for someone approaching from outside. Keyboard movement uses physical feet.
	gate_shape.set_deferred("disabled",admitted() or _inside_compound(world))
func _inside_compound(world) -> bool:
	return world.area_name=="wuchang" and world.regional_map.rect(world.city_data.alliance_bounds).has_point(world.player.position)
func _process(_delta: float) -> void:
	if not is_instance_valid(game.exploration):return
	var w=game.exploration
	if phase=="training_complete":
		var left=w.area_name not in ["wuchang","alliance_office"]
		if w.area_name=="wuchang":left=not w.regional_map.rect(w.city_data.alliance_bounds).grow(64).has_point(w.player.position)
		if left:phase="closed";armed=true;_refresh_gate()
	if w.area_name!="wuchang" or not is_instance_valid(gate_shape):return
	var allow=admitted() or _inside_compound(w)
	if gate_shape.disabled!=allow:gate_shape.set_deferred("disabled",allow)
	if w.player.position.y>3920:armed=true
	var approach=Rect2(1390*4,904*4,180*4,34*4).has_point(w.player.position)
	if armed and not admitted() and approach and Input.is_action_pressed("move_up") and w.active and game.state=="explore" and game.dialogue_lines.is_empty() and not game.settings_menu.window.visible:
		armed=false;_guard_dialogue("alliance_guard_right" if w.player.position.x>1480*4 else "alliance_guard_left")
func _guard_dialogue(speaker: String="alliance_guard_left") -> void:
	armed=false
	var story=game.get("alliance_story")
	if is_instance_valid(story) and story.stage_id=="invited" and phase=="unverified":
		story.begin_gate(speaker);return
	var scene="guard_closed" if phase=="closed" else "guard_visiting" if admitted() else "guard_after_bandits" if game.bandit_story.stage=="completed" else "guard_unverified"
	var lines: Array=data.scenes[scene].duplicate(true)
	if speaker=="alliance_guard_right":
		for line in lines:
			if line[0]=="alliance_guard_left":line[0]="alliance_guard_right"
			elif line[0]=="alliance_guard_right":line[0]="alliance_guard_left"
	game.say(lines)
func handle_interaction(id: String) -> bool:
	if id in ["alliance_guard_left","alliance_guard_right"]:_guard_dialogue(id);return true
	if id not in ["heo_mungyu","gwak_jinseok"]:return false
	var prefix="heo" if id=="heo_mungyu" else "gwak"
	var story=game.get("alliance_story")
	if id=="gwak_jinseok" and is_instance_valid(story) and story.stage_id=="steward":
		game.say(data.scenes.gwak_idle);return true
	var suffix="trained" if phase=="training_complete" else "visiting" if phase=="visiting" else "idle"
	game.say(data.scenes[prefix+"_"+suffix]);return true
