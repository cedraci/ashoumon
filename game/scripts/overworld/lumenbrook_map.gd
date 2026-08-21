extends Node2D
## Standalone first pass of Lumenbrook: a plaza-centered town tilemap.

const TILE_SIZE := 16
const MAP_WIDTH := 30
const MAP_HEIGHT := 20
const GRASS := Vector2i(0, 0)
const TREE := Vector2i(1, 0)
const PATH := Vector2i(2, 0)
const FLOWER := Vector2i(3, 0)
const WATER := Vector2i(4, 0)
const BARRIER := Vector2i(6, 0)
const BRIDGE := Vector2i(7, 0)

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var _source_id := -1

func _ready() -> void:
	_build_tileset()
	_paint_town()

func _build_tileset() -> void:
	var texture: Texture2D = load("res://assets/tiles/atlas.png")
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for coords in [GRASS, TREE, PATH, FLOWER, WATER, BARRIER, BRIDGE]:
		atlas_source.create_tile(coords)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	_source_id = tile_set.add_source(atlas_source)

	var polygon := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
	])
	for coords in [TREE, WATER, BARRIER]:
		var data := atlas_source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, polygon)
	tile_map_layer.tile_set = tile_set

func _paint_town() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var coords := _tile_for(Vector2i(x, y))
			tile_map_layer.set_cell(Vector2i(x, y), _source_id, coords)

func _tile_for(cell: Vector2i) -> Vector2i:
	var x := cell.x
	var y := cell.y
	if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
		return TREE

	# A narrow stream and a bridge give the town a strong visual spine.
	var in_stream := x >= 22 and x <= 24 and y >= 2 and y <= 17
	var on_bridge := in_stream and y >= 9 and y <= 10
	if in_stream and not on_bridge:
		return WATER
	if on_bridge:
		return BRIDGE

	# Central plaza and branching paths create a readable walking hierarchy.
	var plaza := x >= 9 and x <= 19 and y >= 7 and y <= 13
	var main_path := y == 15 or x == 14 or (x >= 9 and x <= 21 and y == 10)
	if plaza or main_path:
		return PATH

	# Garden plots and tree clusters frame the plaza without making a grid.
	var garden := (x >= 3 and x <= 7 and y >= 4 and y <= 7) \
		or (x >= 4 and x <= 8 and y >= 12 and y <= 16) \
		or (x >= 16 and x <= 20 and y >= 3 and y <= 6)
	if garden and (x + y) % 3 == 0:
		return FLOWER
	if garden and (x * 5 + y * 3) % 7 == 0:
		return TREE

	# Low barriers shape the gardens and keep the plaza edges intentional.
	if (x == 8 and y >= 4 and y <= 7) or (x == 20 and y >= 3 and y <= 6):
		return BARRIER
	if (x >= 4 and x <= 7 and y == 11) or (x >= 17 and x <= 20 and y == 14):
		return BARRIER

	if (x * 7 + y * 11) % 29 == 0:
		return FLOWER
	return GRASS

func map_pixel_size() -> Vector2i:
	return Vector2i(MAP_WIDTH * TILE_SIZE, MAP_HEIGHT * TILE_SIZE)
