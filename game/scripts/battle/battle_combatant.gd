class_name BattleCombatant
extends RefCounted
## Mutable runtime battle state for one creature. Wraps an (immutable, shared) Species
## resource + a level + move loadout; never mutate the Species resource itself.

var species: Species
var level: int
var experience: int = 0
var moves: Array = []  # Array of Move
var nickname: String = ""
var max_hp: int
var current_hp: int
var permanently_fainted := false  # reserved for Nuzlocke mode; unused in the vertical slice

func _init(p_species: Species, p_level: int, p_moves: Array) -> void:
	species = p_species
	level = p_level
	moves = p_moves
	max_hp = _calc_stat(species.base_hp, true)
	current_hp = max_hp

func get_display_name() -> String:
	return nickname if nickname != "" else species.display_name

func _calc_stat(base: int, is_hp: bool) -> int:
	if is_hp:
		return int((2 * base * level) / 100.0) + level + 10
	return int((2 * base * level) / 100.0) + 5

func get_attack() -> int:
	return _calc_stat(species.base_attack, false)

func get_defense() -> int:
	return _calc_stat(species.base_defense, false)

func get_special_attack() -> int:
	return _calc_stat(species.base_special_attack, false)

func get_special_defense() -> int:
	return _calc_stat(species.base_special_defense, false)

func get_speed() -> int:
	return _calc_stat(species.base_speed, false)

func experience_to_next_level() -> int:
	return level * 50

func gain_experience(amount: int) -> int:
	if amount <= 0:
		return 0
	experience += amount
	var levels_gained: int = 0
	while experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		_recalculate_stats()
		levels_gained += 1
	return levels_gained

func _recalculate_stats() -> void:
	var previous_max_hp := max_hp
	max_hp = _calc_stat(species.base_hp, true)
	if not is_fainted():
		current_hp += max_hp - previous_max_hp

func is_fainted() -> bool:
	return current_hp <= 0

func apply_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
