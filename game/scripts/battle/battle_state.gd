extends Node2D
## Turn loop over two *parties* (size 1 for wild encounters, size N for trainers),
## each with a controller-driven active member. Both wild and trainer battles share
## this same path - a trainer battle is just "enemy party size > 1, no Catch/Run menu."

signal battle_ended(result: String)  # "player" / "enemy" / "caught" / "fled"

@onready var text_box := $TextBox
@onready var menu_list := $HUD/MenuList
@onready var player_label: Label = $HUD/PlayerLabel
@onready var enemy_label: Label = $HUD/EnemyLabel
@onready var enemy_sprite: Sprite2D = $EnemySprite
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var vote_label: Label = $HUD/VoteLabel

var player_party: Array = []  # Array of BattleCombatant
var enemy_party: Array = []
var player_active: BattleCombatant
var enemy_active: BattleCombatant
var player_controller: TrainerController
var enemy_controller: TrainerController
var is_trainer_battle := false
var trainer_data: Trainer = null
var _participating_party: Array = []  # Array of BattleCombatant that were sent out

const TYPE_TINTS := {
	"fire": Color(1.0, 0.45, 0.3),
	"water": Color(0.35, 0.55, 1.0),
	"grass": Color(0.45, 0.85, 0.4),
	"normal": Color(1, 1, 1),
}

func _ready() -> void:
	if EncounterContext.pending_trainer != null:
		_setup_trainer_battle(EncounterContext.pending_trainer)
	else:
		_setup_wild_battle()

func _setup_wild_battle() -> void:
	var enemy_species: Species = EncounterContext.pending_wild_species
	var enemy_level: int = EncounterContext.pending_wild_level
	if enemy_species == null:
		# Debug fallback so this scene stays testable standalone.
		enemy_species = load("res://data/species/leaflet.tres")
		enemy_level = 5

	var tackle: Move = load("res://data/moves/tackle.tres")
	var starter_move := _starter_move_for(enemy_species)
	var e := BattleCombatant.new(enemy_species, enemy_level, [tackle, starter_move])

	is_trainer_battle = false
	battle_ended.connect(_on_battle_ended)
	start_battle(GameState.party, [e], PlayerMenuController.new(self), ScriptedAIController.new())

func _setup_trainer_battle(trainer: Trainer) -> void:
	trainer_data = trainer
	is_trainer_battle = true
	var tackle: Move = load("res://data/moves/tackle.tres")
	var roster: Array = []
	for i in range(trainer.species_ids.size()):
		var species: Species = DataRegistry.get_species(trainer.species_ids[i])
		var level: int = trainer.levels[i]
		roster.append(BattleCombatant.new(species, level, [tackle, _starter_move_for(species)]))

	var enemy_ctrl: TrainerController = ExternalChatController.new(self) if trainer.controller_type == "EXTERNAL_CHAT" else ScriptedAIController.new()

	battle_ended.connect(_on_battle_ended)
	start_battle(GameState.party, roster, PlayerMenuController.new(self), enemy_ctrl)

func _starter_move_for(species: Species) -> Move:
	match species.type_id:
		"fire":
			return load("res://data/moves/ember.tres")
		"water":
			return load("res://data/moves/water_jet.tres")
		"grass":
			return load("res://data/moves/vine_snap.tres")
		_:
			return load("res://data/moves/tackle.tres")

func _on_battle_ended(result: String) -> void:
	if result == "enemy":
		GameState.heal_party()
	var destination_scene := EncounterContext.return_scene_path
	var destination_position := EncounterContext.return_position
	if destination_scene.is_empty():
		destination_scene = "res://scenes/Overworld/StartingMeadow.tscn"
		destination_position = GameState.overworld_position
	GameState.pending_scene_position = destination_position
	GameState.pending_scene_position_valid = true
	EncounterContext.pending_wild_species = null
	EncounterContext.pending_trainer = null
	EncounterContext.return_scene_path = ""
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file(destination_scene)

