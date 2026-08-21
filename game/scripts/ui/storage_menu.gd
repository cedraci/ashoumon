extends Control

signal closed

const MAIN_ITEMS := ["View stored Pokemon", "Withdraw Pokemon", "Deposit Pokemon", "Exit"]

@onready var title_label: Label = $Panel/Title
@onready var body_label: Label = $Panel/Body
@onready var hint_label: Label = $Panel/Hint

var _active := false
var _mode := "main"
var _selected := 0
var _list_kind := ""

func _ready() -> void:
	visible = false

func open() -> void:
	_active = true
	_mode = "main"
	_selected = 0
	_render_main()
	visible = true

func close() -> void:
	_active = false
	visible = false
	closed.emit()

func _render_main() -> void:
	title_label.text = "CENTER COMPUTER"
	body_label.text = _menu_text(MAIN_ITEMS, _selected)
	hint_label.text = "Up/Down: Select   Enter: Confirm   Esc: Exit"

func _menu_text(items: Array, selected: int) -> String:
	var lines := []
	for index in range(items.size()):
		lines.append(("> " if index == selected else "  ") + items[index])
	return "\n".join(lines)

func _show_list(kind: String) -> void:
	_list_kind = kind
	_mode = "list"
	_selected = 0
	var members: Array = GameState.stored_pokemon if kind == "withdraw" else GameState.party
	if members.is_empty():
		body_label.text = "No Pokemon available."
	else:
		var lines := []
		for index in range(members.size()):
			var member: BattleCombatant = members[index]
			var status := "FAINTED" if member.is_fainted() else "HP %d/%d" % [member.current_hp, member.max_hp]
			lines.append(("> " if index == 0 else "  ") + "%d  %s  Lv %d  %s" % [index + 1, member.get_display_name(), member.level, status])
		body_label.text = "\n".join(lines)
	title_label.text = "WITHDRAW" if kind == "withdraw" else "DEPOSIT"
	hint_label.text = "Up/Down: Select   Enter: Confirm   Esc: Back"

func _show_stored() -> void:
	_mode = "view"
	title_label.text = "STORED POKEMON"
	if GameState.stored_pokemon.is_empty():
		body_label.text = "The Center Computer is empty."
	else:
		var lines := []
		for index in range(GameState.stored_pokemon.size()):
			var member: BattleCombatant = GameState.stored_pokemon[index]
			lines.append("%d  %s  Lv %d" % [index + 1, member.get_display_name(), member.level])
		body_label.text = "\n".join(lines)
	hint_label.text = "Esc/Enter: Back"

func _show_message(message: String) -> void:
	_mode = "message"
	body_label.text = message
	hint_label.text = "Esc/Enter: Back"

func _selected_members() -> Array:
	return GameState.stored_pokemon if _list_kind == "withdraw" else GameState.party

func _confirm_list_selection() -> void:
	var members := _selected_members()
	if members.is_empty():
		_show_message("No Pokemon available.")
		return
	var member: BattleCombatant = members[_selected]
	if _list_kind == "withdraw":
		if GameState.party.size() >= GameState.PARTY_LIMIT:
			_show_message("Your party is full.")
			return
		GameState.stored_pokemon.remove_at(_selected)
		GameState.party.append(member)
		_show_message("%s joined your party." % member.get_display_name())
	else:
		if GameState.party.size() <= 1:
			_show_message("You must keep at least one Pokemon in your party.")
			return
		GameState.party.remove_at(_selected)
		GameState.stored_pokemon.append(member)
		_show_message("%s was deposited." % member.get_display_name())

func _render_list_selection() -> void:
	var members := _selected_members()
	var lines := []
	for index in range(members.size()):
		var member: BattleCombatant = members[index]
		var status := "FAINTED" if member.is_fainted() else "HP %d/%d" % [member.current_hp, member.max_hp]
		lines.append(("> " if index == _selected else "  ") + "%d  %s  Lv %d  %s" % [index + 1, member.get_display_name(), member.level, status])
	body_label.text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _mode == "main":
		if event.is_action_pressed("ui_down"):
			_selected = (_selected + 1) % MAIN_ITEMS.size()
			_render_main()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_selected = (_selected - 1 + MAIN_ITEMS.size()) % MAIN_ITEMS.size()
			_render_main()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			match _selected:
				0:
					_show_stored()
				1:
					_show_list("withdraw")
				2:
					_show_list("deposit")
				3:
					close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			close()
			get_viewport().set_input_as_handled()
	elif _mode == "list":
		var members := _selected_members()
		if event.is_action_pressed("ui_down") and not members.is_empty():
			_selected = (_selected + 1) % members.size()
			_render_list_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up") and not members.is_empty():
			_selected = (_selected - 1 + members.size()) % members.size()
			_render_list_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_confirm_list_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			_mode = "main"
			_selected = 0
			_render_main()
			get_viewport().set_input_as_handled()
	else:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_mode = "main"
			_selected = 0
			_render_main()
			get_viewport().set_input_as_handled()
