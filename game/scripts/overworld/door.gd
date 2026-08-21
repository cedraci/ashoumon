class_name OverworldDoor
extends StaticBody2D

@export_file("*.tscn") var destination_scene: String = ""
@export var destination_position := Vector2.ZERO
@export var transition_on_touch := false

var _transitioning := false
var _pulse_time := 0.0

func _ready() -> void:
	add_to_group("interactable")
	if transition_on_touch:
		collision_layer = 0
		$TransitionArea.body_entered.connect(_on_transition_body_entered)
		queue_redraw()

func _process(delta: float) -> void:
	if transition_on_touch:
		_pulse_time += delta
		queue_redraw()

func _draw() -> void:
	if not transition_on_touch:
		return
	var glow := 0.45 + sin(_pulse_time * 4.0) * 0.15
	draw_rect(Rect2(-8, -8, 16, 16), Color(0.12, 0.55, 0.58, glow), true)
	draw_rect(Rect2(-8, -8, 16, 16), Color(0.55, 1.0, 0.82, 0.95), false, 2.0)
	draw_line(Vector2(-4, 2), Vector2(0, -3), Color(0.9, 1.0, 0.9), 2.0)
	draw_line(Vector2(0, -3), Vector2(4, 2), Color(0.9, 1.0, 0.9), 2.0)

func _on_transition_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not GameState.map_transition_locked:
		_change_scene()

func setup(_text_box, _menu_list, _player) -> void:
	pass

func interact() -> void:
	_change_scene()

func _change_scene() -> void:
	if _transitioning:
		return
	_transitioning = true
	if transition_on_touch:
		GameState.map_transition_locked = true
	var current_scene := get_tree().current_scene.scene_file_path
	if destination_scene.is_empty():
		if GameState.return_scene_path.is_empty():
			return
		GameState.pending_scene_position = GameState.return_position
		GameState.pending_scene_position_valid = true
		call_deferred("_perform_scene_change", GameState.return_scene_path)
		return
	GameState.return_scene_path = current_scene
	GameState.return_position = global_position + Vector2(0, 24)
	GameState.pending_scene_position = destination_position
	GameState.pending_scene_position_valid = true
	call_deferred("_perform_scene_change", destination_scene)

func _perform_scene_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)