class_name TrainerController
extends RefCounted
## Base interface both AI and (later) chat-driven controllers implement.
## The battle loop doesn't know or care which kind it's talking to.

func choose_action(_actor: BattleCombatant, _opponent: BattleCombatant) -> Dictionary:
	return {"type": "move", "move_index": 0}
