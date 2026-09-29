# Laurel & Loom — Design Document

> *Fortune is a thread. Read it, cut it, turn it.*

A grid-based tactical RPG for PC, built in Godot 4. Neoclassical in look and temper: marble,
laurel, gold leaf, Roman capitals, cameo portraits. Its direct inspiration is
*Fire Emblem: Fortune's Weave*; its own idea is that **fortune is visible**.

---

## 1. The pitch

Every tactics game rolls dice you never see. *Laurel & Loom* lays the dice out on the table.

Across the top of the screen runs **the Measured Thread** — a row of numbered beads, the
next rolls fate will make. Every strike in the battle, yours or the enemy's, takes the
bead at the front. Low beads are fortunate: a bead at or under your hit chance hits, and at
or under your crit chance it crits. So the order you act in matters as much as where you
stand. Spend the lucky 7 on the killing blow; let the 94 fall to the enemy archer.

And because the heroine is an Augur, she can reach into the thread: **cut** a bead away,
**turn** it over (a 94 becomes a 7), or **measure** further ahead — paid for with
**Fortune**, a gauge that only fills when luck goes against you.

## 2. What we take from *Fortune's Weave*, and what we change

| *Fortune's Weave* | *Laurel & Loom* |
|---|---|
| Grid tactics: move, act, counter, follow-up | Same foundation — it's the genre's grammar |
| No weapon triangle; each weapon type has its own mechanic (e.g. axes never deal under 5, bows can't counter up close) | Same philosophy, different verbs — see §7: swords quicken, spears brace, axes **shove**, bows **steady**, hymns **resonate** |
| Blaze Arts: signature moves paid in HP, with a gauge that punishes overuse | **Fate Arts** paid in Fortune, a gauge that fills from *misfortune* — the wheel turns (§5). HP-cost **Oaths** are planned for Stage 6 |
| Fortuna's Blessing: rewind turns | **Unravel**: undo your last action, three times per battle (§5.5) |
| Four Flame Lords, four routes through the same war | Planned: **Three Oaths**, three routes (Stage 7) |
| Time passes as you visit towns and explore | Planned: **the Forum** hub, where days pass between battles (Stage 6) |

We are not recreating *Fortune's Weave*. We borrow its structure and its taste for weapons
that each play differently, and build our own mechanic on top.

## 3. Pillars

1. **Fortune you can read.** No hidden dice. Every random outcome comes from a bead you could
   have seen coming. The skill is in sequencing, not hoping.
2. **Marble and measure.** Neoclassical restraint: symmetry, clarity, calm surfaces, one
   accent colour at a time. Nothing on screen should need squinting at.
3. **Every weapon a verb.** A weapon type is a way of playing, not a stat block.

## 4. Setting

**The Heptapolis** — a concord of seven marble cities, in an age of academies and republics
raised on the ruins of an older empire. Their Senate meets under a bronze loom said to have
belonged to the Moirai, the three Fates: Clotho who spins the thread, Lachesis who measures
it, Atropos who cuts it.

**Consul Varro Aurex** has dissolved the Senate and taken the **Distaff of Clotho** from the
Temple of the Moirai. With it, he can spin fortune for his legions.

**Ione Vell**, a junior Augur of the Academy, can read the Measured Thread — a little way
ahead, never far. On the night of the coup her teacher presses the **Shears of Atropos**
into her hands. She escapes the Academy with a handful of companions sworn to restore the
Senate.

### Cast (first act)

| Name | Class | Weapon | Role |
|---|---|---|---|
| **Ione Vell** | Augur *(lord)* | Gladius | Reads the thread; the battle is lost if she falls |
| **Cassian Duro** | Hastatus | Hasta / Pilum | Steady front line, reach with the pilum |
| **Dama Rhue** | Sagittaria | Arcus | Archer; deadly when she holds still |
| **Oren Tace** | Lictor | Securis | Axe-bearer of the fasces; shoves the line open |
| **Selene Amar** | Vestal | Caduceus / Ode | Healer, a little hymn-magic |
| **Mirelle Anthe** | Eques | Hasta | Mounted; joins in Chapter II |
| **Theron Kale** | Orator | Ode / Elegy | Hymn-mage; joins in Chapter III |

**Antagonists:** Aurex's Praetorians — Legionaries, Hoplites, Lictors, Archers, Equites,
Hymnists — led in the first act by **Centurion Bassa**.

## 5. The Measured Thread

### 5.1 Beads
- A bead is a whole number from **1 to 100**. The thread is a seeded, deterministic stream:
  the same battle with the same choices always gives the same beads.
- **Every strike takes the front bead** — player and enemy strikes, initiations and
  counters and follow-ups alike. Healing takes no bead.
- A strike with shown Hit *H* and Crit *C* that draws bead *b*:
  - *b* > *H* → **miss**
  - *b* ≤ *C* → **critical** (×3 damage)
  - otherwise → **hit**

### 5.2 What you can see
- The first **3** beads are shown exactly.
- The next **3** are shown only as **omens**: *fair* (1–33), *middling* (34–66) or
  *ill* (67–100).
- Beyond that, nothing.

### 5.3 The forecast
Because beads are visible, the combat forecast shows the *actual* outcome of every strike
whose outcome is already fixed, and "?" for the rest. A strike's outcome is fixed when every
bead it could draw gives the same result: always for an exact bead, often for an omen (a
*fair* bead against 90 Hit is a hit whatever its number), and even for an unseen bead at 0 or
100 Hit. The forecast accounts for strikes that won't happen (a unit that dies doesn't
counter), and the thread bar highlights the beads the fight would draw, in the colour of the
side that draws each one.

