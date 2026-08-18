extends Node
## Ephemeral handoff data from overworld -> Battle scene (change_scene_to_file
## can't pass constructor args directly, so this is the standard Godot pattern for it).

var pending_wild_species: Species = null
var pending_wild_level: int = 5
var pending_trainer: Trainer = null

func begin_wild_encounter(species: Species, level: int) -> void:
	pending_wild_species = species
	pending_wild_level = level
	pending_trainer = null
	get_tree().change_scene_to_file("res://scenes/Battle/Battle.tscn")

func begin_trainer_battle(trainer: Trainer) -> void:
	pending_trainer = trainer
	pending_wild_species = null
	get_tree().change_scene_to_file("res://scenes/Battle/Battle.tscn")
