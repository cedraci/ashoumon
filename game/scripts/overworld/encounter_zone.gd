class_name EncounterZone
extends Area2D

@export var species_pool: Array[Species] = []
@export var encounter_chance := 0.2
@export var min_level := 3
@export var max_level := 6

var _player: Node = null

@onready var timer: Timer = $Timer

func _ready() -> void:
	if species_pool.is_empty():
		for species in DataRegistry.get_all_species():
			species_pool.append(species as Species)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_player.moved.connect(_on_player_moved)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if _player != null and _player.moved.is_connected(_on_player_moved):
			_player.moved.disconnect(_on_player_moved)
		_player = null
		timer.stop()

func _on_player_moved() -> void:
	if _player != null and timer.is_stopped():
		timer.start()

func _on_timer_timeout() -> void:
	if species_pool.is_empty():
		return
	if randf() < encounter_chance:
		timer.stop()
		var species: Species = species_pool[randi() % species_pool.size()]
		var level := randi_range(min_level, max_level)
		EncounterContext.begin_wild_encounter(species, level)
