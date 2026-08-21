extends Node2D
## Milestone-1 test map: procedurally builds a TileSet (grass + colliding wall tile)
## and paints a bordered room with a couple of interior obstacles, purely to prove
## movement/collision/camera work end-to-end. Replace with editor-authored maps later.

const TILE_SIZE := 16
const MAP_WIDTH := 30
const MAP_HEIGHT := 20
const GRASS_COORDS := Vector2i(0, 0)
const WALL_COORDS := Vector2i(1, 0)
const PATH_COORDS := Vector2i(2, 0)
const FLOWER_COORDS := Vector2i(3, 0)
const WATER_COORDS := Vector2i(4, 0)
const SNOW_COORDS := Vector2i(5, 0)
const BARRIER_COORDS := Vector2i(6, 0)
const BRIDGE_COORDS := Vector2i(7, 0)

const OBSTACLES := [
	Rect2i(0, 0, 30, 1),
	Rect2i(0, 19, 30, 1),
	Rect2i(0, 0, 1, 20),
	Rect2i(29, 0, 1, 20),
	Rect2i(7, 4, 1, 6),
	Rect2i(17, 11, 1, 6),
	Rect2i(21, 3, 6, 1),
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
	atlas_source.create_tile(PATH_COORDS)
	atlas_source.create_tile(FLOWER_COORDS)
	atlas_source.create_tile(WATER_COORDS)
	atlas_source.create_tile(SNOW_COORDS)
	atlas_source.create_tile(BARRIER_COORDS)
	atlas_source.create_tile(BRIDGE_COORDS)

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
	for solid_coords in [WATER_COORDS, BARRIER_COORDS]:
		var solid_data := atlas_source.get_tile_data(solid_coords, 0)
		solid_data.add_collision_polygon(0)
		solid_data.set_collision_polygon_points(0, 0, polygon)

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
			var is_snow := y <= 5 and x >= 16
			var is_water := x >= 11 and x <= 14 and y >= 2 and y <= 17 \
				and not (y >= 9 and y <= 10)
			var is_bridge := x >= 11 and x <= 14 and y >= 9 and y <= 10
			var is_path := y == 10 or x == 10 or (is_snow and y == 6)
			var is_barrier := (x == 7 and y >= 4 and y <= 9) or (x == 17 and y >= 11 and y <= 16)
			var is_flower := not is_path and not is_border and not in_obstacle \
				and ((x * 7 + y * 11) % 37 == 0)
			var coords := WALL_COORDS if (is_border or in_obstacle) \
				else BARRIER_COORDS if is_barrier else BRIDGE_COORDS if is_bridge \
				else WATER_COORDS if is_water else SNOW_COORDS if is_snow \
				else PATH_COORDS if is_path else FLOWER_COORDS if is_flower else GRASS_COORDS
			tile_map_layer.set_cell(Vector2i(x, y), _source_id, coords)

func map_pixel_size() -> Vector2i:
	return Vector2i(MAP_WIDTH * TILE_SIZE, MAP_HEIGHT * TILE_SIZE)
