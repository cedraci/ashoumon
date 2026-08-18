extends Node2D
## Milestone-2 harness: proves TextBox + MenuList work end-to-end.
## Real NPC interaction will replace this trigger in a later milestone.

@onready var text_box := $TextBox
@onready var menu_list := $UILayer/MenuList

var _busy := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F9:
			get_viewport().set_input_as_handled()
			SaveManager.load_game()
			return
		elif event.keycode == KEY_T:
			get_viewport().set_input_as_handled()
			EncounterContext.begin_trainer_battle(load("res://data/trainers/ranger_vale.tres"))
			return
		elif event.keycode == KEY_C:
			get_viewport().set_input_as_handled()
			EncounterContext.begin_trainer_battle(load("res://data/trainers/chat_challenger.tres"))
			return

	if _busy:
		return
	if event.is_action_pressed("ui_accept"):
		_busy = true
		get_viewport().set_input_as_handled()
		_run_demo()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		var pool := [load("res://data/species/ripplet.tres"), load("res://data/species/leaflet.tres")]
		EncounterContext.begin_wild_encounter(pool[randi() % pool.size()], randi_range(3, 6))

func _run_demo() -> void:
	text_box.say(["Hello there, trainer!", "What will you do?"])
	await text_box.finished
	menu_list.set_items(["Fight", "Bag", "Run"])
	menu_list.open()
	var choice: int = await menu_list.item_selected
	menu_list.close()
	text_box.say(["You chose: %s" % menu_list.get_item_text(choice)])
	await text_box.finished
	_busy = false
