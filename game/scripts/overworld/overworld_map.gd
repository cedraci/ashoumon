extends Node2D
## Milestone-1 test map: procedurally builds a TileSet (grass + colliding wall tile)
## and paints a bordered room with a couple of interior obstacles, purely to prove
## movement/collision/camera work end-to-end. Replace with editor-authored maps later.

const TILE_SIZE := 16
const MAP_WIDTH := 30
const MAP_HEIGHT := 20
const GRASS_COORDS := Vector2i(0, 0)
const WALL_COORDS := Vector2i(1, 0)

const OBSTACLES := [
	Rect2i(5, 3, 3, 3),
	Rect2i(12, 8, 4, 2),
	Rect2i(20, 12, 5, 4),
	Rect2i(7, 12, 3, 3),  # Pokémon Center footprint — see Task 5 for the building/nurse placement
]

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var _source_id := -1

func _ready() -> void:
	_build_tileset()
	_paint_map()

func _build_tileset() -> void:
	var texture: Texture2D = load("res://assets/tiles/atlas.png")

	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas_source.create_tile(GRASS_COORDS)
	atlas_source.create_tile(WALL_COORDS)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)

	_source_id = tile_set.add_source(atlas_source)

	var wall_data := atlas_source.get_tile_data(WALL_COORDS, 0)
	var half := TILE_SIZE / 2.0
	var polygon := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, polygon)

	tile_map_layer.tile_set = tile_set

func _paint_map() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var is_border := x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1
			var in_obstacle := false
			for rect in OBSTACLES:
				if rect.has_point(Vector2i(x, y)):
					in_obstacle = true
					break
			var coords := WALL_COORDS if (is_border or in_obstacle) else GRASS_COORDS
			tile_map_layer.set_cell(Vector2i(x, y), _source_id, coords)

func map_pixel_size() -> Vector2i:
	return Vector2i(MAP_WIDTH * TILE_SIZE, MAP_HEIGHT * TILE_SIZE)
