extends Control
## Stable participant slots; identity is independent of the reusable portrait.
const UI = preload("res://scripts/ui.gd")
const EXTRA_ROOT = "res://assets/portraits/extras/"
static var ACTORS = {
	"song_jigyeom":{"name":"송지겸","extra":"male_young","portrait":"res://assets/portraits/alliance/song-jigyeom.png"},
	"bandit_officer": {"name":"정 포두", "extra":"male_middle"},
	"bandit_messenger": {"name":"포졸", "extra":"male_young", "portrait":"res://assets/portraits/story/constable-duty.png"},
	"bandit_farmer": {"name":"피해 농민", "extra":"male_elder"},
	"bandit_raider": {"name":"길목 산적", "extra":"male_middle", "portrait":"res://assets/portraits/archetypes/bandit.png"},
	"bandit_leader": {"name":"산적 우두머리", "extra":"male_middle", "portrait":"res://assets/portraits/archetypes/bandit-sentry.png"},
	"cloth_merchant": {"name": "포목상", "extra": "female_middle"},
	"pirate": {"name": "흑린채 수적", "extra": "male_middle", "portrait":"res://assets/portraits/archetypes/water-bandit.png"},
	"recipient": {"name": "수령인", "extra": "male_common_b"},
	"city_merchant": {"name": "장사꾼", "extra": "male_young", "portrait": "res://assets/portraits/services/merchant.png"},
	"city_artisan": {"name": "장인", "extra": "female_middle", "portrait": "res://assets/portraits/services/artisan.png"},
	"city_instructor": {"name": "교관", "extra": "male_middle", "portrait": "res://assets/portraits/services/instructor.png"},
	"hero": {"name": "도원", "extra": "male_young", "portrait": "res://assets/portraits/player/hero.png"},
	"captain": {"name": "서문길", "extra": "male_middle"},
	"apothecary": {"name": "진소옥", "extra": "female_young"},
	"sailor": {"name": "허만복", "extra": "male_common_a"},
	"clerk": {"name": "육승", "extra": "male_young"},
}
const FRAME_SHADER = preload("res://shaders/dialogue_portrait.gdshader")
var framing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/portrait_framing.json"))
const DIM = Color(0.48, 0.50, 0.49, 1.0)
var portraits: Dictionary = {}
var actor_names: Dictionary = {}
var active_actor: String = ""
var source_facing: Dictionary = {}
var portrait_choices: Dictionary = {}
var basic_portraits: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/basic_npc_portraits.json")).entries
var COMMON_POOL={"male":[],"female":[]}

func _init() -> void:
	for id in basic_portraits:COMMON_POOL[basic_portraits[id].gender].append(id)
	var civil=JSON.parse_string(FileAccess.get_file_as_string("res://data/wuchang_residents.json"))
	for entry in civil.npcs:
		ACTORS[entry.id]={"name":entry.name,"basic_portrait":entry.basic_portrait} if entry.has("basic_portrait") else {"name":entry.name,"extra":entry.extra,"portrait":"res://assets/portraits/wuchang/"+str(entry.id).trim_prefix("wc_")+".png"}
	for entry in JSON.parse_string(FileAccess.get_file_as_string("res://data/suzhou_residents.json")).npcs:
		ACTORS[entry.id]={"name":entry.name,"basic_portrait":entry.basic_portrait}
	for entry in JSON.parse_string(FileAccess.get_file_as_string("res://data/murong_estate_residents.json")).npcs:
		ACTORS[entry.id]={"name":entry.name,"basic_portrait":entry.basic_portrait} if entry.has("basic_portrait") else {"name":entry.name,"portrait":"res://assets/portraits/murong/"+{"mr_patriarch":"gyeongwon","mr_heir":"yuan","mr_guard":"guard","mr_guard_east":"guard"}[entry.id]+".png"}
	for entry in JSON.parse_string(FileAccess.get_file_as_string("res://data/hangzhou_residents.json")).npcs:
		ACTORS[entry.id]={"name":entry.name,"basic_portrait":entry.basic_portrait}
	var qingya=JSON.parse_string(FileAccess.get_file_as_string("res://data/qingya_characters.json"))
	for entry in qingya.npcs:
		var actor={"name":entry.name}
		for key in ["basic_portrait","extra","portrait"]:
			if entry.has(key):actor[key]=entry[key]
		ACTORS[entry.id]=actor
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(0, 143)
	size = Vector2(1280, 372)

