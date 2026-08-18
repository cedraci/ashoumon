class_name DamageCalc
extends RefCounted
## Simplified Gen3-style damage formula, deliberately not exact - good enough for the slice.

static func compute_damage(attacker: BattleCombatant, defender: BattleCombatant, move: Move) -> int:
	if move.power <= 0:
		return 0
	var atk := attacker.get_attack()
	var df := defender.get_defense()
	var base := ((2.0 * attacker.level / 5.0 + 2.0) * move.power * atk / df) / 50.0 + 2.0
	var stab := 1.5 if move.type_id == attacker.species.type_id else 1.0
	var type_mult := TypeChart.get_multiplier(move.type_id, defender.species.type_id)
	var rand_mult := randf_range(0.85, 1.0)
	var damage := base * stab * type_mult * rand_mult
	return max(1, int(damage))
