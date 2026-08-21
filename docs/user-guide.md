# Player's Guide (Work-in-Progress Build)

This guide explains everything the game currently does, in plain language — no
programming knowledge needed. This is an early "vertical slice": one small
test area, three creatures, and a handful of moves, built to prove all the
core systems work before more content and artwork get added.

---

## 1. What is this game?

An original, GBA-style monster-battling RPG (in the spirit of games like
Pokémon, but with entirely original creatures, world, and code). You walk
around a small area, run into wild creatures, battle and catch them, fight
a rival trainer, and — the standout feature — you can let **Twitch chat vote
on an opponent trainer's moves** during a battle, so viewers can play against
the streamer in real time.

Eventually this will become a "Nuzlocke" version of the game — a popular
challenge ruleset (if a creature faints, it's gone for good; you can only
catch the first creature you meet in each area; every creature must be
nicknamed). That ruleset isn't turned on yet, but the groundwork for it is
already built in.

---

## 2. How to launch it

Right now the game runs through the Godot game engine rather than as a
standalone `.exe` you can double-click — that packaging step hasn't been done
yet. Ask whoever set this up to start it for you, or if you have the project
open yourself: open it in Godot and press the **Play** button (top-right,
looks like ▶). A window will open showing a small green field with your
character.

---

## 3. Controls