func texture_for(actor: Dictionary) -> Texture2D:
	if actor.get("portrait_unavailable", false): return null
	# A dedicated illustration overrides the common age/sex portrait.
	var dedicated: String = actor.get("portrait", "")
	if not dedicated.is_empty() and ResourceLoader.exists(dedicated):
		return load(dedicated)
	var id=str(actor.get("basic_portrait",actor.get("extra","male_young")))
	var path: String=basic_portraits.get(id,{}).get("path",EXTRA_ROOT+id+".png")
	if ResourceLoader.exists(path):
		return load(path)
	push_error("Missing dialogue portrait: " + path)
	return null

func frame_for(texture: Texture2D, display_size: Vector2) -> Rect2:
	var reference: Dictionary = framing.reference
	var source_size := texture.get_size()
	var profile: Dictionary = framing.profiles.get(texture.resource_path, {"face_x":source_size.x / 2.0, "eye_y":source_size.y * float(reference.eye_y) / float(reference.height), "eye_to_chin":float(reference.eye_to_chin) * source_size.y / float(reference.height)})
	var target_eye := display_size.y * float(reference.eye_y) / float(reference.height)
	var scale_factor := display_size.y / float(reference.height) * float(reference.eye_to_chin) / float(profile.eye_to_chin)
	# Keep the lower crop filled even for a source that ends high on the torso.
	scale_factor = maxf(scale_factor, (display_size.y - target_eye) / (source_size.y - float(profile.eye_y)))
	var window := display_size / scale_factor
	var origin := Vector2(float(profile.face_x) - window.x / 2.0, float(profile.eye_y) - target_eye / scale_factor)
	return Rect2(origin, window)

func apply_framing(view: TextureRect, actor: Dictionary) -> void:
	view.texture = texture_for(actor)
	if not view.texture: return
	var frame := frame_for(view.texture, view.size)
	var shader = ShaderMaterial.new()
	shader.shader = FRAME_SHADER
	shader.set_shader_parameter("frame_origin", frame.position)
	shader.set_shader_parameter("frame_size", frame.size)
	shader.set_shader_parameter("source_size", view.texture.get_size())
	view.material = shader
	view.stretch_mode = TextureRect.STRETCH_SCALE

func valid_staging(value) -> bool:
	if not value is Dictionary: return false
	for key in value:
		if key not in ["to", "facing"]: return false
	if value.has("to") and (not value.to is String or not ACTORS.has(value.to)): return false
	if value.has("facing"):
		if not value.facing is Dictionary: return false
		for id in value.facing:
			if not ACTORS.has(id) or value.facing[id] not in ["left", "right"]: return false
	return true

func allocate_portraits(participants: Array) -> Array:
	var result: Array = []
	var used := {}
	var pending: Array[int] = []
	for actor in participants:
		var resolved: Dictionary = actor.duplicate(true)
		var texture := texture_for(actor)
		var path: String = texture.resource_path if texture else ""
		if not path.is_empty() and not used.has(path):
			resolved.portrait = path
			used[path] = true
		else:
			pending.append(result.size())
		result.append(resolved)
	for index in pending:
		var actor: Dictionary = result[index]
		var requested=str(actor.get("basic_portrait",actor.get("extra","male_middle")))
		var gender: String=basic_portraits.get(requested,{}).get("gender","female" if str(actor.get("extra","male_middle")).begins_with("female") else "male")
		var chosen := ""
		for variant in COMMON_POOL[gender]:
			var path: String = basic_portraits[variant].path
			if not used.has(path) and ResourceLoader.exists(path):
				chosen = path
				used[path] = true
				break
		# Never silently give two speakers the same face or generate unrequested artwork.
		if chosen.is_empty():
			push_error("More unique NPC portraits required for this conversation")
			actor.portrait_unavailable = true
		actor.portrait = chosen
	return result