func start_battle(p_player_party: Array, p_enemy_party: Array, p_player_controller: TrainerController, p_enemy_controller: TrainerController) -> void:
	player_party = p_player_party
	enemy_party = p_enemy_party
	player_controller = p_player_controller
	enemy_controller = p_enemy_controller
	player_active = _next_active(player_party)
	enemy_active = _next_active(enemy_party)
	if player_active == null or enemy_active == null:
		# One side has no usable member at all (empty party, a stale save where
		# everyone is fainted, or species that failed to resolve). Bail out instead
		# of nil-dereferencing in _apply_tints()/_update_hud(), which would abort the
		# setup chain and leave the battle screen silently frozen.
		push_warning("BattleState: a party has no usable members; ending the battle immediately.")
		text_box.say(["There's nobody able to battle!"])
		battle_ended.emit("enemy" if player_active == null else "player")
		return
	_record_participant(player_active)
	_apply_tints()
	_update_hud()
	_run_battle()

func _next_active(party: Array) -> BattleCombatant:
	for member in party:
		if not member.is_fainted():
			return member
	return null

func _apply_tints() -> void:
	player_sprite.texture = load(player_active.species.sprite_path)
	enemy_sprite.texture = load(enemy_active.species.sprite_path)
	player_sprite.modulate = TYPE_TINTS.get(player_active.species.type_id, Color.WHITE)
	enemy_sprite.modulate = TYPE_TINTS.get(enemy_active.species.type_id, Color.WHITE)

var _vote_countdown_token := 0

## Fire-and-forget: ticks a "chat is voting" label down while the caller
## separately awaits TwitchChatClient.run_vote() for the actual result.
func show_vote_countdown(duration: float, move_names: Array) -> void:
	_vote_countdown_token += 1
	var my_token := _vote_countdown_token
	vote_label.visible = true
	var remaining := duration
	while remaining > 0.0 and _vote_countdown_token == my_token:
		var options_text := ""
		for i in range(move_names.size()):
			options_text += "!%d %s  " % [i + 1, move_names[i]]
		vote_label.text = "%s(%.0fs)" % [options_text, remaining]
		await get_tree().create_timer(0.2).timeout
		remaining -= 0.2

func hide_vote_countdown() -> void:
	_vote_countdown_token += 1
	vote_label.visible = false

## Returns the chosen index, or -1 (MenuList.CANCELLED) if the player backed out
## with ui_cancel. Callers must check for -1 before using it as an array index.
func show_menu(items: Array) -> int:
	menu_list.set_items(items)
	menu_list.open()
	var result: int = await menu_list.item_selected
	menu_list.close()
	return result

func _update_hud() -> void:
	player_label.text = "%s  HP: %d/%d" % [player_active.get_display_name(), player_active.current_hp, player_active.max_hp]
	enemy_label.text = "%s  HP: %d/%d" % [enemy_active.get_display_name(), enemy_active.current_hp, enemy_active.max_hp]

func _run_battle() -> void:
	if is_trainer_battle:
		text_box.say([trainer_data.intro_line, "%s sent out %s!" % [trainer_data.display_name, enemy_active.get_display_name()]])
	else:
		text_box.say(["Wild %s appeared!" % enemy_active.get_display_name()])
	await text_box.finished

	while _next_active(player_party) != null and _next_active(enemy_party) != null:
		var outcome := await _run_turn()
		if outcome != "":
			battle_ended.emit(outcome)
			return

	var player_has_more := _next_active(player_party) != null
	if is_trainer_battle and player_has_more:
		text_box.say([trainer_data.defeat_line])
		await text_box.finished
	text_box.say(["%s wins!" % ("Player" if player_has_more else "Enemy")])
	await text_box.finished
	if player_has_more:
		await _award_experience()
	battle_ended.emit("player" if player_has_more else "enemy")

func _record_participant(member: BattleCombatant) -> void:
	if member != null and not _participating_party.has(member):
		_participating_party.append(member)

func _award_experience() -> void:
	var total_experience: int = 0
	for defeated in enemy_party:
		total_experience += defeated.level * 30
	if total_experience <= 0 or _participating_party.is_empty():
		return
	var messages: Array = []
	for member in _participating_party:
		var old_level: int = member.level
		member.gain_experience(total_experience)
		messages.append("%s gained %d EXP!" % [member.get_display_name(), total_experience])
		if member.level > old_level:
			messages.append("%s grew to Lv %d!" % [member.get_display_name(), member.level])
	text_box.say(messages)
	await text_box.finished