| Key | What it does |
|---|---|
| **Arrow keys** | Walk around |
| **Enter** or **Space** | Talk to someone / confirm a menu choice / advance dialogue text |
| **Escape** | Back out of a menu without choosing (in a battle menu it takes you back a step; at the nurse's question it counts as "No") |
| **↑ / ↓** | Move the selection cursor up/down in any menu |

There are also a few **developer shortcut keys**, since the game doesn't have
a finished title screen, in-world trainers, or a pause menu yet. These are
temporary stand-ins so every feature can be tested without needing the whole
game built out first:

| Key | What it does |
|---|---|
| **F5** | Save your game right now |
| **F9** | Load your last save |
| **T** | Jump straight into a battle against "Ranger Vale," a computer-controlled trainer with two creatures |
| **C** | Jump straight into a battle against "Twitch Chat" — a trainer whose moves are chosen by chat votes (explained in section 10) |

---

## 4. Walking around

You control a small trainer character — green cap, tan shirt. The ground is
textured grass; the leafy tree tiles around the edge of the area and dotted
through the middle are solid, so you can't walk through them. The camera
follows you and won't show past the edge of the test area. All of this is
original pixel art made for this project — early and simple, but real art
rather than placeholder boxes.

Somewhere in the grass is an **encounter zone**, marked by a patch of taller
grass — step into it and stand there for a moment, and there's a chance a wild
creature will jump out and start a battle, the same way tall grass works in
games like this.

There's also a small red-roofed building in the field: that's the **Pokémon
Center**, where you can heal your team for free. See section 8.

The current route is **Frostmeadow Crossing**. Its southern meadow has tall
grass and Mira, the Meadow Scout. A water channel and bridge divide the middle
of the route, where Oren, the Bridge Keeper, is waiting. The northern section
turns snowy and contains Syl, the Snow Ranger. Trees, barriers, flowers, snow,
water, and the bridge are solid or decorative according to their tile type.

---

## 5. Your team

You start with one creature: **Emberkit**, a fire-type. Its stats and moves
scale up as it gains levels (leveling isn't implemented yet as its own
system, but the underlying level number already affects how strong a
creature is in battle).

You can hold up to **10 creatures** at a time. Whichever one in your lineup
isn't fainted comes out first in battle; if it faints, whichever comes next
in your lineup automatically steps in.

### The three creatures that currently exist

| Name | Type | Personality (stat leaning) |
|---|---|---|
| **Emberkit** | Fire | Fast and hits hard, but fragile |
| **Ripplet** | Water | Balanced, tougher defense |
| **Leaflet** | Grass | Slower, but sturdy |

Type match-ups work in a simple three-way rotation, the same shape as
rock-paper-scissors:

**Fire beats Grass → Grass beats Water → Water beats Fire**

A creature using a move of its own type also hits a bit harder ("same-type
attack bonus"), just like the games this is inspired by.

Moves are either **Physical** or **Special**. Physical moves use the user's
Attack against the target's Defense. Special moves use Special Attack against
Special Defense. The move-selection screen shows each move's category in
brackets, and the Pokemon team view shows both pairs of stats.

After winning a battle, every creature that was sent out during that fight earns
experience. Creatures that stayed in the lineup but were never sent out do not
receive experience. Experience is awarded after the victory message, and a level
up immediately recalculates the creature's HP, Attack, Defense, and Speed.
---

## 6. Battling

Battles are turn-based. Each round:

1. You pick an action from a menu (explained below).
2. The opponent picks theirs (either a computer opponent, or Twitch chat —
   see section 10).
3. Whichever creature is faster acts first.
4. Damage is calculated based on the move's power, the attacker's stats, and
   the type match-up (see section 5) — you'll see "**It's super effective!**"
   or "**It's not very effective...**" messages when the type match-up
   matters.
5. If a creature's HP hits 0, it faints. If that empties one side's whole
   team, the battle ends. Damage carries over into the next battle — see
   section 8 for how to heal up.

### Your battle menu

- **Fight** — opens a list of your active creature's moves. Pick one to use it.
- **Catch** — only appears against *wild* creatures, never against a trainer
  (you can't catch someone else's creature!). Throws a ball; see section 7
  for the odds.
- **Run** — only appears against *wild* creatures. Trainer battles can't be
  fled from, same as the classic games.

Pressing **Escape** in a battle menu backs you out one step: from the move list
it returns you to Fight/Catch/Run, and from that top menu it simply re-opens it,
since somebody has to take a turn.

Text messages during battle (like "Emberkit used Ember!") play out at a
typewriter speed — press Enter/Space to skip ahead if you don't want to wait,
or to advance to the next line once one finishes.

---

## 7. Catching wild creatures

When you choose **Catch**, the game rolls the odds based on two things:

  it is to catch. Full-health creatures are quite hard to catch; a creature
  down to a sliver of HP is much more likely to succeed.
  easier or harder to catch than others (this is set per-species; right now
  all three starter-style creatures use the same middling rate).

If the catch fails, you'll see "Oh no! It broke free!" and the wild creature
gets to attack you before your next turn. If it succeeds, that creature joins
your team immediately (as long as you have a free slot out of your 10).

Your bag starts with 100 Pokeballs, 100 Superballs, and 100 Hyperballs. When you
choose **Catch** in battle, a second menu lists the ball types you currently
have and their counts. Choose the ball you want to throw; Escape returns to the
main battle menu. One ball is consumed on every throw, whether the attempt
succeeds or fails. The Bag screen in the Start Menu shows the remaining counts.
Ball strength and the improved catch-rate tuning make weakened wild creatures
substantially easier to catch.

---

## 8. Healing up: the Pokémon Center

Damage sticks around after a battle — winning a fight doesn't patch your team
back up. There are two ways to get your creatures back to full HP.

**The Pokémon Center.** The red-roofed building in the field has a **nurse**
standing in front of it — white cap with a red cross, white dress. Walk up to
her so you're facing her, then press **Enter** or **Space** (the same button
you use to advance dialogue and confirm menu choices). She'll greet you and
ask whether you'd like her to heal your party:

Open the overworld Start Menu with **Enter**, choose **Pokemon**, and the team
view shows a compact selectable roster. Choose a creature with the arrow keys
and Enter, or click its row, to open its detail view with level, current/max HP,
experience progress, Attack, Defense, Special Attack, Special Defense, Speed,
and moves.
- Choose **Yes** and your whole team is restored to full HP immediately, free,
  as many times as you like.
- Choose **No** (or press **Escape** to back out — it counts the same as "No")
  and she'll wave you off; nothing changes.

**Losing a battle.** If every creature on your team faints, you lose the battle
and get sent back to the overworld — and your party is automatically healed on
the way out. So losing isn't a dead end: you can't get permanently stuck with
a team that can't fight. (This is a stand-in for the classic "you black out and
wake up at the last Center" rule; there's no fainting-costs-you-money penalty
yet.) Note the healing only happens on a *loss* — after a win you keep whatever
damage you took, which is exactly what the Center is there for.

