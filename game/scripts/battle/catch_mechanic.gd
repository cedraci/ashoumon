class_name CatchMechanic
extends RefCounted
## Simplified single-roll version of the Gen3 catch formula - good enough for the slice.

static func attempt_catch(target: BattleCombatant) -> bool:
	var hp_factor: float = (3.0 * target.max_hp - 2.0 * target.current_hp) / (3.0 * target.max_hp)
	var chance: float = clamp(hp_factor * (target.species.catch_rate / 255.0), 0.0, 1.0)
	return randf() < chance
