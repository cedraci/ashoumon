extends Control
## Emerald-style overworld pause menu opened with ui_accept when no NPC is in front.

signal closed

const MAIN_ITEMS := ["Pokedex", "Pokemon", "Bag", "Save", "Trainer Card", "Quit"]

@onready var title_label: Label = $Panel/Title
@onready var list_container: VBoxContainer = $Panel/MainList
@onready var team_list: VBoxContainer = $Panel/TeamList
@onready var cursor: TextureRect = $Panel/Cursor
@onready var content_label: RichTextLabel = $Panel/Content
@onready var hint_label: Label = $Panel/Hint

var _active := false
var _view := "main"
var _selected := 0
var _labels: Array[Label] = []
var _quit_selected := 0
var _save_message := ""
var _detail_kind := ""
var _pokedex_offset := 0
var _team_selected := 0
var _team_offset := 0
var _team_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	_build_main_list()

func open() -> void:
	_active = true
	_view = "main"
	_selected = 0
	_quit_selected = 0
	_save_message = ""
	visible = true
	_render_main()

func close() -> void:
	_active = false
	visible = false
	closed.emit()

func _build_main_list() -> void:
	for item in MAIN_ITEMS:
		var label := Label.new()
		label.text = item
		label.add_theme_font_size_override("font_size", 9)
		list_container.add_child(label)
		_labels.append(label)

func _render_main() -> void:
	title_label.text = "MENU"
	list_container.visible = true
	team_list.visible = false
	content_label.visible = false
	hint_label.text = "Enter: Select   Esc: Close"
	for i in range(_labels.size()):
		_labels[i].modulate = Color(1.0, 0.85, 0.2) if i == _selected else Color.WHITE
	if not _labels.is_empty():
		var target: Label = _labels[_selected]
		cursor.position = target.position + list_container.position \
			+ Vector2(-8.0, (target.size.y - cursor.size.y) / 2.0)
		cursor.visible = true

func _render_view(view_title: String, body: String) -> void:
	title_label.text = view_title
	list_container.visible = false
	team_list.visible = false
	content_label.visible = true
	content_label.text = body
	hint_label.text = "Esc: Back"

func _show_selected() -> void:
	match _selected:
		0:
			_show_pokedex()
		1:
			_show_party()
		2:
			_show_bag()
		3:
			SaveManager.save_game()
			_save_message = "Game saved."
			_render_view("SAVE", _save_message)
		4:
			_show_trainer_card()
		5:
			_view = "quit"
			_quit_selected = 0
			_render_quit()

func _show_pokedex() -> void:
	_pokedex_offset = 0
	_detail_kind = "pokedex"
	_render_pokedex()
	_view = "detail"

func _render_pokedex() -> void:
	var species_list: Array = DataRegistry.get_all_species()
	var lines := ["Seen species:"]
	var page_size := 7
	for species in species_list.slice(_pokedex_offset, _pokedex_offset + page_size):
		var number_text := "#%03d" % species.dex_number if species.dex_number > 0 else "---"
		lines.append("%s %s" % [number_text, species.display_name])
		lines.append("   %s" % species.type_id.capitalize())
	if species_list.is_empty():
		lines.append("No species recorded.")
	_render_view("POKEDEX", "\n".join(lines))
	hint_label.text = "Up/Down: Scroll   Esc: Back"

func _show_party() -> void:
	_team_selected = 0
	_team_offset = 0
	_view = "team"
	_render_team()

func _render_team() -> void:
	title_label.text = "POKEMON"
	list_container.visible = false
	team_list.visible = true
	content_label.visible = false
	hint_label.text = "Up/Down: Select   Enter/Click: Details   Esc: Back"
	for child in team_list.get_children():
		child.queue_free()
	_team_buttons.clear()
	if GameState.party.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Your party is empty."
		team_list.add_child(empty_label)
		return
	var visible_count := 8
	_team_offset = clampi(_team_offset, 0, max(0, GameState.party.size() - visible_count))
	for index in range(_team_offset, min(GameState.party.size(), _team_offset + visible_count)):
		var member: BattleCombatant = GameState.party[index]
		var status := "FAINTED" if member.is_fainted() else "HP %d/%d" % [member.current_hp, member.max_hp]
		var button := Button.new()
		button.text = "%d  %-12s Lv %d  %s" % [index + 1, member.get_display_name(), member.level, status]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(116, 11)
		button.add_theme_font_size_override("font_size", 7)
		button.pressed.connect(_open_team_detail.bind(index))
		team_list.add_child(button)
		_team_buttons.append(button)
		button.modulate = Color(1.0, 0.85, 0.2) if index == _team_selected else Color.WHITE

