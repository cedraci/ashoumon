class_name OverworldDoor
extends StaticBody2D

@export_file("*.tscn") var destination_scene: String = ""
@export var destination_position := Vector2.ZERO

func _ready() -> void:
	add_to_group("interactable")

func setup(_text_box, _menu_list, _player) -> void:
	pass

func interact() -> void:
	var current_scene := get_tree().current_scene.scene_file_path
	if destination_scene.is_empty():
		if GameState.return_scene_path.is_empty():
			return
		GameState.pending_scene_position = GameState.return_position
		GameState.pending_scene_position_valid = true
		get_tree().change_scene_to_file(GameState.return_scene_path)
		return
	GameState.return_scene_path = current_scene
	GameState.return_position = global_position + Vector2(0, 24)
	GameState.pending_scene_position = destination_position
	GameState.pending_scene_position_valid = true
	get_tree().change_scene_to_file(destination_scene)