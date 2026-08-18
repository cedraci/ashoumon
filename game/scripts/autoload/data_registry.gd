extends Node
## Indexes every Species/Move resource under res://data by their `id` field, so
## save data can reference content by a stable string id instead of a file path.
## Adding a new .tres file makes it loadable automatically - no code changes.

var _species_by_id: Dictionary = {}
var _moves_by_id: Dictionary = {}

func _ready() -> void:
	_index("res://data/species/", _species_by_id)
	_index("res://data/moves/", _moves_by_id)

func _index(dir_path: String, out_dict: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(dir_path + file_name)
			if res != null and "id" in res:
				out_dict[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_species(id: String) -> Species:
	return _species_by_id.get(id)

func get_move(id: String) -> Move:
	return _moves_by_id.get(id)
