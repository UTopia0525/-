extends RefCounted

# Approved baseline.
const STAT_MAX = 200
const STARTING_STATS = {"strength": 10, "agility": 10, "constitution": 10, "inner": 10, "insight": 10}
const PLAYER_MAX_HP = 300
const ENEMY_MAX_HP = 150
const ENEMY_CONSTITUTION = 5

# Provisional demo rules, not canon: enemy attack, rounding, turn order and timing.
const DEMO_ENEMY_RAW_DAMAGE = 40
const DEMO_ATTACK_DELAY = 0.45
const DEMO_TURN_DELAY = 0.65

static func max_health(stats: Dictionary = STARTING_STATS) -> int:
	return 220 + 3 * int(stats.get("strength", 10)) + 5 * int(stats.get("constitution", 10))

static func damage(raw: float, constitution: float) -> int:
	return floori(damage_before_rounding(raw, constitution))

static func damage_before_rounding(raw: float, constitution: float) -> float:
	return maxf(0.0, raw - constitution) * 100.0 / (100.0 + constitution)

static func basic_attack_damage(stats: Dictionary = STARTING_STATS) -> float:
	return float(stats.strength + stats.inner)

static func samjae_damage() -> float:
	return STARTING_STATS.strength * 3.0 + STARTING_STATS.agility * 2.0

# Realm labels are independent from existing quest minimum-total gates.
static func realm(total: int) -> String:
	if total <= 100:
		return "삼류"
	if total <= 200:
		return "이류"
	if total <= 300:
		return "일류"
	if total <= 400:
		return "절정"
	if total <= 500:
		return "초절정"
	if total <= 600:
		return "화경"
	if total <= 700:
		return "현경"
	return "자연경"
