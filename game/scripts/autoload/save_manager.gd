extends Node
## Persists GameState.party to disk as JSON. GBA-homebrew would need a fixed-size
## SRAM byte layout; a real filesystem means we can just use a versioned JSON blob.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"party": _serialize_party(),
		"bag": GameState.bag,
		"scene_path": GameState.current_scene_path,
		"overworld_position": [GameState.overworld_position.x, GameState.overworld_position.y],
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _serialize_party() -> Array:
	var out := []
	for member in GameState.party:
		var move_ids := []
		for m in member.moves:
			move_ids.append(m.id)
		out.append({
			"species_id": member.species.id,
			"level": member.level,
			"experience": member.experience,
			"current_hp": member.current_hp,
			"nickname": member.nickname,
			"permanently_fainted": member.permanently_fainted,
			"move_ids": move_ids,
		})
	return out

## Returns true if a valid save was found and loaded into GameState.party.
func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("party"):
		return false
	if parsed.get("version", 0) != SAVE_VERSION:
		return false
	if typeof(parsed["party"]) != TYPE_ARRAY:
		return false
	var loaded_party = _deserialize_party(parsed["party"])
	if loaded_party == null:
		return false
	GameState.party = loaded_party
	if typeof(parsed.get("bag", {})) == TYPE_DICTIONARY:
		GameState.bag = parsed.get("bag", {}).duplicate()
	var scene_path = parsed.get("scene_path", "")
	if typeof(scene_path) == TYPE_STRING \
	and (scene_path.is_empty() or scene_path.begins_with("res://scenes/Overworld/") and ResourceLoader.exists(scene_path)):
		GameState.loaded_scene_path = scene_path
	var saved_position = parsed.get("overworld_position", [])
	if typeof(saved_position) == TYPE_ARRAY and saved_position.size() == 2 \
	and typeof(saved_position[0]) in [TYPE_INT, TYPE_FLOAT] \
	and typeof(saved_position[1]) in [TYPE_INT, TYPE_FLOAT]:
		GameState.overworld_position = Vector2(float(saved_position[0]), float(saved_position[1]))
	return true

func _deserialize_party(entries: Array):
	if entries.size() > 10:
		return null
	var party := []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			return null
		if not entry.has_all(["species_id", "level", "current_hp", "move_ids"]):
			return null
		if typeof(entry["species_id"]) != TYPE_STRING \
		or typeof(entry["level"]) != TYPE_INT \
		or typeof(entry["current_hp"]) != TYPE_INT \
		or typeof(entry["move_ids"]) != TYPE_ARRAY:
			return null
		if entry["level"] < 1:
			return null
		var species: Species = DataRegistry.get_species(entry["species_id"])
		if species == null:
			return null
		var moves := []
		for move_id in entry["move_ids"]:
			if typeof(move_id) != TYPE_STRING:
				return null
			var move: Move = DataRegistry.get_move(move_id)
			if move != null:
				moves.append(move)
			else:
				return null
		var combatant := BattleCombatant.new(species, entry["level"], moves)
		var experience = entry.get("experience", 0)
		if typeof(experience) != TYPE_INT or experience < 0:
			return null
		combatant.experience = min(experience, combatant.experience_to_next_level() - 1)
		combatant.current_hp = clampi(entry["current_hp"], 0, combatant.max_hp)
		var nickname = entry.get("nickname", "")
		var permanently_fainted = entry.get("permanently_fainted", false)
		if typeof(nickname) != TYPE_STRING or typeof(permanently_fainted) != TYPE_BOOL:
			return null
		combatant.nickname = nickname
		combatant.permanently_fainted = permanently_fainted
		party.append(combatant)
	return party
