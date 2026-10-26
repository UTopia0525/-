extends RefCounted
## Future story encounters are lethal unless a documented exception is declared.
const DEATH="death"
const RETRY="retry"
const NONLETHAL="nonlethal"
static func defeat_policy(encounter: Dictionary) -> String:
	# Empty encounter is the existing tutorial/combat-only practice setup.
	if encounter.is_empty():return RETRY
	var policy=str(encounter.get("defeat_outcome",DEATH))
	return policy if policy in [DEATH,RETRY,NONLETHAL] else DEATH
