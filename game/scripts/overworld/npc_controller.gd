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
	if npc_type == "nurse":
		_run_nurse_flow()
	else:
		_run_generic_flow()

func _run_generic_flow() -> void:
	_text_box.say(dialogue_lines)
	await _text_box.finished
	_player.unfreeze()

func _run_nurse_flow() -> void:
	_text_box.say(["Welcome to the Pokemon Center!", "Would you like to heal your party?"])
	await _text_box.finished
	_menu_list.set_items(["Yes", "No"])
	_menu_list.open()
	var choice: int = await _menu_list.item_selected
	_menu_list.close()
	if choice == 0:
		GameState.heal_party()
		_text_box.say(["Your party has been healed!"])
	else:
		_text_box.say(["Alright, safe travels!"])
	await _text_box.finished
	_player.unfreeze()
