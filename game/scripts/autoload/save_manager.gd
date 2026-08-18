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
	GameState.party = _deserialize_party(parsed["party"])
	return true

func _deserialize_party(entries: Array) -> Array:
	var party := []
	for entry in entries:
		var species: Species = DataRegistry.get_species(entry["species_id"])
		if species == null:
			continue
		var moves := []
		for move_id in entry["move_ids"]:
			var move: Move = DataRegistry.get_move(move_id)
			if move != null:
				moves.append(move)
		var combatant := BattleCombatant.new(species, entry["level"], moves)
		combatant.current_hp = entry["current_hp"]
		combatant.nickname = entry.get("nickname", "")
		combatant.permanently_fainted = entry.get("permanently_fainted", false)
		party.append(combatant)
	return party
