extends RefCounted
const STAT_MAX = preload("res://scripts/rules.gd").STAT_MAX
signal progress_changed(event: Dictionary)
## Persistent possessions and growth; shop actions validate before spending money.
const RULES = preload("res://scripts/rules.gd")
var weapons = preload("res://scripts/weapons.gd").new()
var arts = preload("res://scripts/martial_arts.gd").new()
var elixirs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/low_grade_elixirs.json"))
var stats: Dictionary
var owned_weapons: Array
var learned: Array
var loadout: Array
var inventory: Dictionary
var consumed: Dictionary
var manual_definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/martial_manuals.json"))
var manuals: Dictionary = {}
const FACTIONS = {"haomun":"하오문","murim_alliance":"무림맹","namgung":"남궁세가","murong":"모용세가"}
const FAVOR_MAX=100
var faction_favor: Dictionary = {}
var known_factions: Array = []
var fame := 0
var error := ""

func _init() -> void:
	elixirs.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/special_elixirs.json")))
	reset()

func reset() -> void:
	fame = 0
	faction_favor = {"murim_alliance":0}
	known_factions=[]
	stats = RULES.STARTING_STATS.duplicate()
	owned_weapons = ["plain_iron_sword"]
	learned = ["samjae"]
	loadout = ["basic_attack", "basic_defense", "samjae", ""]
	manuals = {}
	inventory = {}
	consumed = {}
	for id in elixirs:
		inventory[id] = 0
		consumed[id] = 0
	error = ""

func issue(kind: String, id: String, money: int) -> String:
	var price := -1
	match kind:
		"weapon":
			if not weapons.definitions.has(id) or weapons.get_weapon(id).get("price") == null: return "판매하지 않는 무기입니다."
			if id in owned_weapons: return "이미 소유한 무기입니다."
			price = int(weapons.get_weapon(id).price)
		"art":
			if not arts.definitions.has(id) or arts.get_skill(id).get("price") == null: return "전수하지 않는 무공입니다."
			if id in learned: return "이미 배운 무공입니다."
			if not arts.can_learn(id, stats): return "학습 조건이 부족합니다. 영약과 의뢰로 능력을 기르세요."
			price = int(arts.get_skill(id).price)
		"elixir":
			if not elixirs.has(id) or elixirs[id].get("price")==null: return "판매하지 않는 영약입니다."
			if int(consumed[id]) + int(inventory[id]) >= elixir_limit(id): return "복용량과 보유량이 이 영약의 한도10개에 도달했습니다."
			price = int(elixirs[id].price)
		_: return "잘못된 거래입니다."
	return "소지금이 부족합니다. 필요 %d문 / 보유 %d문" % [price, money] if money < price else ""

func price_for(kind: String, id: String) -> int:
	match kind:
		"weapon": return int(weapons.get_weapon(id).get("price", 0))
		"art": return int(arts.get_skill(id).get("price", 0))
		"elixir": return int(elixirs.get(id, {}).get("price", 0))
	return 0

func purchase(kind: String, id: String, game) -> bool:
	error = issue(kind, id, game.money)
	if not error.is_empty(): return false
	game.money -= price_for(kind, id)
	match kind:
		"weapon": owned_weapons.append(id)
		"art": learned.append(id)
		"elixir": inventory[id] += 1
	progress_changed.emit({"event":"purchase","kind":kind,"id":id,"price":price_for(kind,id)})
	return true

func consume(id: String) -> bool:
	if not elixirs.has(id) or int(inventory.get(id, 0)) <= 0:
		error = "보유한 영약이 없습니다."
		return false
	if int(consumed[id]) >= elixir_limit(id):
		error = "이 영약은 이미10개 복용했습니다."
		return false
	var changed := false
	for key in elixirs[id].permanent_stat_gains:
		if key != "insight" and int(elixirs[id].permanent_stat_gains[key]) > 0 and int(stats[key]) < STAT_MAX: changed = true
	if not changed:
		error = "상승할 능력치가 없어 복용하지 않았습니다."
		return false
	for key in elixirs[id].permanent_stat_gains:
		if key != "insight": stats[key] = mini(STAT_MAX, int(stats[key]) + int(elixirs[id].permanent_stat_gains[key]))
	inventory[id] -= 1
	consumed[id] += 1
	error = ""
	progress_changed.emit({"event":"consume","id":id})
	return true

func grant_manual(id: String) -> bool:
	if not manual_definitions.has(id):return false
	manuals[id]=int(manuals.get(id,0))+1
	return true

func use_manual(id: String) -> bool:
	if not manual_definitions.has(id) or int(manuals.get(id,0))<=0:
		error="보유한 서책이 없습니다.";return false
	var art: String=manual_definitions[id].teaches
	if art in learned:
		error="이미 익힌 무공이므로 서책을 소모하지 않았습니다.";return false
	if not arts.can_learn(art,stats):
		error="이 무공의 학습 조건을 갖추지 못했습니다.";return false
	learned.append(art);manuals[id]-=1;error=""
	progress_changed.emit({"event":"manual_learn","id":art,"kind":"art"})
	return true

