class_name PlayerMenuController
extends TrainerController
## Drives the player's side via the battle's on-screen menu instead of AI.

var battle_state: Node

func _init(p_battle_state: Node) -> void:
	battle_state = p_battle_state

func choose_action(actor: BattleCombatant, _opponent: BattleCombatant) -> Dictionary:
	var options: Array = ["Fight"]
	if not battle_state.is_trainer_battle:
		options.append("Catch")
	options.append("Run")

	var top_choice: int = await battle_state.show_menu(options)
	var choice_label: String = options[top_choice]
	if choice_label == "Catch":
		return {"type": "catch"}
	if choice_label == "Run":
		return {"type": "run"}

	var move_names: Array = []
	for m in actor.moves:
		move_names.append(m.display_name)
	var move_choice: int = await battle_state.show_menu(move_names)
	return {"type": "move", "move_index": move_choice}
