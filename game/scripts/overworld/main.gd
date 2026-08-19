extends Node2D
## Overworld root: wires the shared TextBox/MenuList into each NPC (so they can show
## dialogue without reaching for absolute node paths) and provides debug-only
## hotkeys for save/load and forcing a trainer battle.

@onready var text_box := $TextBox
@onready var menu_list := $UILayer/MenuList
@onready var player := $Player
@onready var nurse_npc := $NurseNPC

func _ready() -> void:
	nurse_npc.setup(text_box, menu_list, player)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F9:
			get_viewport().set_input_as_handled()
			SaveManager.load_game()
		elif event.keycode == KEY_T:
			get_viewport().set_input_as_handled()
			EncounterContext.begin_trainer_battle(load("res://data/trainers/ranger_vale.tres"))
		elif event.keycode == KEY_C:
			get_viewport().set_input_as_handled()
			EncounterContext.begin_trainer_battle(load("res://data/trainers/chat_challenger.tres"))
