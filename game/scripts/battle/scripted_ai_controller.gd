class_name ScriptedAIController
extends TrainerController
## Picks whichever move currently deals the most expected damage.

func choose_action(actor: BattleCombatant, opponent: BattleCombatant) -> Dictionary:
	if actor.moves.is_empty():
		return {"type": "no_move"}
	var best_index := 0
	var best_damage := -1
	for i in range(actor.moves.size()):
		var dmg: int = DamageCalc.compute_damage(actor, opponent, actor.moves[i])
		if dmg > best_damage:
			best_damage = dmg
			best_index = i
	return {"type": "move", "move_index": best_index}
