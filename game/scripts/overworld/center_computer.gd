extends StaticBody2D

var _text_box
var _player
var _storage_menu

func _ready() -> void:
	add_to_group("interactable")
	queue_redraw()

func setup(text_box, _menu_list, player) -> void:
	_text_box = text_box
	_player = player
	_storage_menu = get_tree().current_scene.get_node_or_null("UILayer/StorageMenu")
	if _storage_menu != null and not _storage_menu.closed.is_connected(_on_storage_closed):
		_storage_menu.closed.connect(_on_storage_closed)

func interact() -> void:
	if _player == null or _storage_menu == null:
		return
	_storage_menu.open()

func _on_storage_closed() -> void:
	if _player != null:
		_player.unfreeze()

func _draw() -> void:
	draw_rect(Rect2(-8, -8, 16, 16), Color("#304957"), true)
	draw_rect(Rect2(-6, -6, 12, 9), Color("#72d4c3"), true)
	draw_rect(Rect2(-4, -4, 8, 2), Color("#e6fff0"), true)
	draw_rect(Rect2(-4, 0, 5, 2), Color("#e6fff0"), true)
	draw_rect(Rect2(-5, 8, 10, 2), Color("#1f2f38"), true)
