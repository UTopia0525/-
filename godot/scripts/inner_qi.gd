extends RefCounted
const STAT_MAX = preload("res://scripts/rules.gd").STAT_MAX
## Battle resource governed by the inner-power stat; distinct from the stat itself.
signal changed
const MAXIMUM := 500
var inner_power := 0
var amount := 0

func start(value: int) -> void:
	inner_power = clampi(value, 0, STAT_MAX)
	amount = inner_power
	changed.emit()

func recover_turn() -> void:
	recover(inner_power)

func recover(value: int) -> int:
	var before:=amount
	amount=mini(MAXIMUM,amount+maxi(0,value))
	changed.emit()
	return amount-before

func can_spend(cost: int) -> bool:
	return cost >= 0 and cost <= amount

func spend(cost: int) -> bool:
	if not can_spend(cost): return false
	amount -= cost
	changed.emit()
	return true

func restore(value: int, remaining: int) -> void:
	inner_power = clampi(value, 0, STAT_MAX)
	amount = clampi(remaining, 0, MAXIMUM)
	changed.emit()
