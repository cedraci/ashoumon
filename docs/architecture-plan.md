# Architecture Plan — Original GBA-styled RPG (Godot) with Twitch-controlled trainers

*Supersedes the earlier GBA-homebrew (Butano/mGBA) version of this plan. Pivoted to a modern
engine after confirming the memory-budget tradeoff wasn't worth it for this project — the whole
point of "GBA-styled" here is the look and feel, not literal `.gba` hardware compatibility.*

## Context

Goal: an original creature-battling RPG (own creatures/region/code, not derived from Nintendo),
styled after Pokémon Emerald, as a step toward a Nuzlocke-ruleset game. It should run in an
emulator-like/PC context where **Twitch chat can control an opposing trainer's moves** — chatters
vote on the opponent's actions while the streamer plays the protagonist.

Decisions locked in:
- **Engine: Godot 4.x, GDScript.** Exports to Windows/Mac/Linux (and optionally HTML5). Chosen
  over Unity (heavier, closed runtime) and RPG Maker (fast but awkward to bolt a live chat-driven
  battle AI onto).
- **Scope: vertical slice first** — small original region, ~20-40 original creatures, one full
  overworld → wild encounter → battle → catch → save loop, plus one big trainer fight — before
  scaling content. Nuzlocke rules (permadeath, one catch per area, mandatory nicknames) get layered
  onto this working loop later, not designed in yet but hooks are reserved.
- **Twitch integration is now dramatically simpler than the GBA-homebrew version.** That version
  needed a whole cross-process bridge (Node.js + mGBA Lua scripting + a memory-mailbox protocol)
  because a compiled GBA ROM has no network access and can't be reached except by an emulator
  poking its RAM from outside. Godot is a normal PC application with a built-in WebSocket client,
  so **the game itself connects directly to Twitch chat** — no bridge process, no IPC protocol, no
  emulator scripting. This removes an entire subsystem from the plan.

## 1. Presentation: keeping the GBA look

- Design resolution **240×160** (native GBA), `Viewport` stretch mode `viewport` + aspect
  `keep`/integer scaling, nearest-neighbor texture filtering — crisp pixel-art scaling (2x/3x/4x
  window sizes) with no blur.
- 4bpp-style limited palettes per sprite sheet are an *art-direction choice* now, not a hardware
  requirement — worth keeping for authenticity but not load-bearing for engineering decisions.
- Tile-based overworld via Godot's built-in `TileMap`/`TileSet` (replaces the GBA plan's
  Tiled-authored `.tmx` + custom import step — Godot's tilemap editor is used directly, no
  conversion pipeline needed).

## 2. Project structure (single Godot project, no separate bridge/)

```
game/                          # Godot project root (res://)
  project.godot
  scenes/
    Overworld/                 # Map scenes, Player.tscn, NPC.tscn
    Battle/                    # Battle.tscn + battle UI
    UI/                        # TextBox, MenuList, HUD, vote-countdown widget
  scripts/
    autoload/                  # Singletons: GameState, SaveManager, TwitchChatClient, SceneRouter
    battle/                    # BattleState, DamageCalc, TypeChart, StatusEffects, CatchMechanic,
                                # TrainerController (base), ScriptedAIController, ExternalChatController
    overworld/                 # PlayerController, NpcController, EncounterZone
    data/                      # Resource script defs: Species.gd, Move.gd, Trainer.gd (Godot Resource classes)
  data/
    species/*.tres  moves/*.tres  trainers/*.tres     # authored as Godot Resources (Inspector-editable)
    type_chart.json
  assets/
    sprites/  tiles/  audio/
  docs/
    architecture-plan.md (this file)
    twitch_integration.md
    milestones.md
```

Content is authored as **Godot `Resource` (.tres) files** — editable in the Godot Inspector like
any other engine object, version-control-friendly (text format), and loaded natively with zero
custom parsing code. This replaces the CSV+codegen pipeline from the GBA plan, which existed only
because the GBA has no filesystem or resource loader — Godot has both built in.

## 3. Core architecture

- **Autoload singletons** (Godot's global-script mechanism): `GameState` (current party, flags,
  position), `SaveManager` (JSON to `user://save.json` via `FileAccess` — a real filesystem, so no
  SRAM-layout engineering needed), `SceneRouter` (swap Overworld ↔ Battle, push/pop Menu/Dialogue
  overlays), `TwitchChatClient` (see §4).
- **Battle turn loop**: `BattleState` node drives turns; each side has a `TrainerController`
  (base class with `func get_action(context) -> BattleAction` — now just a normal
  **async/`await`-able function**, since Godot doesn't need non-blocking polling the way a GBA
  frame loop did). `ScriptedAIController` picks immediately; `ExternalChatController` awaits a
  signal from `TwitchChatClient` with a timeout via `get_tree().create_timer()`, falling back to a
  composed `ScriptedAIController` if the timeout fires first. Same fallback guarantee as the GBA
  design (game is fully playable with no Twitch connection), just expressed as async/await instead
  of a polled memory mailbox.