### 5.4 Fortune and the Fate Arts
**Fortune** is a gauge of 0–6, starting at 2. It fills from *misfortune*:
- +1 when one of your strikes misses
- +1 when one of your units takes a critical hit
- +1 at the start of each of your phases after the first

While Ione lives, you can spend Fortune during your phase — including mid-forecast, which
updates live:

| Art | Cost | Effect |
|---|---|---|
| **Measure** *(Lachesis)* | 1 | Every visible bead shows exactly until your phase ends |
| **Cut** *(Atropos)* | 2 | Discard the front bead |
| **Turn** *(Rota Fortunae)* | 3 | Invert the front bead: *b* → 101 − *b* |

Turn is the expensive one because it is the only art that can manufacture luck.

### 5.5 Unravel
Three times a battle, undo your last committed action (a move-and-act, or a Fate Art). The
thread, Fortune, positions and HP all roll back. Unravel exists so a mis-click never costs
a run; its tight budget keeps it from replacing thought.

### 5.6 Why this is interesting
The enemy draws from the same thread. What you leave at the front at the end of your phase
is what the first enemy attack gets. A good turn *spends* the good beads and *leaves* the bad
ones — or cuts them.

## 6. Combat math

| Quantity | Formula |
|---|---|
| Attack | Str (or Mag for hymns and staves) + Might × effectiveness (×2 when effective) |
| Damage | max(0, Attack − Def (or Res) − terrain Def) |
| Hit | clamp(weapon Hit + Skl×2 + Lck/2 − (foe Spd×2 + foe Lck + terrain Avoid), 0, 100) |
| Crit | clamp(weapon Crit + Skl/2 − foe Lck, 0, 100) |
| Follow-up | Attack Speed (Spd) ≥ foe's + 4 (+3 for swords) |
| Order | attacker, defender's counter, then whichever side doubles |
| Critical | ×3 damage |

Integer division throughout. Counters happen if the defender has a weapon that reaches the
distance.

## 7. Weapons

No triangle. Each type has one trait you can plan around.

| Type | Examples | Range | Trait |
|---|---|---|---|
| **Sword** | Gladius, Spatha | 1 | **Tempo** — follows up at +3 Spd instead of +4 |
| **Spear** | Hasta, Pilum (1–2) | 1 / 1–2 | **Brace** — effective against cavalry |
| **Axe** | Securis | 1 | **Shove** — when you initiate and land a hit, a surviving foe is pushed back one tile |
| **Bow** | Arcus | 2 | **Steady** — +15 Hit if the archer hasn't moved this turn; effective against fliers |
| **Hymn** | Ode, Elegy | 1–2 | **Resonance** — ignores terrain Avoid and Def |
| **Staff** | Caduceus | 1 | Heals Mag + 10; takes no bead |

## 8. Classes

