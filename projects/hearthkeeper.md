# Hearthkeeper — WoW: Forever beta companion

A local-first field journal for the *World of Warcraft: Forever* (Classic+) beta, built in the
window between the BlizzCon announcement and the beta opening.

**Stack:** React · Vite · PWA (service worker + manifest) · localStorage · no backend

**Source:** [`apps/hearthkeeper/`](../apps/hearthkeeper) — the one project in this repository
that ships its code, because there is no client data in it to protect.

---

## The idea

Blizzard announced Forever on September 12, 2026 and opened the beta five days later: a
five-week test, a level cap of 20 rising to 30, three new zones, nine new dungeons, a new race,
six new race/class combinations, and revised talent trees with a new 16-point tier.

The thing that actually goes wrong for a beta tester is not failing to find bugs. It is finding
three of them during a dungeon run, playing on, and reconstructing one of them an hour later in
a form nobody can act on. The game client has no way to take a note, and no feedback forum was
announced at beta start.

So Hearthkeeper is built around capture, not browsing:

- **Log a finding with a title and nothing else.** Severity, zone, level, character, steps and
  expected/actual are all optional, and can be filled in after the run.
- **Near-duplicate detection on the way in** — the same report in the same place, written with
  different punctuation, gets caught before it becomes two entries.
- **Export as forum-ready markdown**, grouped by severity, steps renumbered, stamped with the
  build it was seen on. A report without a build stamp is unactionable.

## The part I find most interesting: reach

Most of the announced patch cannot be tested during the beta at all, and a companion app that
ignores that is worse than nothing.

Talent points start at level 10, one per level. So the phase 1 cap of 20 is exactly 11 points —
the first talent tier. The new 16-point tier, the headline change to the talent system, needs
level 25, which only exists after the cap moves to 30. A tester who stops at the phase 1 cap
never sees the thing the patch is most notable for. The app computes that from two numbers and
puts it on the dashboard.

The same logic runs over content. Of three announced zones, one is a 1–12 starting area, one is
30–45 and so is barely reachable at the beta's final cap, and one has no announced level range
at all. No raid is testable. Coverage is therefore scored against **what the live phase can
actually reach** — everything else is listed with the reason it is out of reach and excluded
from the denominator, because a completion number that can only go down is a number people stop
reading.

## Provenance as a first-class field

Every zone, dungeon, raid, phase and talent tier carries a confidence flag — `announced`,
`reported`, `carried-over`, `unconfirmed` — displayed inline next to the value rather than in a
disclaimer nobody reads.

This is the honest engineering position during an announcement window. Most circulating "facts"
are somebody's paraphrase of a stage demo. The phase 2 date is the live example: Blizzard said
"a couple of weeks", so the pack carries an estimated date flagged `reported`, and every screen
that derives from it says so.

Unknown is kept distinct from false throughout. The Skyborne Elves have exactly one confirmed
class per faction and the rest unannounced, so a Skyborne Hunter raises a *warning* that the
announced list is incomplete, while a Tauren Mage is a hard *error*. Per-talent data is
deliberately not shipped: it is not public, it would be wrong within a week, and a companion
that guesses at it does more damage than one that admits the gap.

## Game data is a versioned pack, not code

Beta facts move. A phase date lands, a zone's level range shifts, a dungeon gets named.

Content lives in versioned JSON packs with a `packVersion` and a `gameBuild` stamp. The app
keeps a snapshot of the pack it last saw and diffs a new one against it, so after an update a
tester gets an explicit "what changed" list — level ranges that moved, dungeons that arrived,
class lists that grew, phase dates that slipped — instead of a silently different UI. Findings
keep the build stamp they were logged under, so a report from the opening build is never
re-read as a report about a later one.

## Local-first, same as the rest of my work

No accounts, no server, no analytics, no network calls. The journal is a JSON file the tester
owns: exports round-trip, imports merge by last-edit-wins so a laptop file and a phone file can
be combined, a partially corrupt file restores its valid part and reports what it skipped, and
a refused write — private mode, exhausted quota — is surfaced rather than swallowed. Storage
sits behind an adapter, so IndexedDB or a host-provided store is a one-file change.

It installs as a PWA and works with the network off, which is the real use case: a second
screen next to a game client, often a phone, sometimes on wifi that drops.

## Engineering notes

Every rule lives in `src/core/` as a pure function with no React import — schedule resolution,
talent arithmetic, journal validation, coverage bucketing, report rendering, backup migration.
The views read state and call actions and hold no rules of their own. That is what makes **84
unit tests** run in about a second with no DOM, and it is the answer to "how do you test a
companion app for a game you cannot automate".

A browser smoke test covers what unit tests structurally cannot: it loads the built app on a
phone-sized viewport, logs a finding, checks the duplicate warning, adds a character, reloads,
cuts the network, and confirms both the app and the data are still there — then replays the
dashboard with the clock moved into each beta phase to check the caps and reachable counts.

The unit suite paid for itself during the build. A round-trip test caught that a finding with
no level recorded was being stored as level `0` — because `Number(null)` is `0` — and then
rejected by its own validator on the next import. Left in, that would have quietly eaten
findings on restore, which is the single worst thing a journal can do.

## Roadmap

Generated packs once Blizzard publishes real patch notes for the build, replacing the
hand-compiled one. A second export formatter if a structured feedback endpoint ever appears.
Screenshot attachments on findings, which is the change that would push storage from
localStorage to IndexedDB.