func assign(id: String, slot: int) -> bool:
	if slot < 0 or slot >= 4 or (id != "" and id not in learned and id not in ["basic_attack", "basic_defense"]): return false
	# Moving an assigned technique leaves its old slot empty, preserving four distinct slots.
	for index in range(4):
		if loadout[index] == id: loadout[index] = ""
	loadout[slot] = id
	progress_changed.emit({"event":"loadout","id":id,"slot":slot})
	return true

func favor_for(faction: String) -> int:return int(faction_favor.get(faction,0))

func add_favor(faction: String, amount: int) -> bool:
	if not FACTIONS.has(faction) or not whole(favor_for(faction)+amount,-1000000000,1000000000):return false
	faction_favor[faction]=clampi(favor_for(faction)+amount,0,FAVOR_MAX)
	if favor_for(faction)>0 and faction not in known_factions:known_factions.append(faction)
	progress_changed.emit({"event":"favor","id":faction,"amount":amount})
	return true

func snapshot() -> Dictionary:
	return {"manuals":manuals.duplicate(), "known_factions":known_factions.duplicate(), "faction_favor":faction_favor.duplicate(), "fame":fame, "stats":stats.duplicate(), "weapons":owned_weapons.duplicate(), "learned":learned.duplicate(), "loadout":loadout.duplicate(), "inventory":inventory.duplicate(), "consumed":consumed.duplicate()}

func valid(data) -> bool:
	data=upgrade_elixirs(arts.upgrade_progress(data))
	if not data is Dictionary: return false
	if not data.get("manuals",{}) is Dictionary:return false
	for id in data.get("manuals",{}):
		if not manual_definitions.has(id) or not whole(data.manuals[id],0,1000000):return false
	if data.has("fame") and not whole(data.fame, 0, 1000000000): return false
	if data.has("faction_favor"):
		if not data.faction_favor is Dictionary:return false
		for faction in data.faction_favor:
			if not FACTIONS.has(faction) or not whole(data.faction_favor[faction],-1000000000,1000000000):return false
	if data.has("known_factions"):
		if not data.known_factions is Array:return false
		for faction in data.known_factions:
			if not faction is String or not FACTIONS.has(faction) or data.known_factions.count(faction)!=1:return false
		for faction in data.get("faction_favor",{}):
			if not whole(data.faction_favor[faction],0,FAVOR_MAX):return false
			if data.faction_favor[faction]>0 and faction not in data.known_factions:return false
	for key in ["stats", "inventory", "consumed"]:
		if not data.get(key) is Dictionary: return false
	for key in ["weapons", "learned", "loadout"]:
		if not data.get(key) is Array: return false
	if data.stats.size() != 5 or data.inventory.size() != elixirs.size() or data.consumed.size() != elixirs.size(): return false
	for key in RULES.STARTING_STATS:
		if not whole(data.stats.get(key), 0, STAT_MAX): return false
	for id in elixirs:
		if not whole(data.inventory.get(id), 0, elixir_limit(id)) or not whole(data.consumed.get(id), 0, elixir_limit(id)): return false
		if data.inventory[id] + data.consumed[id] > elixir_limit(id): return false
	if "plain_iron_sword" not in data.weapons or "samjae" not in data.learned or data.loadout.size() not in [3,4]: return false
	for id in data.weapons:
		if not id is String or not weapons.definitions.has(id) or data.weapons.count(id) != 1: return false
	for id in data.learned:
		if not id is String or not arts.definitions.has(id) or data.learned.count(id) != 1: return false
	for id in data.loadout:
		if not id is String or (id != "" and ((id not in data.learned and (data.loadout.size() == 3 or id not in ["basic_attack", "basic_defense"])) or data.loadout.count(id) != 1)): return false
	return true

func elixir_limit(id: String) -> int:return int(elixirs[id].get("max_lifetime_uses",2147483647))

func upgrade_elixirs(data):
	if not data is Dictionary or not data.get("inventory") is Dictionary or not data.get("consumed") is Dictionary:return data
	var upgraded=data.duplicate(true)
	for id in elixirs:
		if id=="namgung_cheongcheon_pill" and not upgraded.inventory.has(id) and not upgraded.consumed.has(id):upgraded.inventory[id]=0;upgraded.consumed[id]=0
	return upgraded

func whole(value, minimum: int, maximum: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(value) and value == floor(value) and value >= minimum and value <= maximum

func restore(data: Dictionary) -> void:
	data=upgrade_elixirs(arts.upgrade_progress(data))
	manuals=data.get("manuals",{}).duplicate()
	fame = int(data.get("fame", 0))
	faction_favor={"murim_alliance":0}
	faction_favor.merge(data.get("faction_favor",{}),true)
	known_factions=data.get("known_factions",[]).duplicate()
	for faction in faction_favor:
		faction_favor[faction]=clampi(int(faction_favor[faction]),0,FAVOR_MAX)
		if faction_favor[faction]>0 and faction not in known_factions:known_factions.append(faction)
	stats = data.stats.duplicate()
	owned_weapons = data.weapons.duplicate()
	learned = data.learned.duplicate()
	loadout = data.loadout.duplicate()
	if loadout.size() == 3: loadout.push_front("basic_attack")
	inventory = data.inventory.duplicate()
	consumed = data.consumed.duplicate()