| Class | Move | Type | Weapons | Notes |
|---|---|---|---|---|
| Augur | 5 | Foot | Sword | Ione only; lord |
| Hastatus | 5 | Foot | Spear | High Def |
| Sagittaria | 5 | Foot | Bow | |
| Lictor | 5 | Foot | Axe | High HP/Str, low Skl |
| Vestal | 5 | Foot | Staff, Hymn | Healer |
| Orator | 5 | Foot | Hymn | Mage |
| Eques | 7 | Cavalry | Spear, Sword | Rough terrain costs more |
| Legionary | 5 | Foot | Sword | Enemy |
| Hoplite | 4 | Armor | Spear | Enemy; very high Def, low Res |
| Hymnist | 5 | Foot | Hymn | Enemy mage |
| Centurion | 5 | Armor | Sword/Spear | Boss |

## 9. Terrain

| Tile | Foot | Armor | Cav. | Avoid | Def | Notes |
|---|---|---|---|---|---|---|
| Plaza (marble) | 1 | 1 | 1 | 0 | 0 | |
| Meadow | 1 | 1 | 1 | 0 | 0 | |
| Road | 1 | 1 | 1 | 0 | 0 | |
| Olive grove | 2 | 3 | 3 | 20 | 1 | |
| Colonnade | 2 | 2 | — | 20 | 1 | Cavalry can't pass |
| Rubble | 2 | 2 | 3 | 10 | 0 | |
| Stairs | 1 | 1 | 2 | 0 | 0 | |
| Altar | 1 | 1 | 1 | 20 | 2 | Heals 20% HP at the start of the occupant's phase |
| Gate | 1 | 1 | 1 | 10 | 1 | Seize point |
| Bridge | 1 | 1 | 1 | 0 | 0 | |
| Pool / river | — | — | — | | | Impassable (fliers excepted) |
| Wall | — | — | — | | | Impassable |

## 10. Objectives

- **Rout** — defeat every enemy.
- **Seize** — Ione ends a move on the marked tile and chooses Seize.
- **Survive** — hold out until the end of turn *N*.
- **Defeat commander** — defeat the named boss.

Always: the battle is lost if Ione falls.

## 11. Enemy behaviour

Enemies don't read the thread (Aurex's Distaff is a story beat for later, when they will).
Each enemy has a disposition:
- **Charge** — moves toward the nearest reachable foe every turn.
- **Guard** — attacks anything it can reach this turn, otherwise holds.
- **Hold** — never moves; attacks what's already in range.

Target choice scores expected damage, kill chance, counter-damage taken, and a bonus for
striking the lord or a wounded unit. Among tiles it could attack from, it prefers higher
terrain Avoid/Def.

## 12. Controls (PC)

| Action | Keyboard | Mouse |
|---|---|---|
| Move cursor | Arrows / WASD | Hover |
| Confirm | Z / Enter / Space | Left click |
| Cancel | X / Esc / Backspace | Right click |
| Next ready unit | Tab | |
| Show all enemy ranges | R | |
| Measure / Cut / Turn | M / C / T | Buttons on the thread bar |
| Unravel | U / Ctrl+Z | Button |
| End turn | E | Map menu |

Controller support is planned for Stage 7.

## 13. Architecture

- **Engine:** Godot 4.7 (GDScript, typed). Compatibility renderer for the widest PC support.
- **Core/presentation split.** Everything under `src/core/` is plain `RefCounted` logic with
  no nodes — the grid, pathfinding, combat, the thread, battle state, AI. The battle scene
  asks the core what happens and then animates it. This is what makes the rules testable
  headlessly and makes Unravel a matter of snapshotting state.
- **Data as code.** Units, classes, weapons, terrain and chapters are GDScript dictionaries
  under `src/data/`, with maps drawn in ASCII — readable diffs, no editor-only resources.
- **Art is code, too.** Tiles and cameo portraits are drawn procedurally with `_draw()`, so
  the project has no binary art to manage at this stage. Fonts are OFL (Cinzel, Cormorant
  Garamond).
- **Tests.** A small headless test runner (`tests/run_tests.gd`) covers the rules and runs
  full AI-vs-AI battles to make sure every chapter terminates cleanly.

## 14. Risks and open questions

| Risk | Mitigation |
|---|---|
| Visible beads make the game too solvable | Only 3 exact beads; omens beyond; enemy count and stats tuned against a perfect-information player. Revisit after playtests |
| Bead-order planning is a lot to hold in your head | The forecast does the arithmetic; the thread bar marks which beads the current forecast would consume |
| Procedural art reads as placeholder | Art direction commits to a *style* (cameos, frieze UI) that suits vector drawing; a painted-art pass is Stage 7 |
| Scope creep toward the full *Fortune's Weave* feature set | The roadmap holds everything past the first act behind explicit stages |
