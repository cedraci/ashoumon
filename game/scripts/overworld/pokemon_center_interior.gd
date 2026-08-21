extends Node2D

const TILE_SIZE := 16
const WIDTH := 15
const HEIGHT := 10
const FLOOR_COORDS := Vector2i(2, 0)
const WALL_COORDS := Vector2i(1, 0)

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
	_build_room()
	queue_redraw()

func _build_room() -> void:
	var texture: Texture2D = load("res://assets/tiles/atlas.png")
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(FLOOR_COORDS)
	source.create_tile(WALL_COORDS)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	var wall_data := source.get_tile_data(WALL_COORDS, 0)
	var polygon := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
	])
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, polygon)
	var source_id := tile_set.add_source(source)
	tile_map_layer.tile_set = tile_set

	for y in range(HEIGHT):
		for x in range(WIDTH):
			var exit_x := int(WIDTH / 2)
			var is_exit_gap := x == exit_x and y == HEIGHT - 1
			var is_border := (x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1) and not is_exit_gap
			tile_map_layer.set_cell(Vector2i(x, y), source_id, WALL_COORDS if is_border else FLOOR_COORDS)

func _draw() -> void:
	# Counter, equipment, and room accents are drawn at the native 240x160 scale.
	draw_rect(Rect2(40, 48, 160, 16), Color("#6b3f32"), true)
	draw_rect(Rect2(40, 48, 160, 3), Color("#d59b61"), true)
	draw_rect(Rect2(48, 80, 32, 24), Color("#304957"), true)
	draw_rect(Rect2(52, 84, 24, 14), Color("#72d4c3"), true)
	draw_rect(Rect2(56, 87, 16, 2), Color("#e6fff0"), true)
	draw_rect(Rect2(56, 92, 10, 2), Color("#e6fff0"), true)
	draw_rect(Rect2(48, 104, 32, 4), Color("#1f2f38"), true)
	draw_rect(Rect2(104, 112, 32, 8), Color("#d59b61"), true)
	draw_rect(Rect2(112, 120, 16, 4), Color("#6b3f32"), true)
	draw_string(ThemeDB.fallback_font, Vector2(48, 76), "PC", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#e6fff0"))
	draw_string(ThemeDB.fallback_font, Vector2(95, 40), "HEALING CENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#fff0c2"))
