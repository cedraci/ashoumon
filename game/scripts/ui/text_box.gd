extends CanvasLayer
## Reusable dialogue box: queues lines, types them out, advances/skips on ui_accept.

signal finished

const CHARS_PER_SECOND := 40.0

@onready var label: RichTextLabel = $Panel/MarginContainer/Label
@onready var indicator: TextureRect = $Panel/ContinueIndicator

var _queue: Array = []
var _typing := false

func _ready() -> void:
	visible = false

func say(lines: Array) -> void:
	_queue = lines.duplicate()
	visible = true
	_show_next_line()

func _show_next_line() -> void:
	if _queue.is_empty():
		visible = false
		finished.emit()
		return
	var line: String = _queue.pop_front()
	label.text = line
	label.visible_characters = 0
	indicator.visible = false
	_typing = true
	var total_chars := label.get_total_character_count()
	var char_index := 0
	while _typing and char_index < total_chars:
		await get_tree().create_timer(1.0 / CHARS_PER_SECOND).timeout
		char_index += 1
		label.visible_characters = char_index
	label.visible_characters = total_chars
	_typing = false
	indicator.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		if _typing:
			_typing = false
		else:
			_show_next_line()
		get_viewport().set_input_as_handled()
