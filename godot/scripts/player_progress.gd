extends RefCounted
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
var error := ""

func _init() -> void: reset()

func reset() -> void:
	stats = RULES.STARTING_STATS.duplicate()
	owned_weapons = ["plain_iron_sword"]
	learned = ["samjae"]
	loadout = ["samjae", "", ""]
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
			if not elixirs.has(id): return "판매하지 않는 영약입니다."
			if int(consumed[id]) + int(inventory[id]) >= int(elixirs[id].max_lifetime_uses): return "복용량과 보유량이 이 영약의 한도10개에 도달했습니다."
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
	return true

func consume(id: String) -> bool:
	if not elixirs.has(id) or int(inventory.get(id, 0)) <= 0:
		error = "보유한 영약이 없습니다."
		return false
	if int(consumed[id]) >= int(elixirs[id].max_lifetime_uses):
		error = "이 영약은 이미10개 복용했습니다."
		return false
	var changed := false
	for key in elixirs[id].permanent_stat_gains:
		if key != "insight" and int(elixirs[id].permanent_stat_gains[key]) > 0 and int(stats[key]) < 100: changed = true
	if not changed:
		error = "상승할 능력치가 없어 복용하지 않았습니다."
		return false
	for key in elixirs[id].permanent_stat_gains:
		if key != "insight": stats[key] = mini(100, int(stats[key]) + int(elixirs[id].permanent_stat_gains[key]))
	inventory[id] -= 1
	consumed[id] += 1
	error = ""
	return true

func assign(id: String, slot: int) -> bool:
	if slot < 0 or slot >= 3 or (id != "" and id not in learned): return false
	# Moving an assigned technique leaves its old slot empty, preserving three distinct slots.
	for index in range(3):
		if loadout[index] == id: loadout[index] = ""
	loadout[slot] = id
	return true

func snapshot() -> Dictionary:
	return {"stats":stats.duplicate(), "weapons":owned_weapons.duplicate(), "learned":learned.duplicate(), "loadout":loadout.duplicate(), "inventory":inventory.duplicate(), "consumed":consumed.duplicate()}

func valid(data) -> bool:
	if not data is Dictionary: return false
	for key in ["stats", "inventory", "consumed"]:
		if not data.get(key) is Dictionary: return false
	for key in ["weapons", "learned", "loadout"]:
		if not data.get(key) is Array: return false
	if data.stats.size() != 5 or data.inventory.size() != elixirs.size() or data.consumed.size() != elixirs.size(): return false
	for key in RULES.STARTING_STATS:
		if not whole(data.stats.get(key), 0, 100): return false
	for id in elixirs:
		if not whole(data.inventory.get(id), 0, 10) or not whole(data.consumed.get(id), 0, 10): return false
		if data.inventory[id] + data.consumed[id] > elixirs[id].max_lifetime_uses: return false
	if "plain_iron_sword" not in data.weapons or "samjae" not in data.learned or data.loadout.size() != 3: return false
	for id in data.weapons:
		if not id is String or not weapons.definitions.has(id) or data.weapons.count(id) != 1: return false
	for id in data.learned:
		if not id is String or not arts.definitions.has(id) or data.learned.count(id) != 1: return false
	for id in data.loadout:
		if not id is String or (id != "" and (id not in data.learned or data.loadout.count(id) != 1)): return false
	return true

func whole(value, minimum: int, maximum: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(value) and value == floor(value) and value >= minimum and value <= maximum

func restore(data: Dictionary) -> void:
	stats = data.stats.duplicate()
	owned_weapons = data.weapons.duplicate()
	learned = data.learned.duplicate()
	loadout = data.loadout.duplicate()
	inventory = data.inventory.duplicate()
	consumed = data.consumed.duplicate()
