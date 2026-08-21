class_name CatchMechanic
extends RefCounted
## Simplified catch formula with stronger ball multipliers for the vertical slice.

const BALL_MULTIPLIERS := {
	"poke_ball": 1.5,
	"super_ball": 2.0,
	"hyper_ball": 2.5,
}

static func get_ball_display_name(ball_id: String) -> String:
	match ball_id:
		"hyper_ball":
			return "Hyperball"
		"super_ball":
			return "Superball"
		_:
			return "Pokeball"

static func attempt_catch(target: BattleCombatant, ball_id: String) -> bool:
	var hp_factor: float = (3.0 * target.max_hp - 2.0 * target.current_hp) / (3.0 * target.max_hp)
	var ball_multiplier: float = BALL_MULTIPLIERS.get(ball_id, 1.0)
	var chance: float = clamp(hp_factor * (target.species.catch_rate / 255.0) * ball_multiplier * 1.5, 0.0, 1.0)
	return randf() < chance
