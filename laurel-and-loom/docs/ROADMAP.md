# Laurel & Loom — Roadmap

The game is built in stages. Each stage ends with something playable and a set of acceptance
criteria that are checked before the next stage starts. Stages 0–4 make up the **first act**;
5–7 are planned, not built.

| Stage | Name | Status |
|---|---|---|
| 0 | The Plan | Done |
| 1 | The Board | Next |
| 2 | The Thread | Planned |
| 3 | Marble & Lyre | Planned |
| 4 | The First Act | Planned |
| 5 | The Distaff | Planned |
| 6 | The Forum | Planned |
| 7 | Three Oaths | Planned |

---

## Stage 0 — The Plan
Design document, art direction, this roadmap.

**Accept when:** the core mechanic, combat maths, weapon traits, cast, and staging are
written down precisely enough to build from.

## Stage 1 — The Board
The genre's grammar, with nothing novel yet.
- Godot project; the core/presentation split; headless test runner
- ASCII maps, terrain costs by movement type, Dijkstra movement ranges, attack ranges
- Units, classes, weapons as data
- Cursor (keys and mouse), select → move → act → wait, cancel back out
- Combat forecast and resolution, counters, follow-ups, death
- Enemy phase with Charge / Guard / Hold dispositions
- Rout objective, victory and defeat

**Accept when:** a battle can be played to victory or defeat with mouse or keyboard;
pathfinding, combat maths and AI are covered by tests; an AI-vs-AI battle always ends.

## Stage 2 — The Thread
The idea the game is built around.
- Seeded, deterministic bead stream; every strike consumes the front bead
- Exact and omen windows on the thread bar
- Forecast shows each strike's bead and outcome, and highlights the beads it would consume
- Fortune gauge and its three triggers; Measure, Cut and Turn
- Weapon traits: Tempo, Brace, Shove, Steady, Resonance
- Unravel (three per battle) via state snapshots

**Accept when:** the forecast always agrees with the resolved combat (tested across many
seeds); Fate Arts, Fortune and Unravel behave as specified; replaying the same choices on
the same seed produces the same battle.

## Stage 3 — Marble & Lyre
Make it look and sound like itself.
- Cinzel and Cormorant Garamond; a shared theme
- Procedural tiles and cameo portraits per the art direction
- Meander-framed panels, the frieze phase banner, the thread bar as loom weights
- Lunge / damage / crit / death animations; danger-zone overlay
- Generated lyre sound effects
- Title screen

**Accept when:** screenshots of the title, the board, a forecast and the enemy phase read
as one coherent neoclassical style; nothing is drawn with engine-default fonts.

## Stage 4 — The First Act
A short, complete campaign.
- Prologue and three chapters, with Rout, Seize, Survive and Defeat-commander objectives
- Dialogue scenes staged as friezes before and after battles
- EXP, growth-rate level-ups, a roster that carries between chapters
- Save and load between chapters; settings (fullscreen, volume, animation speed)
- Windows and Linux export presets

**Accept when:** the act can be played start to finish; every chapter is covered by an
AI-vs-AI termination test; saves round-trip.

---

## Stage 5 — The Distaff *(planned)*
Aurex's commanders read the thread too. Commanders get their own Fate Arts; the Distaff
lets them **spin** new beads into the thread. Fliers (Gryphon riders) arrive, so bows'
effectiveness matters. Weapon durability or a lighter alternative, decided by playtest.

## Stage 6 — The Forum *(planned)*
A hub between battles, in the spirit of *Fortune's Weave*'s towns and passing time: days
pass as you visit the market, the baths, the library. Supports between companions
(adjacency bonuses that grow into conversations). **Oaths** — once-a-battle personal skills
paid in HP, our answer to Blaze Arts.

## Stage 7 — Three Oaths *(planned)*
The war splits into three routes (Senate, Legion, Temple), each a different view of the same
events, as *Fortune's Weave* does with its four lords. Painted art pass, full soundtrack,
controller support, Steam build.

---

## Known trade-offs

| Decision | Why | When to revisit |
|---|---|---|
| Procedural vector art instead of sprites | Ships a coherent look without an artist; keeps the repo text-only | Stage 7 art pass |
| Data in GDScript dictionaries, not `.tres` resources | Readable diffs, testable without the editor | If a designer who prefers the inspector joins |
| One equipped weapon at a time, chosen when attacking | Keeps inventory UI small | If item variety grows past ~3 per unit |
| No weapon durability | FE-style durability adds bookkeeping that fights the thread's puzzle focus | Stage 5 playtests |
| Enemies ignore the thread | Keeps the AI fair and legible; the Distaff will change this on purpose | Stage 5 |
