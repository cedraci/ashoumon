extends Panel
## Reusable vertical selection list: battle move-select, bag, party menus all use this.

signal item_selected(index: int)
signal cancelled()

const NORMAL_COLOR := Color(1, 1, 1)
const SELECTED_COLOR := Color(1, 0.85, 0.2)

@onready var list_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var cursor: TextureRect = $Cursor

var _items: Array = []
var _labels: Array = []
var _selected := 0
var _active := false

func set_items(items: Array) -> void:
	_items = items.duplicate()
	for child in list_container.get_children():
		child.queue_free()
	_labels.clear()
	for item_text in _items:
		var lbl := Label.new()
		lbl.text = item_text
		lbl.add_theme_font_size_override("font_size", 9)
		list_container.add_child(lbl)
		_labels.append(lbl)
	_selected = 0
	_update_highlight()

func get_item_text(index: int) -> String:
	return _items[index]

func open() -> void:
	visible = true
	_active = true
	_selected = 0
	cursor.visible = not _labels.is_empty()
	_update_highlight()

func close() -> void:
	visible = false
	_active = false
	cursor.visible = false

func _update_highlight() -> void:
	for i in range(_labels.size()):
		_labels[i].modulate = SELECTED_COLOR if i == _selected else NORMAL_COLOR
	if not _labels.is_empty():
		var target: Label = _labels[_selected]
		cursor.position = target.position + list_container.position \
			+ Vector2(-8.0, (target.size.y - cursor.size.y) / 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if not _active or _items.is_empty():
		return
	if event.is_action_pressed("ui_down"):
		_selected = (_selected + 1) % _items.size()
		_update_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_selected = (_selected - 1 + _items.size()) % _items.size()
		_update_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_active = false
		get_viewport().set_input_as_handled()
		item_selected.emit(_selected)
	elif event.is_action_pressed("ui_cancel"):
		_active = false
		get_viewport().set_input_as_handled()
		cancelled.emit()
