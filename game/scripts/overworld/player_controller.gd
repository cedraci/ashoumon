extends CharacterBody2D

signal moved

const SPEED := 60.0
const TILE_SIZE := 16.0

@onready var interact_zone: Area2D = $InteractZone

var facing := Vector2i(0, 1)
var _frozen := false

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		_update_facing(input_vector)

	if _frozen:
		velocity = Vector2.ZERO
	else:
		velocity = input_vector * SPEED
	move_and_slide()
	if not _frozen and input_vector != Vector2.ZERO:
		moved.emit()
	GameState.overworld_position = global_position

	interact_zone.position = Vector2(facing.x, facing.y) * TILE_SIZE

func _update_facing(input_vector: Vector2) -> void:
	if abs(input_vector.x) > abs(input_vector.y):
		facing = Vector2i(int(sign(input_vector.x)), 0)
	elif abs(input_vector.y) > abs(input_vector.x):
		facing = Vector2i(0, int(sign(input_vector.y)))
	# Exact diagonal tie: keep the previous facing rather than flicker.

func _unhandled_input(event: InputEvent) -> void:
	if _frozen:
		return
	if event.is_action_pressed("ui_accept"):
		for body in interact_zone.get_overlapping_bodies():
			if body.is_in_group("interactable"):
				get_viewport().set_input_as_handled()
				_frozen = true
				body.interact()
				return

func unfreeze() -> void:
	_frozen = false

func freeze() -> void:
	_frozen = true

func is_frozen() -> bool:
	return _frozen
