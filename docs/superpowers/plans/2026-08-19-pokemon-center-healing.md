# Pokémon Center Healing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Heal the party automatically on a battle loss, and add a Pokémon Center with a nurse the player can talk to and heal on demand — which requires building a small NPC-interaction subsystem that doesn't exist yet.

**Architecture:** A `facing` direction + a repositioning `InteractZone` on the player (mirrors `EncounterZone`'s existing Area2D-trigger convention, just facing the other way) drives a generic `NPC` node (`StaticBody2D`, blocks movement, `npc_type` of `"generic"` or `"nurse"`). `main.gd`'s throwaway "Milestone-2 harness" demo code is removed since it directly conflicts with real interaction.

**Tech Stack:** Godot 4.7 / GDScript. `game/tools/pixelgen.js` (Node, no dependencies) for the two new sprites (nurse, building).

**Spec:** `docs/superpowers/specs/2026-08-19-pokemon-center-healing-design.md`

## Global Constraints

- Reuse `ui_accept` for interaction — no new input action is added (per spec).
- `"interactable"` is the exact group name NPCs use; `InteractZone` filters on it.
- NPCs are `StaticBody2D` on `collision_layer = 1` (same layer as walls/tilemap) —
  `Area2D.get_overlapping_bodies()` only returns `PhysicsBody2D` nodes, so an `Area2D`
  NPC would never be detected.
- No dialogue-tree engine, no NPC movement/schedules, no shop/money system, no
  change to what winning a battle does — all explicitly out of scope per spec.
- Every debug/verification scene and script created for testing is deleted at the
  end of its task (same convention used throughout this project's prior visual-layer
  work) — nothing throwaway gets committed.
- Godot binary for all verification:
  `C:/Users/cedri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.1-stable_win64_console.exe`
  Project path: `C:/Users/cedri/Desktop/testashou/game`. Always run
  `--headless --path <project> --import` after adding/changing any `.png` asset,
  before running a scene that uses it, so Godot generates the `.import` file.
- To simulate the interact/confirm button (`ui_accept`, `ui_up`, `ui_down`,
  `ui_cancel`) in a debug harness, you must use a synthetic `InputEventAction` via
  `Input.parse_input_event()` — these buttons are read via `_unhandled_input(event)`
  in `player_controller.gd`/`menu_list.gd`/`text_box.gd`, which only reacts to real
  input *events*, not `Input.action_press()` (that API only affects **polling**
  reads like `Input.get_action_strength()`, which is what continuous movement uses).
  Movement (`ui_left/right/up/down` held) uses `Input.action_press()`/`action_release()`
  correctly since `player_controller.gd`'s movement code polls every physics frame.
- Save any debug/verification screenshots to `C:/Users/cedri/Desktop/testashou/.debug_output/`
  (create the directory if it doesn't exist) and view them with the Read tool — this
  is a fixed, project-local path so it works the same regardless of which session or
  agent runs the task, unlike a session-specific temp/scratchpad directory.
  `.debug_output/` is already git-ignored.

---

## Task 1: Heal the party on battle loss

**Files:**
- Modify: `game/scripts/autoload/game_state.gd`
- Modify: `game/scripts/battle/battle_state.gd:80-84` (the `_on_battle_ended` function)

**Interfaces:**
- Produces: `GameState.heal_party() -> void` — sets every party member's
  `current_hp = max_hp`. Later tasks (3, 5) call this same function from the nurse's
  "Yes" branch.

- [ ] **Step 1: Add `heal_party()` to `GameState`**

Open `game/scripts/autoload/game_state.gd` and add this function (anywhere after
`add_to_party`):

```gdscript
func heal_party() -> void:
	for member in party:
		member.current_hp = member.max_hp
```

- [ ] **Step 2: Call it on a loss in `battle_state.gd`**

In `game/scripts/battle/battle_state.gd`, find:

```gdscript
func _on_battle_ended(_result: String) -> void:
	EncounterContext.pending_wild_species = null
	EncounterContext.pending_trainer = null
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/Overworld/Main.tscn")
```

Replace it with:

```gdscript
func _on_battle_ended(result: String) -> void:
	if result == "enemy":
		GameState.heal_party()
	EncounterContext.pending_wild_species = null
	EncounterContext.pending_trainer = null
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/Overworld/Main.tscn")
```

(Renamed the parameter from `_result` to `result` since it's now used — the
underscore prefix was only there because it used to be unused.)

- [ ] **Step 3: Write and run a verification harness**

Create `game/scripts/battle/_debug_heal_on_loss.gd`:

```gdscript
extends Node
## Throwaway verification harness for heal-on-loss. Deleted after verification.

func _ready() -> void:
	GameState.party = [BattleCombatant.new(load("res://data/species/emberkit.tres"), 5, [load("res://data/moves/tackle.tres")])]
	GameState.party[0].apply_damage(30)
	if GameState.party[0].current_hp >= GameState.party[0].max_hp:
		print("FAIL setup: party should start damaged")
		get_tree().quit()
		return

	var battle := load("res://scenes/Battle/Battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame

	battle._on_battle_ended("enemy")

	if GameState.party[0].current_hp == GameState.party[0].max_hp:
		print("PASS: party healed on loss")
	else:
		print("FAIL: party not healed on loss, hp=%d/%d" % [GameState.party[0].current_hp, GameState.party[0].max_hp])
	get_tree().quit()
```

Create `game/scenes/Battle/_debug_heal_on_loss.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/_debug_heal_on_loss.gd" id="1_script"]

[node name="DebugRoot" type="Node"]
script = ExtResource("1_script")
```

Run:

```bash
GODOT="C:/Users/cedri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.1-stable_win64_console.exe"
cd "/c/Users/cedri/Desktop/testashou/game"
"$GODOT" --headless --path . --import
"$GODOT" --path . res://scenes/Battle/_debug_heal_on_loss.tscn
```

Expected: `PASS: party healed on loss` printed, no `ERROR:`/`FAIL` lines.

- [ ] **Step 4: Delete the debug harness**

```bash
rm game/scenes/Battle/_debug_heal_on_loss.tscn game/scripts/battle/_debug_heal_on_loss.gd
rm -f game/scenes/Battle/_debug_heal_on_loss.tscn.uid game/scripts/battle/_debug_heal_on_loss.gd.uid
```

- [ ] **Step 5: Commit**

```bash
git add game/scripts/autoload/game_state.gd game/scripts/battle/battle_state.gd
git commit -m "feat: heal the party automatically on a battle loss"
```

---

## Task 2: Player facing direction + InteractZone

**Files:**
- Modify: `game/scripts/overworld/player_controller.gd`
- Modify: `game/scenes/Overworld/Player.tscn`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `PlayerController.facing: Vector2i` — current cardinal facing, default `Vector2i(0, 1)` (down).
  - `PlayerController.unfreeze() -> void` — called by NPCs (Task 3) when a conversation ends.
  - `Player.tscn` gains a child node `InteractZone` (`Area2D`), which Task 3/5 don't touch directly, but Task 5's end-to-end test relies on it existing and repositioning correctly.

- [ ] **Step 1: Rewrite `player_controller.gd`**

Replace the entire contents of `game/scripts/overworld/player_controller.gd` with:

```gdscript
extends CharacterBody2D

const SPEED := 60.0
const TILE_SIZE := 16.0

@onready var interact_zone: Area2D = $InteractZone

var facing := Vector2i(0, 1)
var _frozen := false

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		_update_facing(input_vector)

	if _frozen:
		velocity = Vector2.ZERO
	else:
		velocity = input_vector * SPEED
	move_and_slide()

	interact_zone.position = Vector2(facing.x, facing.y) * TILE_SIZE

func _update_facing(input_vector: Vector2) -> void:
	if abs(input_vector.x) > abs(input_vector.y):
		facing = Vector2i(int(sign(input_vector.x)), 0)
	elif abs(input_vector.y) > abs(input_vector.x):
		facing = Vector2i(0, int(sign(input_vector.y)))
	# Exact diagonal tie: keep the previous facing rather than flicker.

func _unhandled_input(event: InputEvent) -> void:
	if _frozen:
		return
	if event.is_action_pressed("ui_accept"):
		for body in interact_zone.get_overlapping_bodies():
			if body.is_in_group("interactable"):
				get_viewport().set_input_as_handled()
				_frozen = true
				body.interact()
				return

func unfreeze() -> void:
	_frozen = false
```

- [ ] **Step 2: Add `InteractZone` to `Player.tscn`**

Replace the entire contents of `game/scenes/Overworld/Player.tscn` with:

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/player_overworld.png" id="1_sprite"]
[ext_resource type="Script" path="res://scripts/overworld/player_controller.gd" id="2_script"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(10, 13)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_2"]
size = Vector2(8, 8)

[node name="Player" type="CharacterBody2D"]
script = ExtResource("2_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, -1)
texture = ExtResource("1_sprite")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 1.5)
shape = SubResource("RectangleShape2D_1")

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_top = 0
limit_right = 480
limit_bottom = 320
position_smoothing_enabled = true

[node name="InteractZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 1
position = Vector2(0, 16)

[node name="CollisionShape2D" type="CollisionShape2D" parent="InteractZone"]
shape = SubResource("RectangleShape2D_2")
```

- [ ] **Step 3: Write and run a verification harness**

Create `game/scripts/overworld/_debug_interact_stub.gd` (a minimal stand-in
"interactable" — the real `NPC` doesn't exist until Task 3):

```gdscript
extends StaticBody2D

var interact_count := 0

func interact() -> void:
	interact_count += 1
```

Create `game/scripts/overworld/_debug_facing_zone.gd`:

```gdscript
extends Node2D
## Throwaway harness for facing + InteractZone. Deleted after verification.

func _press_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)

func _ready() -> void:
	var player = load("res://scenes/Overworld/Player.tscn").instantiate()
	add_child(player)
	player.global_position = Vector2(100, 100)

	var stub := StaticBody2D.new()
	stub.collision_layer = 1
	stub.collision_mask = 0
	stub.add_to_group("interactable")
	stub.set_script(load("res://scripts/overworld/_debug_interact_stub.gd"))
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	stub.add_child(shape)
	add_child(stub)
	# Player defaults to facing down (0,1); interact zone should reach (100,116).
	stub.global_position = Vector2(100, 116)

	await get_tree().physics_frame
	await get_tree().physics_frame

	if player.facing != Vector2i(0, 1):
		print("FAIL: default facing should be (0,1), got %s" % [player.facing])
		get_tree().quit()
		return

	_press_action("ui_accept")
	await get_tree().create_timer(0.1).timeout

	if stub.interact_count == 1:
		print("PASS: interact zone detected stub and called interact()")
	else:
		print("FAIL: interact_count = %d, expected 1" % stub.interact_count)
	get_tree().quit()
```

Create `game/scenes/Overworld/_debug_facing_zone.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/overworld/_debug_facing_zone.gd" id="1_script"]

[node name="DebugRoot" type="Node2D"]
script = ExtResource("1_script")
```

Run:

```bash
GODOT="C:/Users/cedri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.1-stable_win64_console.exe"
cd "/c/Users/cedri/Desktop/testashou/game"
"$GODOT" --headless --path . --import
"$GODOT" --path . res://scenes/Overworld/_debug_facing_zone.tscn
```

Expected: both `PASS:` lines printed, no `ERROR:` lines. If `interact_count` is 0,
double check `stub.global_position` matches where `interact_zone` actually lands
(print `player.interact_zone.global_position` to compare) before changing anything.

- [ ] **Step 4: Delete the debug harness**

```bash
rm game/scenes/Overworld/_debug_facing_zone.tscn game/scripts/overworld/_debug_facing_zone.gd game/scripts/overworld/_debug_interact_stub.gd
rm -f game/scenes/Overworld/_debug_facing_zone.tscn.uid game/scripts/overworld/_debug_facing_zone.gd.uid game/scripts/overworld/_debug_interact_stub.gd.uid
```

- [ ] **Step 5: Commit**

```bash
git add game/scripts/overworld/player_controller.gd game/scenes/Overworld/Player.tscn
git commit -m "feat: add player facing direction and an interact zone"
```

---

## Task 3: NPC subsystem (generic + nurse) and the nurse sprite

**Files:**
- Create: `game/scripts/overworld/npc_controller.gd`
- Create: `game/scenes/Overworld/NPC.tscn`
- Modify: `game/tools/gen_sprites.js` (add the nurse sprite generator)
- Create (generated): `game/assets/sprites/nurse_npc.png`

**Interfaces:**
- Consumes: `GameState.heal_party()` (Task 1), `PlayerController.unfreeze()` (Task 2).
- Produces:
  - `NPC.setup(text_box, menu_list, player) -> void`
  - `NPC.interact() -> void`
  - `NPC.dialogue_lines: Array[String]` (export, default `[]`)
  - `NPC.npc_type: String` (export, default `"nurse"` — see step 2 for why)
  - Task 5 instances `NPC.tscn` directly in `Main.tscn` and calls `.setup(...)` on it
    from `main.gd`.

- [ ] **Step 1: Add the nurse sprite generator**

Open `game/tools/gen_sprites.js`. Add these constants near the top, alongside the
existing `PALETTE` object (character-only tones, same convention already used for
`SKIN`/`HAIR`):

```js
const CAP_WHITE = [245, 240, 232, 255];
const CROSS_RED = [196, 74, 62, 255];
const DRESS_WHITE = [245, 240, 232, 255];
```

Add this function after `paintPlayer`:

```js
// --- Nurse NPC: same body plan as the player sprite, white cap+dress, small red
// cross on the cap. 16x16.
function paintNurse(x, y) {
	// Red cross on the cap — checked first so it overrides the cap fill beneath it.
	if (x === 7 && (y === 1 || y === 2)) return CROSS_RED;
	if (y === 2 && (x === 6 || x === 8)) return CROSS_RED;
	// Cap (rows 1-3)
	if (y === 1 && x >= 5 && x <= 10) return PALETTE.OUTLINE;
	if (y === 2 && x >= 4 && x <= 11) return (x === 4 || x === 11) ? PALETTE.OUTLINE : CAP_WHITE;
	if (y === 3 && x >= 5 && x <= 10) return CAP_WHITE;
	// Face (rows 4-6)
	if (y >= 4 && y <= 6) {
		if (x === 5 || x === 10) return PALETTE.OUTLINE;
		if (x >= 6 && x <= 9) return PALETTE.SKIN;
	}
	if (y === 5 && (x === 6 || x === 9)) return PALETTE.OUTLINE; // eyes
	// Dress (rows 7-13)
	if (y >= 7 && y <= 13) {
		if (x === 4 || x === 11) return PALETTE.OUTLINE;
		if (x >= 5 && x <= 10) return DRESS_WHITE;
	}
	if (y === 10 && x >= 5 && x <= 10) return CROSS_RED; // belt accent
	// Shoes (row 14)
	if (y === 14 && x >= 5 && x <= 10) return PALETTE.OUTLINE;
	return null;
}
```

At the bottom of the file, alongside the existing `player.writePNG(...)` call, add:

```js
const nurse = new Canvas(16, 16);
nurse.forEach((x, y, c) => { const col = paintNurse(x, y); if (col) c.setPixel(x, y, col); });
nurse.writePNG(path.join(OUT_DIR, 'nurse_npc.png'));
```

- [ ] **Step 2: Generate and visually check the sprite**

```bash
cd "/c/Users/cedri/Desktop/testashou/game/tools"
node gen_sprites.js
mkdir -p "/c/Users/cedri/Desktop/testashou/.debug_output"
node -e "
const { Canvas } = require('./pixelgen.js');
const fs = require('fs');
const zlib = require('zlib');
function decodePNG(buf) {
  let offset = 8; let width, height, idat = [];
  while (offset < buf.length) {
    const len = buf.readUInt32BE(offset);
    const type = buf.toString('ascii', offset+4, offset+8);
    const data = buf.subarray(offset+8, offset+8+len);
    if (type === 'IHDR') { width = data.readUInt32BE(0); height = data.readUInt32BE(4); }
    if (type === 'IDAT') idat.push(data);
    offset += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const out = new Canvas(width, height);
  let pos = 0;
  for (let y=0;y<height;y++){ pos++; for (let x=0;x<width;x++){ out.setPixel(x,y,[raw[pos],raw[pos+1],raw[pos+2],raw[pos+3]]); pos+=4; } }
  return out;
}
function upscale(canvas, factor) {
  const out = new Canvas(canvas.width*factor, canvas.height*factor);
  for (let y=0;y<canvas.height;y++) for (let x=0;x<canvas.width;x++) {
    const px = canvas.getPixel(x,y);
    for (let dy=0;dy<factor;dy++) for (let dx=0;dx<factor;dx++) out.setPixel(x*factor+dx,y*factor+dy,px);
  }
  return out;
}
upscale(decodePNG(fs.readFileSync('../assets/sprites/nurse_npc.png')), 12).writePNG('C:/Users/cedri/Desktop/testashou/.debug_output/nurse_npc_12x.png');
"
```

View `C:/Users/cedri/Desktop/testashou/.debug_output/nurse_npc_12x.png` with the
Read tool. Confirm it reads as a person with a white cap+dress and a visible small
red cross — if the cross or cap looks wrong, adjust the pixel coordinates in
`paintNurse` and regenerate before moving on.

- [ ] **Step 3: Write `npc_controller.gd`**

Create `game/scripts/overworld/npc_controller.gd`:

```gdscript
extends StaticBody2D
## Generic overworld NPC: "generic" just shows dialogue_lines; "nurse" runs a
## Yes/No heal confirmation. No dialogue-tree engine, no movement/schedules —
## deliberately just enough for these two cases (see the design spec).

@export var dialogue_lines: Array[String] = []
@export var npc_type: String = "generic"

var _text_box
var _menu_list
var _player

func setup(text_box, menu_list, player) -> void:
	_text_box = text_box
	_menu_list = menu_list
	_player = player

func interact() -> void:
	if npc_type == "nurse":
		_run_nurse_flow()
	else:
		_run_generic_flow()

func _run_generic_flow() -> void:
	_text_box.say(dialogue_lines)
	await _text_box.finished
	_player.unfreeze()

func _run_nurse_flow() -> void:
	_text_box.say(["Welcome to the Pokemon Center!", "Would you like to heal your party?"])
	await _text_box.finished
	_menu_list.set_items(["Yes", "No"])
	_menu_list.open()
	var choice: int = await _menu_list.item_selected
	_menu_list.close()
	if choice == 0:
		GameState.heal_party()
		_text_box.say(["Your party has been healed!"])
	else:
		_text_box.say(["Alright, safe travels!"])
	await _text_box.finished
	_player.unfreeze()
```

- [ ] **Step 4: Create `NPC.tscn`**

Create `game/scenes/Overworld/NPC.tscn`. Default `npc_type` is `"nurse"` and the
default texture is the nurse sprite — this project only ships one NPC instance (the
nurse, wired in Task 5), so the scene's own defaults double as that instance's
config with no per-instance property overrides needed. A future second NPC would
override `npc_type`/`dialogue_lines`/the `Sprite2D`'s `texture` on its own instance.

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/nurse_npc.png" id="1_sprite"]
[ext_resource type="Script" path="res://scripts/overworld/npc_controller.gd" id="2_script"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(10, 13)

[node name="NPC" type="StaticBody2D"]
collision_layer = 1
collision_mask = 0
script = ExtResource("2_script")
npc_type = "nurse"

[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, -1)
texture = ExtResource("1_sprite")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 1.5)
shape = SubResource("RectangleShape2D_1")
```

- [ ] **Step 5: Write and run a verification harness**

Create `game/scripts/overworld/_debug_npc_flows.gd`:

```gdscript
extends Node2D
## Throwaway harness for NPC generic + nurse flows. Deleted after verification.

func _press_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)

func _flush_textbox(line_count: int) -> void:
	for i in range(line_count * 2):
		_press_action("ui_accept")
		await get_tree().create_timer(0.05).timeout

func _ready() -> void:
	GameState.party = [BattleCombatant.new(load("res://data/species/emberkit.tres"), 5, [load("res://data/moves/tackle.tres")])]

	var text_box = load("res://scenes/UI/TextBox.tscn").instantiate()
	add_child(text_box)
	var menu_list = load("res://scenes/UI/MenuList.tscn").instantiate()
	add_child(menu_list)
	var player = load("res://scenes/Overworld/Player.tscn").instantiate()
	add_child(player)

	# --- Generic NPC ---
	var generic_npc = load("res://scenes/Overworld/NPC.tscn").instantiate()
	generic_npc.npc_type = "generic"
	generic_npc.dialogue_lines = ["Hello there!"]
	add_child(generic_npc)
	generic_npc.setup(text_box, menu_list, player)

	generic_npc.interact()
	await _flush_textbox(1)
	await get_tree().create_timer(0.1).timeout
	if text_box.visible:
		print("FAIL: generic NPC textbox still visible after flushing")
	else:
		print("PASS: generic NPC dialogue completed and closed")

	# --- Nurse NPC ---
	GameState.party[0].apply_damage(20)
	if GameState.party[0].current_hp >= GameState.party[0].max_hp:
		print("FAIL setup: party should be damaged before nurse test")

	var nurse = load("res://scenes/Overworld/NPC.tscn").instantiate()
	add_child(nurse)
	nurse.setup(text_box, menu_list, player)
	nurse.interact()
	await _flush_textbox(2)     # "Welcome..." + "Would you like..." lines
	await get_tree().create_timer(0.1).timeout
	_press_action("ui_accept")   # confirm "Yes" (default selection index 0)
	await get_tree().create_timer(0.1).timeout
	await _flush_textbox(1)      # "Your party has been healed!" line

	if GameState.party[0].current_hp == GameState.party[0].max_hp:
		print("PASS: nurse healed the party")
	else:
		print("FAIL: party hp = %d/%d after nurse Yes" % [GameState.party[0].current_hp, GameState.party[0].max_hp])
	get_tree().quit()
```

Create `game/scenes/Overworld/_debug_npc_flows.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/overworld/_debug_npc_flows.gd" id="1_script"]

[node name="DebugRoot" type="Node2D"]
script = ExtResource("1_script")
```

Run:

```bash
GODOT="C:/Users/cedri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.1-stable_win64_console.exe"
cd "/c/Users/cedri/Desktop/testashou/game"
"$GODOT" --headless --path . --import
"$GODOT" --path . res://scenes/Overworld/_debug_npc_flows.tscn
```

Expected: `PASS: generic NPC dialogue completed and closed` and
`PASS: nurse healed the party`, no `ERROR:`/`FAIL` lines.

- [ ] **Step 6: Delete the debug harness**

```bash
rm game/scenes/Overworld/_debug_npc_flows.tscn game/scripts/overworld/_debug_npc_flows.gd
rm -f game/scenes/Overworld/_debug_npc_flows.tscn.uid game/scripts/overworld/_debug_npc_flows.gd.uid
```

- [ ] **Step 7: Commit**

```bash
git add game/tools/gen_sprites.js game/assets/sprites/nurse_npc.png game/assets/sprites/nurse_npc.png.import
git add game/scripts/overworld/npc_controller.gd game/scenes/Overworld/NPC.tscn
git commit -m "feat: add generic/nurse NPC interaction and the nurse sprite"
```

---

## Task 4: Pokémon Center building visual

**Files:**
- Create: `game/tools/gen_pokecenter.js`
- Create (generated): `game/assets/tiles/pokecenter_building.png`
- Modify: `game/scripts/overworld/overworld_map.gd` (add one obstacle rect)

**Interfaces:**
- Produces: `res://assets/tiles/pokecenter_building.png` (48x48), and a new
  `OBSTACLES` entry `Rect2i(7, 12, 3, 3)` — Task 5 places the building `Sprite2D`
  and the nurse `NPC` instance relative to this exact footprint, so the coordinates
  here are load-bearing, not illustrative.

- [ ] **Step 1: Write the building generator**

Create `game/tools/gen_pokecenter.js`:

```js
// Generates the Pokémon Center building backdrop onto
// game/assets/tiles/pokecenter_building.png — a 48x48 decorative sprite (matches
// the 3x3-tile obstacle footprint added to overworld_map.gd's OBSTACLES). Palette
// values must match game/scripts/ui/palette.gd plus ACCENT_RED for the roof.
'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_FILE = path.join(__dirname, '..', 'assets', 'tiles', 'pokecenter_building.png');
const SIZE = 48;

const OUTLINE = [56, 40, 32, 255];
const ROOF = [196, 74, 62, 255];       // ACCENT_RED
const ROOF_DARK = [156, 55, 46, 255];
const WALL = [219, 193, 133, 255];     // SAND
const WALL_DARK = [176, 140, 92, 255]; // SAND_DARK
const DOOR = [92, 62, 42, 255];

function paint(x, y) {
	// Roof: triangular peak, rows 0-19, widening from the apex down to row 19.
	if (y < 20) {
		const roofHalfWidth = (y / 19) * 24;
		const distFromCenter = Math.abs(x - 23.5);
		if (distFromCenter <= roofHalfWidth) {
			return distFromCenter >= roofHalfWidth - 2 ? ROOF_DARK : ROOF;
		}
		return null; // outside the roof triangle, above the walls: transparent
	}
	// Outline around the building's footprint.
	if (x === 0 || x === SIZE - 1 || y === SIZE - 1) return OUTLINE;
	// Walls with a centered door.
	if (y >= 34) {
		if (x >= 20 && x <= 27) {
			return (x === 20 || x === 27 || y === 34) ? OUTLINE : DOOR;
		}
	}
	return (x === 1 || x === SIZE - 2) ? WALL_DARK : WALL;
}

const canvas = new Canvas(SIZE, SIZE);
canvas.forEach((x, y, c) => {
	const col = paint(x, y);
	if (col) c.setPixel(x, y, col);
});
canvas.writePNG(OUT_FILE);
```

- [ ] **Step 2: Generate and visually check it**

```bash
cd "/c/Users/cedri/Desktop/testashou/game/tools"
node gen_pokecenter.js
mkdir -p "/c/Users/cedri/Desktop/testashou/.debug_output"
node -e "
const { Canvas } = require('./pixelgen.js');
const fs = require('fs');
const zlib = require('zlib');
function decodePNG(buf) {
  let offset = 8; let width, height, idat = [];
  while (offset < buf.length) {
    const len = buf.readUInt32BE(offset);
    const type = buf.toString('ascii', offset+4, offset+8);
    const data = buf.subarray(offset+8, offset+8+len);
    if (type === 'IHDR') { width = data.readUInt32BE(0); height = data.readUInt32BE(4); }
    if (type === 'IDAT') idat.push(data);
    offset += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const out = new Canvas(width, height);
  let pos = 0;
  for (let y=0;y<height;y++){ pos++; for (let x=0;x<width;x++){ out.setPixel(x,y,[raw[pos],raw[pos+1],raw[pos+2],raw[pos+3]]); pos+=4; } }
  return out;
}
function upscale(canvas, factor) {
  const out = new Canvas(canvas.width*factor, canvas.height*factor);
  for (let y=0;y<canvas.height;y++) for (let x=0;x<canvas.width;x++) {
    const px = canvas.getPixel(x,y);
    for (let dy=0;dy<factor;dy++) for (let dx=0;dx<factor;dx++) out.setPixel(x*factor+dx,y*factor+dy,px);
  }
  return out;
}
upscale(decodePNG(fs.readFileSync('../assets/tiles/pokecenter_building.png')), 4).writePNG('C:/Users/cedri/Desktop/testashou/.debug_output/pokecenter_building_4x.png');
"
```

View `C:/Users/cedri/Desktop/testashou/.debug_output/pokecenter_building_4x.png`
with the Read tool. Confirm it reads as a small building: red peaked roof, tan
walls, a darker door centered at the bottom. If the roof triangle or door looks
wrong, adjust the constants in `paint()` and regenerate before moving on — this is
exactly the kind of thing that needs a look, not just a read of the code.

- [ ] **Step 3: Add the obstacle footprint**

In `game/scripts/overworld/overworld_map.gd`, find:

```gdscript
const OBSTACLES := [
	Rect2i(5, 3, 3, 3),
	Rect2i(12, 8, 4, 2),
	Rect2i(20, 12, 5, 4),
]
```

Replace with:

```gdscript
const OBSTACLES := [
	Rect2i(5, 3, 3, 3),
	Rect2i(12, 8, 4, 2),
	Rect2i(20, 12, 5, 4),
	Rect2i(7, 12, 3, 3),  # Pokémon Center footprint — see Task 5 for the building/nurse placement
]
```

- [ ] **Step 4: Verify the map still builds correctly**

This task doesn't place the building sprite yet (that's Task 5), so there's nothing
new to look at visually — this step just confirms the new obstacle rect didn't
break `_paint_map()` (e.g. an out-of-range `Rect2i` throwing at runtime).

Create `game/scripts/overworld/_debug_map_obstacle_check.gd`:

```gdscript
extends Node
## Throwaway harness: confirms the new OBSTACLES rect doesn't break map painting.
## Deleted after verification.

func _ready() -> void:
	for i in range(30):
		await get_tree().process_frame

	var img := get_viewport().get_texture().get_image()
	var big := img.duplicate()
	big.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	var out_dir := "C:/Users/cedri/Desktop/testashou/.debug_output/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	big.save_png(out_dir + "map_obstacle_check_3x.png")
	get_tree().quit()
```

Create `game/scenes/Overworld/_debug_map_obstacle_check.tscn`:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://scenes/Overworld/Main.tscn" id="1_main"]
[ext_resource type="Script" path="res://scripts/overworld/_debug_map_obstacle_check.gd" id="2_script"]

[node name="DebugRoot" type="Node"]
script = ExtResource("2_script")

[node name="Main" parent="." instance=ExtResource("1_main")]
```

Run:

```bash
GODOT="C:/Users/cedri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.1-stable_win64_console.exe"
cd "/c/Users/cedri/Desktop/testashou/game"
"$GODOT" --headless --path . --import
"$GODOT" --path . res://scenes/Overworld/_debug_map_obstacle_check.tscn
```

Expected: no `ERROR:` output. View
`C:/Users/cedri/Desktop/testashou/.debug_output/map_obstacle_check_3x.png` with the
Read tool — confirm grass/trees still paint correctly (the building's obstacle
tiles will just look like ordinary tree-obstacle tiles here since the decorative
sprite isn't placed until Task 5, which is expected, not a bug).

Delete the harness:

```bash
rm game/scenes/Overworld/_debug_map_obstacle_check.tscn game/scripts/overworld/_debug_map_obstacle_check.gd
rm -f game/scenes/Overworld/_debug_map_obstacle_check.tscn.uid game/scripts/overworld/_debug_map_obstacle_check.gd.uid
```

- [ ] **Step 5: Commit**

```bash
git add game/tools/gen_pokecenter.js game/assets/tiles/pokecenter_building.png game/assets/tiles/pokecenter_building.png.import
git add game/scripts/overworld/overworld_map.gd
git commit -m "feat: add the Pokémon Center building sprite and its map obstacle"
```

---

## Task 5: Wire it all into Main.tscn, clean up the demo harness, verify end-to-end

**Files:**
- Modify: `game/scenes/Overworld/Main.tscn`
- Modify: `game/scripts/overworld/main.gd`

**Interfaces:**
- Consumes: `NPC.tscn`/`NPC.setup()` (Task 3), `pokecenter_building.png` (Task 4),
  `GameState.heal_party()` (Task 1), `PlayerController.facing`/`unfreeze()` (Task 2).
- Produces: nothing further downstream — this is the integration task.

Building footprint from Task 4 is tiles (7,12) to (9,14) inclusive (world pixels
(112,192) to (159,239)). Building sprite center: `(136, 216)`. Nurse NPC position
(tile (8,15), just below the footprint, acting as the entrance): `(136, 248)`.

- [ ] **Step 1: Place the building sprite and the nurse NPC in `Main.tscn`**

Open `game/scenes/Overworld/Main.tscn`. Current contents:

```
[gd_scene load_steps=6 format=3]

[ext_resource type="PackedScene" path="res://scenes/Overworld/OverworldMap.tscn" id="1_map"]
[ext_resource type="PackedScene" path="res://scenes/Overworld/Player.tscn" id="2_player"]
[ext_resource type="Script" path="res://scripts/overworld/main.gd" id="3_script"]
[ext_resource type="PackedScene" path="res://scenes/UI/TextBox.tscn" id="4_textbox"]
[ext_resource type="PackedScene" path="res://scenes/UI/MenuList.tscn" id="5_menu"]
[ext_resource type="PackedScene" path="res://scenes/Overworld/EncounterZone.tscn" id="6_encounter"]

[node name="Main" type="Node2D"]
script = ExtResource("3_script")

[node name="OverworldMap" parent="." instance=ExtResource("1_map")]

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(240, 160)

[node name="TextBox" parent="." instance=ExtResource("4_textbox")]

[node name="EncounterZone" parent="." instance=ExtResource("6_encounter")]
position = Vector2(352, 80)

[node name="UILayer" type="CanvasLayer" parent="."]

[node name="MenuList" parent="UILayer" instance=ExtResource("5_menu")]
offset_left = 132.0
offset_top = 56.0
offset_right = 228.0
offset_bottom = 120.0
visible = false
```

Replace it with (adds the `PokeCenterBuilding` sprite, the `NurseNPC` instance, and
two new `ext_resource` entries — `load_steps` bumped from 6 to 8 accordingly):

```
[gd_scene load_steps=8 format=3]

[ext_resource type="PackedScene" path="res://scenes/Overworld/OverworldMap.tscn" id="1_map"]
[ext_resource type="PackedScene" path="res://scenes/Overworld/Player.tscn" id="2_player"]
[ext_resource type="Script" path="res://scripts/overworld/main.gd" id="3_script"]
[ext_resource type="PackedScene" path="res://scenes/UI/TextBox.tscn" id="4_textbox"]
[ext_resource type="PackedScene" path="res://scenes/UI/MenuList.tscn" id="5_menu"]
[ext_resource type="PackedScene" path="res://scenes/Overworld/EncounterZone.tscn" id="6_encounter"]
[ext_resource type="Texture2D" path="res://assets/tiles/pokecenter_building.png" id="7_building_tex"]
[ext_resource type="PackedScene" path="res://scenes/Overworld/NPC.tscn" id="8_nurse"]

[node name="Main" type="Node2D"]
script = ExtResource("3_script")

[node name="OverworldMap" parent="." instance=ExtResource("1_map")]

[node name="PokeCenterBuilding" type="Sprite2D" parent="."]
position = Vector2(136, 216)
texture = ExtResource("7_building_tex")

[node name="NurseNPC" parent="." instance=ExtResource("8_nurse")]
position = Vector2(136, 248)

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(240, 160)

[node name="TextBox" parent="." instance=ExtResource("4_textbox")]

[node name="EncounterZone" parent="." instance=ExtResource("6_encounter")]
position = Vector2(352, 80)

[node name="UILayer" type="CanvasLayer" parent="."]

[node name="MenuList" parent="UILayer" instance=ExtResource("5_menu")]
offset_left = 132.0
offset_top = 56.0
offset_right = 228.0
offset_bottom = 120.0
visible = false
```

- [ ] **Step 2: Replace `main.gd`**

Replace the entire contents of `game/scripts/overworld/main.gd` with (removes the
"Milestone-2 harness" demo — the fake dialogue on `ui_accept` and the debug random
wild-encounter trigger on `ui_cancel`, both of which now conflict with real
interaction; keeps the `F5`/`F9`/`T`/`C` debug hotkeys since those are raw `KEY_*`
checks that don't conflict; wires the nurse NPC to the shared `TextBox`/`MenuList`):

```gdscript
extends Node2D
## Overworld root: wires the shared TextBox/MenuList into each NPC (so they can show
## dialogue without reaching for absolute node paths) and provides debug-only
## hotkeys for save/load and forcing a trainer battle.

@onready var text_box := $TextBox
@onready var menu_list := $UILayer/MenuList
@onready var player := $Player
@onready var nurse_npc := $NurseNPC

func _ready() -> void:
	nurse_npc.setup(text_box, menu_list, player)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F9:
			get_viewport().set_input_as_handled()
			SaveManager.load_game()
		elif event.keycode == KEY_T:
			get_viewport().set_input_as_handled()
			EncounterContext.begin_trainer_battle(load("res://data/trainers/ranger_vale.tres"))
		elif event.keycode == KEY_C:
			get_viewport().set_input_as_handled()
			EncounterContext.begin_trainer_battle(load("res://data/trainers/chat_challenger.tres"))
```

- [ ] **Step 3: Write and run the end-to-end verification harness**

Create `game/scripts/overworld/_debug_e2e_heal.gd`:

```gdscript
extends Node
## Throwaway end-to-end harness: walk to the nurse, interact, confirm heal.
## Deleted after verification.

func _press_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)

func _flush_textbox(line_count: int) -> void:
	for i in range(line_count * 2):
		_press_action("ui_accept")
		await get_tree().create_timer(0.05).timeout

func _ready() -> void:
	GameState.party = [BattleCombatant.new(load("res://data/species/emberkit.tres"), 5, [load("res://data/moves/tackle.tres")])]
	GameState.party[0].apply_damage(25)

	var main = load("res://scenes/Overworld/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	var player = main.get_node("Player")
	player.global_position = Vector2(136, 280)  # a few tiles below the nurse, open ground

	# Walk up toward the nurse (tile (8,15), world ~(136,248)) — the nurse's own
	# collision naturally stops the player at contact distance.
	Input.action_press("ui_up")
	for i in range(40):
		await get_tree().physics_frame
	Input.action_release("ui_up")
	await get_tree().physics_frame

	print("Player position before interact: %s, facing: %s" % [player.global_position, player.facing])

	# Visual check: confirm the building/nurse/player actually read correctly
	# together on screen — the PASS/FAIL below only proves the logic worked.
	var img := get_viewport().get_texture().get_image()
	var big := img.duplicate()
	big.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	var out_dir := "C:/Users/cedri/Desktop/testashou/.debug_output/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	big.save_png(out_dir + "e2e_heal_before_interact_3x.png")

	_press_action("ui_accept")  # talk to the nurse
	await get_tree().create_timer(0.1).timeout
	await _flush_textbox(2)
	await get_tree().create_timer(0.1).timeout
	_press_action("ui_accept")  # confirm "Yes" (default selection index 0)
	await get_tree().create_timer(0.1).timeout
	await _flush_textbox(1)

	if GameState.party[0].current_hp == GameState.party[0].max_hp:
		print("PASS: end-to-end nurse heal worked")
	else:
		print("FAIL: party hp = %d/%d" % [GameState.party[0].current_hp, GameState.party[0].max_hp])
	get_tree().quit()
```

Create `game/scenes/Overworld/_debug_e2e_heal.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/overworld/_debug_e2e_heal.gd" id="1_script"]

[node name="DebugRoot" type="Node"]
script = ExtResource("1_script")
```

Run:

```bash
GODOT="C:/Users/cedri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.1-stable_win64_console.exe"
cd "/c/Users/cedri/Desktop/testashou/game"
"$GODOT" --headless --path . --import
"$GODOT" --path . res://scenes/Overworld/_debug_e2e_heal.tscn
```

Expected: `PASS: end-to-end nurse heal worked`, no `ERROR:`/`FAIL` lines. If it
fails, the printed player position/facing line tells you whether the player didn't
reach the nurse (adjust the starting position or frame count) or reached it but
wasn't detected (check `player.interact_zone.global_position` against the nurse's
`global_position`). Also view
`C:/Users/cedri/Desktop/testashou/.debug_output/e2e_heal_before_interact_3x.png`
with the Read tool to confirm the building/nurse/player actually look right
together — the PASS/FAIL only proves the logic worked, not that the art reads
correctly on screen.

- [ ] **Step 4: Delete the debug harness**

```bash
rm game/scenes/Overworld/_debug_e2e_heal.tscn game/scripts/overworld/_debug_e2e_heal.gd
rm -f game/scenes/Overworld/_debug_e2e_heal.tscn.uid game/scripts/overworld/_debug_e2e_heal.gd.uid
```

- [ ] **Step 5: Full-game sanity boot**

Boot the real game (no scene argument, uses `run/main_scene`) briefly to confirm no
startup errors, same pattern used throughout this project:

```bash
GODOT_WINDOWED="C:/Users/cedri/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.1-stable_win64_console.exe"
cd "/c/Users/cedri/Desktop/testashou/game"
"$GODOT_WINDOWED" --path . &
GPID=$!
sleep 6
kill $GPID
```

Expected: only the known harmless teardown noise on forced kill (`BUG: Unreferenced
static string...`, `RID allocations... leaked at exit` — seen throughout this
project whenever a process is killed instead of calling `get_tree().quit()`), no
scene-load or script-parse errors.

- [ ] **Step 6: Commit**

```bash
git add game/scenes/Overworld/Main.tscn game/scripts/overworld/main.gd
git commit -m "feat: wire the Pokémon Center and nurse into the overworld"
```
