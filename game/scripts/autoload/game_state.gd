extends Node
## Holds the player's party across scene changes. Not yet persisted to disk
## (that's milestone 5's SaveManager) - lives only for the current play session.

var party: Array = []  # Array of BattleCombatant

func _ready() -> void:
	if not SaveManager.load_game():
		_create_starter_party()

func _create_starter_party() -> void:
	var tackle: Move = load("res://data/moves/tackle.tres")
	var ember: Move = load("res://data/moves/ember.tres")
	var emberkit: Species = load("res://data/species/emberkit.tres")
	party.append(BattleCombatant.new(emberkit, 5, [tackle, ember]))

func get_lead() -> BattleCombatant:
	for member in party:
		if not member.is_fainted():
			return member
	return party[0] if not party.is_empty() else null

func add_to_party(combatant: BattleCombatant) -> bool:
	if party.size() >= 6:
		return false
	party.append(combatant)
	return true
