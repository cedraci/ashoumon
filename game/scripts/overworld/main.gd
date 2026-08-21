extends Node2D
## Overworld root: wires the shared TextBox/MenuList into each NPC (so they can show
## dialogue without reaching for absolute node paths) and provides debug-only
## hotkeys for save/load and forcing a trainer battle.

@onready var text_box := $TextBox
@onready var menu_list := $UILayer/MenuList
@onready var start_menu := $UILayer/StartMenu
@onready var player := $Player

func _ready() -> void:
	player.global_position = GameState.overworld_position
	# NPCs add themselves to "interactable" in their own _ready(), and Godot runs a
	# child's _ready() before its parent's - so by the time this runs, every NPC in
	# the scene is already registered. Wiring them generically means a new NPC just
	# works instead of needing another hardcoded line here.
	for npc in get_tree().get_nodes_in_group("interactable"):
		npc.setup(text_box, menu_list, player)
	start_menu.closed.connect(player.unfreeze)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") \
	and not start_menu.visible \
	and not player.is_frozen() \
	and not text_box.visible \
	and not menu_list.visible:
		start_menu.open()
		player.freeze()
		get_viewport().set_input_as_handled()
		return
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
