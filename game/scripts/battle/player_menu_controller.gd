class_name PlayerMenuController
extends TrainerController
## Drives the player's side via the battle's on-screen menu instead of AI.

var battle_state: Node

func _init(p_battle_state: Node) -> void:
	battle_state = p_battle_state

func choose_action(actor: BattleCombatant, _opponent: BattleCombatant) -> Dictionary:
	if actor.moves.is_empty():
		return {"type": "no_move"}
	var options: Array = ["Fight"]
	if not battle_state.is_trainer_battle:
		options.append("Catch")
	options.append("Run")

	var move_names: Array = []
	for m in actor.moves:
		move_names.append("%s [%s]" % [m.display_name, m.damage_class.capitalize()])

	# show_menu() returns -1 when the player backs out with ui_cancel. Never use that
	# as an index (GDScript would silently read the LAST entry) - instead behave like
	# the classic games: cancelling the move list steps back to the top menu, and
	# cancelling the top menu just re-opens it, since a turn must always be taken.
	var action: Dictionary = {}
	while action.is_empty():
		var top_choice: int = await battle_state.show_menu(options)
		if top_choice < 0:
			continue
		var choice_label: String = options[top_choice]
		if choice_label == "Catch":
			var ball_ids: Array = GameState.get_available_ball_ids()
			if ball_ids.is_empty():
				action = {"type": "catch", "ball_id": ""}
			else:
				var ball_options: Array = []
				for ball_id in ball_ids:
					ball_options.append("%s x%d" % [CatchMechanic.get_ball_display_name(ball_id), GameState.bag[ball_id]])
				var ball_choice: int = await battle_state.show_menu(ball_options)
				if ball_choice >= 0:
					action = {"type": "catch", "ball_id": ball_ids[ball_choice]}
		elif choice_label == "Run":
			action = {"type": "run"}
		else:
			var move_choice: int = await battle_state.show_menu(move_names)
			if move_choice >= 0:
				action = {"type": "move", "move_index": move_choice}
	return action
