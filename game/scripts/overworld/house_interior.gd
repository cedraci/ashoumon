extends Node2D

const TILE_SIZE := 16
const WIDTH := 15
const HEIGHT := 10

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
	var texture: Texture2D = load("res://assets/tiles/atlas.png")
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for coords in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]:
		source.create_tile(coords)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	var polygon := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	var wall_data := source.get_tile_data(Vector2i(1, 0), 0)
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, polygon)
	var source_id := tile_set.add_source(source)
	tile_map_layer.tile_set = tile_set
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var border := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1
			tile_map_layer.set_cell(Vector2i(x, y), source_id, Vector2i(1, 0) if border else Vector2i(2, 0))