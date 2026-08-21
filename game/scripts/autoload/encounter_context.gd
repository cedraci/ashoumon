extends Node
## Ephemeral handoff data from overworld -> Battle scene (change_scene_to_file
## can't pass constructor args directly, so this is the standard Godot pattern for it).

var pending_wild_species: Species = null
var pending_wild_level: int = 5
var pending_trainer: Trainer = null
var return_scene_path := ""
var return_position := Vector2.ZERO

func begin_wild_encounter(species: Species, level: int) -> void:
	pending_wild_species = species
	pending_wild_level = level
	pending_trainer = null
	_capture_return_location()
	get_tree().change_scene_to_file("res://scenes/Battle/Battle.tscn")

func begin_trainer_battle(trainer: Trainer) -> void:
	pending_trainer = trainer
	pending_wild_species = null
	_capture_return_location()
	get_tree().change_scene_to_file("res://scenes/Battle/Battle.tscn")

func _capture_return_location() -> void:
	var current_scene := get_tree().current_scene
	return_scene_path = current_scene.scene_file_path if current_scene != null else ""
	return_position = GameState.overworld_position
