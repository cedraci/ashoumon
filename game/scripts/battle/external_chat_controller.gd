class_name ExternalChatController
extends TrainerController
## Same interface as ScriptedAIController - the battle loop never knows or cares
## that this one's decision comes from Twitch chat instead of a rule-based AI.
## Falls back to AI on timeout or if chat isn't connected, so the game is never
## blocked waiting on a stream that isn't running.

const VOTE_DURATION := 10.0

var battle_state: Node
var _fallback := ScriptedAIController.new()

func _init(p_battle_state: Node) -> void:
	battle_state = p_battle_state

func choose_action(actor: BattleCombatant, opponent: BattleCombatant) -> Dictionary:
	var move_names: Array = []
	for m in actor.moves:
		move_names.append(m.display_name)

	battle_state.show_vote_countdown(VOTE_DURATION, move_names)
	var choice: int = await TwitchChatClient.run_vote(actor.moves.size(), VOTE_DURATION)
	battle_state.hide_vote_countdown()

	if choice < 0 or choice >= actor.moves.size():
		return _fallback.choose_action(actor, opponent)
	return {"type": "move", "move_index": choice}
