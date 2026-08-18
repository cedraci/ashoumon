class_name Trainer
extends Resource
## Parallel arrays keep this simple: each creature gets [Tackle, its type's starter
## move], same as wild encounters (see BattleState._starter_move_for). A future
## milestone can give trainers custom movesets if the content actually needs it.

@export var id: String
@export var display_name: String
@export var species_ids: Array[String] = []
@export var levels: Array[int] = []
@export var intro_line: String = "Let's battle!"
@export var defeat_line: String = "I lost..."
## "AI_DEFAULT" or "EXTERNAL_CHAT" - see ExternalChatController. Emulator-only in
## spirit even here: nothing about this depends on real hardware, but the whole
## point is a PC-side WebSocket connection, so this trainer type has no meaning
## outside a build that's actually running with a live Twitch connection.
@export var controller_type: String = "AI_DEFAULT"
