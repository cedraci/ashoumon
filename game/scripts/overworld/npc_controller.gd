extends StaticBody2D
## Generic overworld NPC: "generic" just shows dialogue_lines; "nurse" runs a
## Yes/No heal confirmation. No dialogue-tree engine, no movement/schedules —
## deliberately just enough for these two cases (see the design spec).

@export var dialogue_lines: Array[String] = []
@export var npc_type: String = "generic"

var _text_box
var _menu_list
var _player

func _ready() -> void:
	add_to_group("interactable")

func setup(text_box, menu_list, player) -> void:
	_text_box = text_box
	_menu_list = menu_list
	_player = player

func interact() -> void:
	if _text_box == null or _menu_list == null or _player == null:
		# setup() was never called - most likely this NPC lives in a scene whose root
		# doesn't wire up the "interactable" group. The player froze themselves just
		# before calling us, so release them rather than leaving them stuck forever.
		push_warning("NPC '%s': interact() called before setup(); releasing the player." % name)
		var stuck_player = _player if _player != null else get_tree().get_first_node_in_group("player")
		if stuck_player != null:
			stuck_player.unfreeze()
		return
	if npc_type == "nurse":
		_run_nurse_flow()
	else:
		_run_generic_flow()

func _run_generic_flow() -> void:
	if dialogue_lines.is_empty():
		# TextBox.say([]) emits `finished` synchronously, before an await below could
		# subscribe to it - which would strand this coroutine and keep the player
		# frozen. With nothing to say, just hand control straight back.
		_player.unfreeze()
		return
	_text_box.say(dialogue_lines)
	await _text_box.finished
	_player.unfreeze()

func _run_nurse_flow() -> void:
	_text_box.say(["Welcome to the Pokemon Center!", "Would you like to heal your party?"])
	await _text_box.finished
	_menu_list.set_items(["Yes", "No"])
	_menu_list.open()
	# -1 here means the player pressed ui_cancel; that falls through to the "No"
	# branch below, which still closes the menu and unfreezes the player.
	var choice: int = await _menu_list.item_selected
	_menu_list.close()
	if choice == 0:
		GameState.heal_party()
		_text_box.say(["Your party has been healed!"])
	else:
		_text_box.say(["Alright, safe travels!"])
	await _text_box.finished
	_player.unfreeze()