---

## 9. Trainer battles

Unlike wild encounters, trainer battles are against an opponent with a full
lineup of creatures (right now, two). When one of their creatures faints,
they send out the next one automatically, with a message announcing it —
there's no running away and no catching involved.

Right now there's one trainer to fight this way, "**Ranger Vale**" (triggered
with the **T** key), who battles you with a Ripplet and a Leaflet. This
stands in for what will eventually be real trainer characters you meet by
walking up to them in the world.

---

## 10. The Twitch chat feature

This is the headline feature: instead of a computer deciding the opponent
trainer's moves, **the moves can be decided by a live Twitch chat vote** —
so if a streamer is playing, their viewers can control the opposing trainer
in real time.

Here's exactly how it works:

1. When it's the chat-controlled trainer's turn to act, the game shows a
   countdown on screen listing the move options, like:
   `!1 Tackle  !2 Water Jet  (8s)`
2. For **10 seconds**, anyone in the connected Twitch channel's chat can type
   `!1`, `!2`, `!3`, or `!4` to vote for that move.
3. Each person's **most recent** message counts (so you can change your
   vote), and it's one vote per person.
4. Whichever move gets the **most votes** wins. If it's a tie, whichever
   option got voted for *first* wins the tie.
5. When the timer runs out, that move gets used — and you'll see the normal
   battle message play out ("Twitch Chat's Ripplet used Water Jet!").

**Important honesty note:** this only works while the game is actually
connected to a live Twitch channel's chat, and that connection isn't wired
up to a real streamer's channel yet by default (right now it's only ever
been pointed at test channels while building the feature). If nobody's
chat is connected, or nobody votes in time, the game **never gets stuck
waiting** — it automatically falls back to the same computer-controlled
decision-making a normal trainer uses, so the game is always fully playable
solo.

**Also worth knowing:** this Twitch feature only works because the game runs
on a computer with an internet connection. It's not something that could
ever work if this game were turned into a real Game Boy Advance cartridge —
real GBA hardware can't get online. That trade-off was made on purpose so
this feature could exist at all.

---

## 11. Saving and loading

Press **F5** at any time in the overworld to save. Press **F9** to load your
last save. Your save keeps track of:

- Every creature in your team (species, level, current HP, nickname if it
  has one)
- That's it, for now — your position in the world and any story progress
  aren't saved yet, since there isn't really a "world" with progress to
  track yet beyond the one test area.

There's no in-game menu for this yet (no pause screen), which is why it's
tied to a direct key press for now.

---

## 12. What's *not* built yet (so you know what to expect)

Being upfront about the current limitations:

- **Early art, and no sound at all** — there are now real pixel-art sprites for
  the player, the nurse, all three creatures, the map tiles, the Pokémon Center
  and the battle backdrop, plus a proper themed menu/dialogue style. It's a
  first pass, though: nothing is animated, the characters don't turn to face the
  way they're walking, and there is no music or sound effects yet.
- **No Nuzlocke rules active yet** — permadeath, one-catch-per-area, and
  mandatory nicknames are all planned but switched off for now.
- **No trainer NPCs in the world yet** — the nurse is the only character you
  can walk up to and talk to. Trainer battles are still triggered by developer
  shortcut keys (T and C) instead of by meeting someone in the world.
- **No title screen or pause menu** — the game boots straight into the
  playable area.
- **Only one small test area, three creatures, two trainers, and four moves**
  exist so far — enough to prove every system works, not a full game's
  worth of content yet.
- **No standalone installer/.exe** — it currently has to be launched through
  the Godot engine.

None of these are things that don't work — they're simply not built yet, in
roughly the order they'll be tackled next.
