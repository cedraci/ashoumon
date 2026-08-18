class_name TypeChart
extends RefCounted
## Small original type triangle for the vertical slice: fire > grass > water > fire.

const CHART := {
	"fire": {"fire": 0.5, "water": 0.5, "grass": 2.0},
	"water": {"fire": 2.0, "water": 0.5, "grass": 0.5},
	"grass": {"fire": 0.5, "water": 2.0, "grass": 0.5},
}

static func get_multiplier(attack_type: String, defend_type: String) -> float:
	if CHART.has(attack_type) and CHART[attack_type].has(defend_type):
		return CHART[attack_type][defend_type]
	return 1.0
