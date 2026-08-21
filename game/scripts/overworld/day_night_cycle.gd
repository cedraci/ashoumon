extends CanvasModulate
## Slow palette cycle for Lumenbrook. Starts at midday for predictable testing.

@export var cycle_duration_seconds := 240.0
@export_range(0.0, 1.0) var time_of_day := 0.5

const NIGHT_TINT := Color(0.42, 0.50, 0.72, 1.0)
const DAY_TINT := Color(1.0, 1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	if cycle_duration_seconds <= 0.0:
		color = DAY_TINT
		return
	time_of_day = fmod(time_of_day + delta / cycle_duration_seconds, 1.0)
	var daylight := max(0.0, sin((time_of_day - 0.25) * TAU))
	var brightness := lerpf(0.55, 1.0, daylight)
	color = NIGHT_TINT.lerp(DAY_TINT, brightness)