func _open_team_detail(index: int) -> void:
	if index < 0 or index >= GameState.party.size():
		return
	var member: BattleCombatant = GameState.party[index]
	var lines := [
		member.get_display_name(),
		"Lv %d    EXP %d/%d" % [member.level, member.experience, member.experience_to_next_level()],
		"HP  %d/%d" % [member.current_hp, member.max_hp],
		"ATK %d   DEF %d" % [member.get_attack(), member.get_defense()],
		"SpA %d   SpD %d" % [member.get_special_attack(), member.get_special_defense()],
		"SPD %d" % member.get_speed(),
		"",
		"Moves:",
	]
	for move in member.moves:
		lines.append("- %s [%s]" % [move.display_name, move.damage_class.capitalize()])
	_detail_kind = "team_detail"
	_view = "detail"
	_render_view("POKEMON", "\n".join(lines))
	hint_label.text = "Esc/Enter: Back"

func _show_bag() -> void:
	var lines := [
		"Pokeball      %d" % GameState.bag.get("poke_ball", 0),
		"Superball     %d" % GameState.bag.get("super_ball", 0),
		"Hyperball     %d" % GameState.bag.get("hyper_ball", 0),
	]
	_render_view("BAG", "\n".join(lines))
	_view = "detail"

func _show_trainer_card() -> void:
	_render_view("TRAINER CARD", "Name: Player\nBadges: 0\nLocation: Test Field")
	_view = "detail"

func _render_quit() -> void:
	title_label.text = "QUIT"
	list_container.visible = false
	content_label.visible = true
	content_label.text = "Quit the game?\n\nYes       No"
	hint_label.text = "Left/Right: Choose   Enter: Confirm   Esc: Back"
	content_label.modulate = Color(1.0, 0.85, 0.2)
	content_label.visible_characters = -1

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _view == "main":
		_handle_main_input(event)
	elif _view == "team":
		_handle_team_input(event)
	elif _view == "quit":
		_handle_quit_input(event)
	else:
		if _detail_kind == "pokedex" and event.is_action_pressed("ui_down"):
			_pokedex_offset = min(_pokedex_offset + 1, max(0, DataRegistry.get_all_species().size() - 7))
			_render_pokedex()
			get_viewport().set_input_as_handled()
		elif _detail_kind == "pokedex" and event.is_action_pressed("ui_up"):
			_pokedex_offset = max(0, _pokedex_offset - 1)
			_render_pokedex()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			if _detail_kind == "team_detail":
				_view = "team"
				_render_team()
			else:
				_render_main()
				_view = "main"
			_detail_kind = ""
			get_viewport().set_input_as_handled()

func _handle_team_input(event: InputEvent) -> void:
	if GameState.party.is_empty():
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			_render_main()
			_view = "main"
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_down"):
		_team_selected = (_team_selected + 1) % GameState.party.size()
		if _team_selected >= _team_offset + 8:
			_team_offset = _team_selected - 7
		_render_team()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_team_selected = (_team_selected - 1 + GameState.party.size()) % GameState.party.size()
		if _team_selected < _team_offset:
			_team_offset = _team_selected
		_render_team()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_open_team_detail(_team_selected)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_render_main()
		_view = "main"
		get_viewport().set_input_as_handled()

func _handle_main_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_selected = (_selected + 1) % MAIN_ITEMS.size()
		_render_main()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_selected = (_selected - 1 + MAIN_ITEMS.size()) % MAIN_ITEMS.size()
		_render_main()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_show_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _handle_quit_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_quit_selected = 1 - _quit_selected
		_render_quit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if _quit_selected == 0:
			get_tree().quit()
		else:
			_render_main()
			_view = "main"
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_render_main()
		_view = "main"
		get_viewport().set_input_as_handled()
