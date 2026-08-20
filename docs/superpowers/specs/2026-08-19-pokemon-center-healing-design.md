# Pokémon Center healing + battle-loss healing

## Context

Currently there is no way to heal a party outside of winning battles (which doesn't
heal at all) — losing a battle just returns to the overworld with the party still
fainted/damaged, and there is no in-world way to restore HP. This spec covers two
related fixes:

1. Auto-heal the party when the player loses a battle (matches the classic
   "blackout" behavior — losing isn't a soft-lock, but it isn't free either since
   winning still doesn't heal).
2. A Pokémon Center the player can walk into and talk to a nurse to heal on demand,
   any time.

(2) requires a real NPC-interaction subsystem, since none exists yet. `main.gd` is
currently an explicit "Milestone-2 harness" (its own doc comment says so) that fakes
a dialogue/menu demo on `ui_accept` and triggers a random wild battle on `ui_cancel`
— neither of those is real gameplay and both conflict with real interaction, so this
spec also removes them.

## 1. Heal on battle loss

- `GameState.gd` gets `func heal_party() -> void`: sets `current_hp = max_hp` for
  every `BattleCombatant` in `party`.
- `battle_state.gd::_on_battle_ended(result)`: when `result == "enemy"` (player
  lost), call `GameState.heal_party()` before returning to the overworld. Winning
  does not trigger this — only the Center heals on demand after a win.

## 2. NPC interaction subsystem

### Facing + interact zone (`player_controller.gd`, `Player.tscn`)

- `PlayerController` gains `var facing := Vector2i(0, 1)` (default: facing down).
  Movement input is continuous and can be diagonal, but facing must be a single
  cardinal direction, so: whichever axis has the larger `abs()` value in
  `input_vector` wins; on an exact tie, keep the previous facing (don't flicker).
  Only updates when `input_vector` is non-zero — releasing all keys keeps the last
  facing.
- `Player.tscn` gains a child `InteractZone` (`Area2D`, small ~8x8
  `RectangleShape2D`, `collision_layer = 0`, `collision_mask = 1` so it only reads
  the world, same convention as `EncounterZone`). Each frame, its `position` is set
  to `facing * 16` (one tile ahead), so it always sits on the tile the player is
  facing.
- On `ui_accept` press (only when not already frozen/busy — see below):
  `InteractZone.get_overlapping_bodies()` filtered to group `"interactable"`; if one
  is found, call `.interact()` on it and freeze player movement
  (`_frozen = true`, `_physics_process` skips `move_and_slide` input while frozen)
  until the NPC's interaction signals completion.
- This reuses `EncounterZone`'s existing Area2D-trigger convention (just the
  detector lives on the player instead of the zone), so no new detection pattern
  enters the codebase.

### NPC (`NPC.tscn`, `npc_controller.gd`)

- `StaticBody2D` (blocks movement, so players can't walk through NPCs), in group
  `"interactable"`.
- `@export var dialogue_lines: Array[String] = []`
- `@export var npc_type: String = "generic"` — `"generic"` just shows
  `dialogue_lines` via the scene's `TextBox` and unfreezes the player when done;
  `"nurse"` shows a greeting line, opens a Yes/No `MenuList` ("Heal your party?"),
  and on Yes calls `GameState.heal_party()` and shows a confirmation line, on No
  shows a short goodbye line — then unfreezes the player either way.
- NPCs need a reference to the scene's shared `TextBox`/`MenuList` (owned by
  `Main.gd`, matching how `main.gd`'s existing demo already uses them) — passed in
  via `Main.gd` calling `npc.setup(text_box, menu_list, player)` once at `_ready()`,
  rather than NPCs reaching upward via fragile absolute paths. `player` is needed so
  the NPC can call `player.unfreeze()` when the conversation ends.
- No general-purpose dialogue-tree engine, no NPC movement/schedules — out of scope,
  YAGNI. This is deliberately just enough to support a generic talker and the nurse.

### Pokémon Center building (visual + placement)

- One small decorative building sprite (roof + wall, same `pixelgen.js` tooling as
  the rest of the visual layer), placed as a plain `Sprite2D` in `Main.tscn` — not
  part of the procedural `TileMapLayer`, since that map is built at runtime by
  `overworld_map.gd` and this is a one-off landmark, not a repeating tile.
- A couple of the existing `WALL_COORDS` obstacle tiles get added to
  `overworld_map.gd`'s `OBSTACLES` list at the building's footprint so the player
  can't walk straight through where the building "is" — reuses the existing
  obstacle mechanism, no new tile types.
- One `NPC.tscn` instance (`npc_type = "nurse"`) placed at the building's entrance.

### `main.gd` cleanup

- Remove `_run_demo()` and the `ui_accept`/`ui_cancel` block in
  `_unhandled_input` (the fake dialogue demo and the debug-random-wild-encounter
  trigger) — both are dead weight now that real interaction exists, and the
  `ui_accept` one would directly conflict with talking to NPCs.
- Keep the `F5`/`F9` save/load and `T`/`C` debug-trainer-battle hotkeys — they're
  raw `KEY_*` checks, not `ui_accept`/`ui_cancel`, so they don't conflict and are
  still useful for testing.

## Testing

Screenshots alone can't verify this (it's input-driven, not just visual), so
verification will simulate real input in a throwaway debug harness — same
screenshot-after-N-frames pattern used for the visual-layer work, but driving
`Input.action_press`/`action_release` to walk the player to the nurse, press
interact, select "Yes", and confirm both the dialogue text and the party's HP
change. Also verify a losing battle leaves the party fully healed on return to the
overworld. All debug scaffolding gets deleted after verification, as before.

## Out of scope

- General dialogue-tree/branching system.
- NPC movement, schedules, or multiple Centers.
- Any change to what winning a battle does (still no auto-heal).
- Money/items/shop system (mentioned nowhere in the request; not implied by
  "Pokémon Center").