func set_participants(participants: Array) -> void:
	clear()
	participants = allocate_portraits(participants)
	# Stable sides are assigned by identity, never by the current speaker.
	var has_hero=participants.any(func(actor):return actor.id=="hero")
	var others=participants.filter(func(actor):return actor.id!="hero") if has_hero else participants
	var opponent_index=0
	var rows=maxi(1,ceili(others.size()/6.0))
	var height=size.y/rows
	for actor in participants:
		var id: String=actor.id
		if portraits.has(id):continue
		var x=61.0;var width=310.0;var y=0.0
		if id!="hero" or not has_hero:
			var count=mini(6,others.size()-(opponent_index/6)*6)
			var column=opponent_index%6
			y=(opponent_index/6)*height
			if has_hero:
				width=320.0 if count==1 else 285.0 if count==2 else 260.0 if count==3 else 800.0/count
				x=870.0 if count==1 else 681.0+column*242 if count==2 else 526.0+column*218 if count==3 else 430.0+column*width
			else:
				width=minf(340.0,1180.0/count);x=(size.x-width*count)/2.0+column*width
			opponent_index+=1
		var portrait=TextureRect.new();portrait.name=id
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(portrait);portrait.position=Vector2(x,y);portrait.size=Vector2(width,height)
		portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		apply_framing(portrait,actor)
		portrait_choices[id]=portrait.texture.resource_path if portrait.texture else ""
		source_facing[id]=framing.profiles.get(portrait_choices[id],{}).get("natural_facing","right")
		portraits[id]=portrait
		var label=UI.label(self,actor.get("name",id),Rect2(x,y+height-32,width,31),18,Color("ead8ad"))
		label.add_theme_color_override("font_outline_color",Color("13221d"));label.add_theme_constant_override("outline_size",4);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.z_index=2
		actor_names[id]=label
	show()
	set_speaker("")

func set_speaker(id: String, staging: Dictionary = {}) -> void:
	active_actor = id
	var addressed: String = str(staging.get("to", ""))
	if not portraits.has(addressed) or addressed == id:
		addressed = "hero" if id != "hero" and portraits.has("hero") else ""
		if addressed.is_empty():
			var nearest := INF
			for other in portraits:
				if other == id or not portraits.has(id): continue
				var distance: float = portraits[id].position.distance_squared_to(portraits[other].position)
				if distance < nearest:
					nearest = distance
					addressed = other
	for actor_id in portraits:
		var view: TextureRect = portraits[actor_id]
		view.self_modulate = Color.WHITE if actor_id == id else DIM
		view.z_index=1 if actor_id==id else 0
		actor_names[actor_id].self_modulate = Color.WHITE if actor_id == id else Color(0.65, 0.65, 0.65)
		var target: String = addressed if actor_id == id else "hero" if portraits.has("hero") and actor_id!="hero" else id
		var desired: String = str(source_facing[actor_id])
		if portraits.has(target) and target != actor_id:
			var from_x: float = view.position.x + view.size.x / 2.0
			var to_view: TextureRect = portraits[target]
			var to_x: float = to_view.position.x + to_view.size.x / 2.0
			if not is_equal_approx(from_x, to_x): desired = "right" if to_x > from_x else "left"
		elif id.is_empty() and portraits.size() > 1:
			desired = "right" if view.position.x + view.size.x / 2.0 < size.x / 2.0 else "left"
		var overrides: Dictionary = staging.get("facing", {})
		if overrides.has(actor_id): desired = str(overrides[actor_id])
		view.flip_h = desired != source_facing[actor_id]

func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	portraits.clear()
	actor_names.clear()
	source_facing.clear()
	portrait_choices.clear()
	active_actor = ""
	hide()
