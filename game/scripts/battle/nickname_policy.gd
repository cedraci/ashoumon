class_name NicknamePolicy
extends RefCounted
## No-op for the vertical slice. Nuzlocke mode will hook in here to require a
## nickname before a catch is finalized; call site is reserved now to avoid a
## save-format migration later.

static func maybe_prompt(_combatant: BattleCombatant) -> void:
	pass
