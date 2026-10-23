extends RefCounted
## Battle resource governed by the inner-power stat; distinct from the stat itself.
signal changed
const MAXIMUM := 500
var inner_power := 0
var amount := 0

func start(value: int) -> void:
	inner_power = clampi(value, 0, 100)
	amount = inner_power
	changed.emit()

func recover_turn() -> void:
	amount = mini(MAXIMUM, amount + inner_power)
	changed.emit()

func can_spend(cost: int) -> bool:
	return cost >= 0 and cost <= amount

func spend(cost: int) -> bool:
	if not can_spend(cost): return false
	amount -= cost
	changed.emit()
	return true

func restore(value: int, remaining: int) -> void:
	inner_power = clampi(value, 0, 100)
	amount = clampi(remaining, 0, MAXIMUM)
	changed.emit()
