extends Node
## Holds the player's party and overworld state across scene changes.

var party: Array = []  # Array of BattleCombatant
var bag: Dictionary = {}
var overworld_position := Vector2(240, 160)
var return_scene_path := "res://scenes/Overworld/Main.tscn"
var return_position := Vector2(240, 160)
var current_scene_path := ""
var loaded_scene_path := ""
var map_transition_locked := false
var pending_scene_position := Vector2.ZERO
var pending_scene_position_valid := false

const DEFAULT_BALL_COUNTS := {
	"poke_ball": 100,
	"super_ball": 100,
	"hyper_ball": 100,
}

func _ready() -> void:
	if not SaveManager.load_game():
		_create_starter_party()
	_ensure_default_bag()

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
	if party.size() >= 10:
		return false
	party.append(combatant)
	return true

func heal_party() -> void:
	for member in party:
		member.current_hp = member.max_hp

func _ensure_default_bag() -> void:
	for item_id in DEFAULT_BALL_COUNTS:
		if not bag.has(item_id) or typeof(bag[item_id]) != TYPE_INT:
			bag[item_id] = DEFAULT_BALL_COUNTS[item_id]
		bag[item_id] = max(0, bag[item_id])

func get_best_ball() -> String:
	for item_id in ["hyper_ball", "super_ball", "poke_ball"]:
		if bag.get(item_id, 0) > 0:
			return item_id
	return ""

func get_available_ball_ids() -> Array:
	var available: Array = []
	for item_id in ["poke_ball", "super_ball", "hyper_ball"]:
		if bag.get(item_id, 0) > 0:
			available.append(item_id)
	return available

func consume_ball(item_id: String) -> bool:
	if bag.get(item_id, 0) <= 0:
		return false
	bag[item_id] -= 1
	return true