## Returns a battle-ending outcome string ("caught"/"fled"), or "" if the battle continues.
func _run_turn() -> String:
	await _handle_switch_ins()

	var player_action: Dictionary = await player_controller.choose_action(player_active, enemy_active)

	if player_action["type"] == "run":
		text_box.say(["Got away safely!"])
		await text_box.finished
		return "fled"

	if player_action["type"] == "catch":
		var ball_id: String = String(player_action.get("ball_id", ""))
		if ball_id == "":
			text_box.say(["You have no balls left!"])
			await text_box.finished
			var no_ball_enemy_action: Dictionary = await enemy_controller.choose_action(enemy_active, player_active)
			await _execute_action(enemy_active, player_active, no_ball_enemy_action)
			return ""
		if not GameState.consume_ball(ball_id):
			text_box.say(["You don't have that ball anymore!"])
			await text_box.finished
			return ""
		text_box.say(["You threw a %s..." % CatchMechanic.get_ball_display_name(ball_id)])
		await text_box.finished
		if CatchMechanic.attempt_catch(enemy_active, ball_id):
			var catch_destination := GameState.add_caught_pokemon(enemy_active)
			var catch_messages := ["Gotcha! %s was caught!" % enemy_active.get_display_name()]
			if catch_destination == "stored":
				catch_messages.append("Your party is full.")
				catch_messages.append("%s was sent to the Center Computer." % enemy_active.get_display_name())
			text_box.say(catch_messages)
			await text_box.finished
			NicknamePolicy.maybe_prompt(enemy_active)
			return "caught"
		text_box.say(["Oh no! It broke free!"])
		await text_box.finished
		var enemy_action: Dictionary = await enemy_controller.choose_action(enemy_active, player_active)
		await _execute_action(enemy_active, player_active, enemy_action)
		return ""

	var enemy_action: Dictionary = await enemy_controller.choose_action(enemy_active, player_active)
	var order: Array = [
		{"actor": player_active, "target": enemy_active, "action": player_action},
		{"actor": enemy_active, "target": player_active, "action": enemy_action},
	]
	order.sort_custom(func(a, b): return a["actor"].get_speed() > b["actor"].get_speed())

	for entry in order:
		if entry["actor"].is_fainted() or entry["target"].is_fainted():
			continue
		await _execute_action(entry["actor"], entry["target"], entry["action"])
		if entry["target"].is_fainted():
			text_box.say(["%s fainted!" % entry["target"].get_display_name()])
			await text_box.finished
			return ""
	return ""

## Shows a "Go, X!" message and updates HUD/tint whenever the active member on
## either side has changed since last turn (i.e. the previous one just fainted).
func _handle_switch_ins() -> void:
	var new_player_active := _next_active(player_party)
	if new_player_active != player_active:
		player_active = new_player_active
		_record_participant(player_active)
		_apply_tints()
		_update_hud()
		text_box.say(["Go, %s!" % player_active.get_display_name()])
		await text_box.finished

	var new_enemy_active := _next_active(enemy_party)
	if new_enemy_active != enemy_active:
		enemy_active = new_enemy_active
		_apply_tints()
		_update_hud()
		var lead_in := "%s sent out" % trainer_data.display_name if is_trainer_battle else "Wild"
		text_box.say(["%s %s!" % [lead_in, enemy_active.get_display_name()]])
		await text_box.finished

func _execute_action(actor: BattleCombatant, target: BattleCombatant, action: Dictionary) -> void:
	if action.get("type", "") == "no_move":
		text_box.say(["%s has no usable moves and struggles!" % actor.get_display_name()])
		await text_box.finished
		target.apply_damage(max(1, int(actor.get_attack() / 2.0)))
		_update_hud()
		return
	var move_index: int = action.get("move_index", -1)
	if move_index < 0 or move_index >= actor.moves.size():
		push_warning("BattleState: ignoring invalid move action for %s." % actor.get_display_name())
		return
	var move: Move = actor.moves[move_index]
	text_box.say(["%s used %s!" % [actor.get_display_name(), move.display_name]])
	await text_box.finished
	var damage := DamageCalc.compute_damage(actor, target, move)
	target.apply_damage(damage)
	_update_hud()
	var mult: float = TypeChart.get_multiplier(move.type_id, target.species.type_id)
	if mult > 1.0:
		text_box.say(["It's super effective!"])
		await text_box.finished
	elif mult < 1.0:
		text_box.say(["It's not very effective..."])
		await text_box.finished
