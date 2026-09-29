# Laurel & Loom

*Fortune is a thread. Read it, cut it, turn it.*

A neoclassical tactical RPG for PC, built in **Godot 4**, inspired by
*Fire Emblem: Fortune's Weave*. Grid battles in marble plazas and olive groves, units drawn as
Wedgwood and black-figure cameos — and one idea of its own: **the dice are visible**. Every
strike takes the next bead from the Measured Thread across the top of the screen, and the
heroine, an Augur, can cut a bead away or turn it over.

<img src="docs/images/forecast.png" width="720" alt="A battle in the Academy courtyard. Across the top, the Measured Thread: beads numbered 55, 20 and 64, then three coloured omens and two blank beads. The forecast panel shows Ione attacking a Legionary: her strike draws 55 and hits for 7, his counter draws 20 and hits for 6, her follow-up draws 64 and hits for 7.">

- [Design document](docs/DESIGN.md) — the mechanic, the maths, the cast
- [Art direction](docs/ART_DIRECTION.md) — palette, type, cameos, frieze UI
- [Roadmap](docs/ROADMAP.md) — the stages and what each one must prove

## Status

Built in stages; see the [roadmap](docs/ROADMAP.md) for where it stands.

## Screenshots

| | |
|---|---|
| <img src="docs/images/title.png" width="420" alt="Title screen: LAUREL & LOOM over a faint Ionic temple front, a gold thread with numbered beads strung across the columns, and a Begin/Quit menu."> | <img src="docs/images/measured-thread.png" width="420" alt="The thread after Measure: all six visible beads show their numbers. Turn has just flipped the front bead from 55 to 46."> |
| **Title** — a hexastyle temple drawn in code, the thread across its capitals | **Measure and Turn** — every visible bead exact; the front bead turned over |
| <img src="docs/images/danger-zone.png" width="420" alt="The danger zone: every tile an enemy could strike next phase, outlined in Pompeian red, inside a gold meander frame."> | <img src="docs/images/enemy-phase.png" width="420" alt="The enemy phase: a Legionary's strike misses Cassian and the bead it drew drops from the thread."> |
| **Danger zone** — everything the enemy can reach next phase | **Enemy phase** — their strikes spend the same thread |

## Running it

1. Install [Godot 4.7](https://godotengine.org/download) (standard build, not .NET).
2. Open `game/project.godot` in the editor and press **F5**, or from a terminal:
   `godot --path game`

Controls: arrows/WASD or the mouse to move the cursor; **Z**/Enter/left-click to confirm;
**X**/Esc/right-click to cancel; **Tab** next unit; **R** danger zone; **E** end turn.

## Tests

```sh
GODOT=/path/to/godot game/tools/run_tests.sh                   # rules: pathfinding, combat, thread, AI, chapters
godot --headless --path game res://tools/smoke.tscn          # plays every chapter through the real battle scene
```

The rules live in `game/src/core/` as plain objects with no scene nodes, so they test
headlessly; the smoke run drives the actual battle controller, AI on both sides, until
each chapter ends.
