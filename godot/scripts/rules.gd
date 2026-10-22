extends RefCounted

# Approved baseline.
const STARTING_STATS = {"strength": 10, "agility": 10, "constitution": 10, "inner": 10, "insight": 10}
const PLAYER_MAX_HP = 300
const ENEMY_MAX_HP = 150
const ENEMY_CONSTITUTION = 5

# Provisional demo rules, not canon: enemy attack, rounding, turn order and timing.
const DEMO_ENEMY_RAW_DAMAGE = 40
const DEMO_ATTACK_DELAY = 0.45
const DEMO_TURN_DELAY = 0.65

static func damage(raw: float, constitution: float) -> int:
	return floori(maxf(0.0, raw - constitution) * 100.0 / (100.0 + constitution))

static func samjae_damage() -> float:
	return STARTING_STATS.strength * 3.0 + STARTING_STATS.agility * 2.0

static func realm(total: int) -> String:
	if total == 500:
		return "자연경"
	if total >= 400:
		return "현경"
	if total >= 300:
		return "화경"
	if total >= 200:
		return "초절정"
	if total >= 100:
		return "절정"
	return "명칭 미정"