- **Damage/combat math, type chart, catch formula**: same simplified Gen-3-style approach as
  before (damage formula, small 6-8 type original chart, catch-rate roll) — this logic doesn't
  change with the engine swap, just its implementation language (GDScript instead of C++).
- **Nuzlocke hooks reserved now**: `permanently_fainted: bool` field on party member data,
  no-op `require_nickname()` call site in the catch flow, `already_resolved` dict per
  `EncounterZone` id in save data. Same rationale as before — free now, avoids a save-format
  migration later.

## 4. Twitch integration (now a single in-game system, not a bridge)

`TwitchChatClient` (autoload, GDScript `WebSocketPeer`):
- Connects to `wss://irc-ws.chat.twitch.tv:443` using an **anonymous justinfan login**
  (`PASS SCHMOOPIIE` / `NICK justinfan12345` — Twitch's documented anonymous-read convention, no
  OAuth/bot account needed for read-only chat).
- Sends `JOIN #<channel>`, parses incoming `PRIVMSG #<channel> :<message>` lines each `_process`
  tick via `WebSocketPeer.poll()` + `get_packet()`.
- On `BattleState` entering "awaiting external trainer action," it calls
  `TwitchChatClient.start_vote(choices, duration_sec)`, which tallies `!1`-`!4` messages for a
  fixed window (**10s, majority vote, ties broken by first-received**, one vote per chat user per
  window — same scheme as the original design, still the right one) and emits a `vote_resolved`
  signal the `ExternalChatController` awaits.
- Reconnect-with-backoff on disconnect; if not connected at all, `start_vote` should resolve
  immediately to "no votes" so the timeout/fallback path still works — the game is never blocked
  waiting on Twitch.
- Optional later add-on: a tiny local HTTP endpoint (Godot can serve one) showing live vote tally
  for an OBS browser-source overlay.

No separate Node.js process, no emulator Lua scripting, no memory-mailbox protocol — the entire
"external-control hook" from the GBA plan collapses into one autoloaded script plus a signal.

## 5. Milestones (each independently playable/testable)

0. **Project bring-up** — empty Godot project, 240×160 viewport scaled correctly, one static
   sprite on screen, exported and run standalone.
1. **Overworld movement + collision** — one hand-built `TileMap`, player moves with 4-dir
   collision, camera follows.
2. **Menu/text/dialogue system** — text box with typewriter effect, list menu (reused for
   battle move-select and party/bag menus).
3. **Battle core loop vs scripted AI** — debug-triggered battle, both sides use
   `ScriptedAIController`, damage calc, fainting, return to overworld.
4. **Wild encounters + catching** — `EncounterZone` trigger, wild battle, catch mechanic, caught
   creature added to party.
5. **Save/load** — `SaveManager` persists party/position/flags to `user://save.json`, loads on
   boot, versioned schema field for future migration.
6. **Trainer battle content** — one full "gym-equivalent" multi-creature trainer, exercising the
   whole slice end-to-end offline.
7. **TwitchChatClient online** — connect to a real (even empty/test) channel, confirm
   join/parse/vote-tally works standalone with a debug overlay, independent of battle wiring.
8. **ExternalChatController wired into battle** — run the milestone-6 trainer with
   `controller_type = EXTERNAL_CHAT`, verify chat votes drive moves with on-screen countdown, and
   verify graceful fallback to AI when chat is silent or disconnected.

## 6. Risks / constraints (updated for the pivot)

- **This is no longer a `.gba` ROM.** It won't run in mGBA or on real GBA hardware — it's a native
  PC (and optionally web) executable that merely looks/plays like a GBA game. Worth being explicit
  about since the original ask was specifically GBA/emulator; this trade was made deliberately to
  avoid the 256KB EWRAM ceiling and the whole mailbox/bridge complexity.
- **Original assets required either way**: sprites, tiles, and audio must be original (or
  properly licensed) — the engine swap doesn't change the IP situation, only the technical
  constraints.
- **Twitch anonymous IRC** has its own rate limits and occasional connection resets — the
  reconnect/backoff behavior in `TwitchChatClient` isn't optional polish, it's what keeps the game
  from hanging if Twitch's edge drops the socket mid-battle.
- **Chat input stays a tiny whitelist** (`!1`-`!4`), one vote per user per window — same
  abuse-resistance posture as before, just enforced in GDScript instead of Node.js.
- **Godot version drift**: pin a specific Godot 4.x version for the project once created, since
  WebSocket/TileMap APIs have shifted across 4.x minor versions.

## Critical files (build roughly in this order)

- `game/scripts/battle/trainer_controller.gd` — base class both AI and chat controllers implement.
- `game/scripts/autoload/twitch_chat_client.gd` — the entire Twitch integration surface.
- `game/scripts/battle/external_chat_controller.gd` — awaits `twitch_chat_client`'s vote signal,
  falls back to composed `ScriptedAIController` on timeout.
- `game/scripts/autoload/save_manager.gd` — JSON save/load, versioned schema.
- `docs/twitch_integration.md` — document the justinfan anonymous-login convention, vote scheme,
  and timeout/fallback contract so it isn't lost later.
